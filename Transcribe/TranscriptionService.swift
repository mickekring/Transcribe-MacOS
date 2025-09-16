import Foundation
import Combine

// Transcription update structure for streaming
struct TranscriptionUpdate {
    let text: String
    let progress: Double
    let segments: [TranscriptionSegmentData]
    let isComplete: Bool
}

class TranscriptionService {
    private let modelManager = ModelManager.shared
    private let languageManager = LanguageManager.shared
    // private var whisperCppService: WhisperCppService?  // Removed - too complex
    private var whisperKitService: WhisperKitService?
    private var simpleService: SimpleWhisperService?
    
    func transcribe(fileURL: URL) -> AsyncThrowingStream<TranscriptionUpdate, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Check if we have a downloaded model
                    guard let selectedModel = UserDefaults.standard.string(forKey: "selectedTranscriptionModel"),
                          !selectedModel.isEmpty else {
                        throw TranscriptionError.noModelSelected
                    }
                    
                    if selectedModel.starts(with: "kb_whisper-") ||  // KB CoreML models
                       selectedModel.starts(with: "openai_whisper-") {
                        // Use WhisperKit for standard Whisper models and KB CoreML models
                        try await transcribeWithWhisperKit(
                            fileURL: fileURL,
                            modelId: selectedModel,
                            continuation: continuation
                        )
                    } else if selectedModel.starts(with: "cloud-") {
                        // Use cloud model (OpenAI API)
                        try await transcribeWithCloudModel(
                            fileURL: fileURL,
                            modelId: selectedModel,
                            continuation: continuation
                        )
                    } else {
                        throw TranscriptionError.unsupportedModel
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Removed - using WhisperKit for all models now
    
    private func transcribeWithWhisperKit(
        fileURL: URL,
        modelId: String,
        continuation: AsyncThrowingStream<TranscriptionUpdate, Error>.Continuation
    ) async throws {
        // Initialize WhisperKit service if needed
        if whisperKitService == nil {
            whisperKitService = WhisperKitService()
        }
        
        // Use WhisperKit for standard models
        guard let service = whisperKitService else {
            throw TranscriptionError.modelNotFound
        }
        
        // Get the selected language
        let selectedLanguage = languageManager.selectedLanguage.code
        
        // Stream transcription updates with model and language
        for try await update in service.transcribe(fileURL: fileURL, modelId: modelId, language: selectedLanguage) {
            continuation.yield(update)
            
            if update.isComplete {
                continuation.finish()
                return
            }
        }
    }
    
    private func transcribeWithCloudModel(
        fileURL: URL,
        modelId: String,
        continuation: AsyncThrowingStream<TranscriptionUpdate, Error>.Continuation
    ) async throws {
        // Implementation for cloud models (OpenAI, Groq, etc.)
        // This would use the API keys stored in UserDefaults
        continuation.yield(TranscriptionUpdate(
            text: "Cloud transcription not yet implemented",
            progress: 1.0,
            segments: [],
            isComplete: true
        ))
        continuation.finish()
    }
    
    // Removed - no longer needed with WhisperKit
    /*
    private func getWhisperCppPath() -> String {
        // Check if whisper.cpp is installed
        // First check if it's in the app bundle
        if let bundlePath = Bundle.main.path(forResource: "whisper", ofType: nil) {
            return bundlePath
        }
        
        // Check common installation paths
        let commonPaths = [
            "/usr/local/bin/whisper",
            "/opt/homebrew/bin/whisper",
            "~/.local/bin/whisper"
        ]
        
        for path in commonPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                return expandedPath
            }
        }
        
        // Return default path (will need to be installed)
        return "/usr/local/bin/whisper"
    }
    
    // Mock transcription for testing when whisper.cpp is not available
    private func mockTranscription(
        fileURL: URL,
        continuation: AsyncThrowingStream<TranscriptionUpdate, Error>.Continuation
    ) async {
        // Send initial progress
        continuation.yield(TranscriptionUpdate(
            text: "Starting transcription...",
            progress: 0.1,
            segments: [],
            isComplete: false
        ))
        
        // Simulate progress
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            let progress = Double(i) / 10.0
            let mockText = """
            This is a mock transcription for testing purposes.
            
            Since whisper.cpp is not installed, we're showing this demo text to verify the UI is working correctly.
            
            To enable real transcription:
            1. Install whisper.cpp from https://github.com/ggerganov/whisper.cpp
            2. Download KB Whisper models from the Settings
            3. Try transcribing again
            
            Progress: \(Int(progress * 100))%
            
            File: \(fileURL.lastPathComponent)
            """
            
            continuation.yield(TranscriptionUpdate(
                text: mockText,
                progress: progress,
                segments: [
                    TranscriptionSegmentData(
                        start: 0,
                        end: 5,
                        text: "This is a mock transcription for testing purposes.",
                        words: nil
                    )
                ],
                isComplete: false
            ))
        }
        
        // Send final update
        continuation.yield(TranscriptionUpdate(
            text: """
            [Mock Transcription Complete]
            
            This is a demonstration of the transcription interface.
            
            To enable real transcription, please install whisper.cpp:
            
            brew install whisper-cpp
            
            Or build from source:
            git clone https://github.com/ggerganov/whisper.cpp
            cd whisper.cpp
            make
            
            Then download KB Whisper models from Settings.
            """,
            progress: 1.0,
            segments: [],
            isComplete: true
        ))
        
        continuation.finish()
    }
    
    private func parseProgress(from line: String) -> Double? {
        // Parse progress from whisper.cpp output
        // Format: "progress = 50%"
        if let range = line.range(of: #"progress\s*=\s*(\d+)%"#, options: .regularExpression) {
            let progressStr = String(line[range]).replacingOccurrences(of: "progress", with: "")
                .replacingOccurrences(of: "=", with: "")
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let progress = Double(progressStr) {
                return progress / 100.0
            }
        }
        return nil
    }
    */
    
    private func parseTimestamp(_ timestamp: String) -> Double {
        // Parse timestamp format "00:00:00,000" to seconds
        let components = timestamp.replacingOccurrences(of: ",", with: ".").split(separator: ":")
        guard components.count == 3 else { return 0 }
        
        let hours = Double(components[0]) ?? 0
        let minutes = Double(components[1]) ?? 0
        let seconds = Double(components[2]) ?? 0
        
        return hours * 3600 + minutes * 60 + seconds
    }
    
    func cancelTranscription() {
        // WhisperKit handles cancellation internally
    }
}

enum TranscriptionError: LocalizedError {
    case noModelSelected
    case modelNotFound
    case unsupportedModel
    case whisperNotInstalled
    
    var errorDescription: String? {
        switch self {
        case .noModelSelected:
            return "No transcription model selected"
        case .modelNotFound:
            return "Selected model not found. Please download it first."
        case .unsupportedModel:
            return "Unsupported model type"
        case .whisperNotInstalled:
            return "whisper.cpp is not installed. Please install it first."
        }
    }
}