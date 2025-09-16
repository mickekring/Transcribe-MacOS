import Foundation
import AVFoundation

class BergetTranscriptionService {
    private let apiKey: String
    private let baseURL = "https://api.berget.ai/v1"
    private let model = "KBLab/kb-whisper-large"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func transcribe(
        audioURL: URL,
        language: String? = nil,
        onProgress: ((String) -> Void)? = nil,
        completion: @escaping (Result<TranscriptionResult, Error>) -> Void
    ) {
        Task {
            do {
                // First, check if streaming is supported
                let supportsStreaming = await checkStreamingSupport()
                
                if supportsStreaming {
                    // Try streaming transcription
                    try await transcribeWithStreaming(
                        audioURL: audioURL,
                        language: language,
                        onProgress: onProgress,
                        completion: completion
                    )
                } else {
                    // Fall back to regular transcription
                    let result = try await transcribeWithoutStreaming(
                        audioURL: audioURL,
                        language: language
                    )
                    
                    await MainActor.run {
                        completion(.success(result))
                    }
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func transcribeWithoutStreaming(
        audioURL: URL,
        language: String? = nil
    ) async throws -> TranscriptionResult {
        let boundary = UUID().uuidString
        
        // Create multipart form data
        var body = Data()
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/\(audioURL.pathExtension)\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: audioURL))
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)
        
        // Add language if specified
        if let language = language, language != "auto" {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // Add response format (for potential segments/timestamps)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create request
        var request = URLRequest(url: URL(string: "\(baseURL)/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 300 // 5 minutes for large files
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudTranscriptionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw CloudTranscriptionError.apiError(errorMessage)
            }
            throw CloudTranscriptionError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Check if we got verbose JSON with segments
        if let segments = json?["segments"] as? [[String: Any]] {
            return parseVerboseResponse(json: json!, audioURL: audioURL)
        } else if let text = json?["text"] as? String {
            // Simple text response
            return TranscriptionResult(
                text: text,
                segments: [],
                language: json?["language"] as? String ?? "unknown",
                duration: getAudioDuration(url: audioURL) ?? 0,
                timestamp: Date(),
                modelUsed: model
            )
        } else {
            throw CloudTranscriptionError.invalidResponse
        }
    }
    
    private func transcribeWithStreaming(
        audioURL: URL,
        language: String? = nil,
        onProgress: ((String) -> Void)? = nil,
        completion: @escaping (Result<TranscriptionResult, Error>) -> Void
    ) async throws {
        // For now, we'll implement this as a TODO since Berget might not support streaming yet
        // We'll fall back to regular transcription
        let result = try await transcribeWithoutStreaming(audioURL: audioURL, language: language)
        await MainActor.run {
            completion(.success(result))
        }
    }
    
    private func checkStreamingSupport() async -> Bool {
        // Check if Berget supports streaming
        // For now, return false as they likely don't support it yet
        return false
    }
    
    private func parseVerboseResponse(json: [String: Any], audioURL: URL) -> TranscriptionResult {
        var segments: [TranscriptionSegment] = []
        
        if let jsonSegments = json["segments"] as? [[String: Any]] {
            for segment in jsonSegments {
                if let text = segment["text"] as? String,
                   let start = segment["start"] as? Double,
                   let end = segment["end"] as? Double {
                    segments.append(TranscriptionSegment(
                        id: segments.count,
                        start: start,
                        end: end,
                        text: text,
                        confidence: nil,
                        speaker: nil
                    ))
                }
            }
        }
        
        let fullText = json["text"] as? String ?? segments.map { $0.text }.joined(separator: " ")
        
        return TranscriptionResult(
            text: fullText,
            segments: segments,
            language: json["language"] as? String ?? "unknown",
            duration: json["duration"] as? Double ?? getAudioDuration(url: audioURL) ?? 0,
            timestamp: Date(),
            modelUsed: model
        )
    }
    
    private func getAudioDuration(url: URL) -> Double? {
        let asset = AVAsset(url: url)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        return durationInSeconds.isFinite ? durationInSeconds : nil
    }
}

enum CloudTranscriptionError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .fileNotFound:
            return "Audio file not found"
        }
    }
}