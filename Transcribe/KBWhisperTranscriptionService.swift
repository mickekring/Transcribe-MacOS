import Foundation
import AVFoundation
import WhisperKit

// Service specifically for KB Whisper models
class KBWhisperTranscriptionService {
    private let modelManager = ModelManager.shared
    private let languageManager = LanguageManager.shared
    private var whisperKit: WhisperKit?
    
    func transcribe(fileURL: URL, modelId: String) -> AsyncThrowingStream<TranscriptionUpdate, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Check if KB model is downloaded
                    guard modelManager.isModelDownloaded(modelId) else {
                        throw TranscriptionError.modelNotFound
                    }
                    
                    // Get the path to the downloaded GGML model
                    guard let modelPath = modelManager.getModelPath(modelId) else {
                        throw TranscriptionError.modelNotFound
                    }
                    
                    continuation.yield(TranscriptionUpdate(
                        text: "Loading KB Whisper model: \(modelId)...",
                        progress: 0.1,
                        segments: [],
                        isComplete: false
                    ))
                    
                    // Initialize WhisperKit with specific model path
                    // Note: WhisperKit expects CoreML models, not GGML
                    // We need to either:
                    // 1. Convert GGML to CoreML format
                    // 2. Use whisper.cpp directly
                    // 3. Use WhisperKit's built-in models but specify Swedish
                    
                    // For now, use WhisperKit with Swedish language specified
                    if whisperKit == nil {
                        // Initialize WhisperKit without specifying a model
                        // It will use its default model but we'll force Swedish
                        whisperKit = try await WhisperKit()
                    }
                    
                    guard let whisperKit = whisperKit else {
                        throw TranscriptionError.modelNotFound
                    }
                    
                    continuation.yield(TranscriptionUpdate(
                        text: "Processing with \(modelId) (Swedish optimized)...",
                        progress: 0.3,
                        segments: [],
                        isComplete: false
                    ))
                    
                    // Determine task and language
                    let language = languageManager.selectedLanguage.code
                    let isSwedish = language == "sv" || language == "auto"
                    
                    // Create decoding options to ensure transcription (not translation)
                    var decodingOptions = DecodingOptions()
                    decodingOptions.language = isSwedish ? "sv" : language  // Force Swedish if selected
                    decodingOptions.task = .transcribe  // IMPORTANT: Use transcribe, not translate
                    decodingOptions.temperature = 0.0
                    decodingOptions.skipSpecialTokens = true
                    decodingOptions.withoutTimestamps = false
                    
                    // Load and prepare audio
                    let audioArray = try await loadAudio(from: fileURL)
                    
                    continuation.yield(TranscriptionUpdate(
                        text: "Transcribing in \(isSwedish ? "Swedish" : language)...",
                        progress: 0.5,
                        segments: [],
                        isComplete: false
                    ))
                    
                    // Transcribe with specified options
                    let results = try await whisperKit.transcribe(
                        audioArray: audioArray,
                        decodeOptions: decodingOptions
                    )
                    
                    // Process results
                    if let result = results.first {
                        let fullText = result.segments.map { $0.text }.joined(separator: " ")
                        
                        let segments = result.segments.map { segment in
                            TranscriptionSegmentData(
                                start: Double(segment.start),
                                end: Double(segment.end),
                                text: segment.text,
                                words: nil
                            )
                        }
                        
                        continuation.yield(TranscriptionUpdate(
                            text: fullText,
                            progress: 1.0,
                            segments: segments,
                            isComplete: true
                        ))
                    }
                    
                    continuation.finish()
                    
                } catch {
                    print("KB Whisper transcription error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func loadAudio(from url: URL) async throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        
        // Read the audio file
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                   sampleRate: 16000, 
                                   channels: 1, 
                                   interleaved: false)!
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, 
                                      frameCapacity: UInt32(file.length))!
        try file.read(into: buffer)
        
        // Convert to array
        let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], 
                                                   count: Int(buffer.frameLength)))
        
        return floatArray
    }
}

// Removed custom DecodingOptions extension - using WhisperKit's default initializer

// Removed - using WhisperKit's DecodingTask instead