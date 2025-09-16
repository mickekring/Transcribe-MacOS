import Foundation
import WhisperKit
import AVFoundation

class WhisperKitService {
    var whisperKit: WhisperKit?
    private let languageManager = LanguageManager.shared
    private var isInitializing = false
    private var currentModelId: String?
    
    
    var currentModel: String? {
        return currentModelId
    }
    
    var availableModels: [String] = [
        "kb_whisper-base-coreml",
        "kb_whisper-small-coreml",
        "kb_whisper-medium-coreml",
        "kb_whisper-large-coreml",
        "openai_whisper-base",
        "openai_whisper-small", 
        "openai_whisper-medium",
        "openai_whisper-large-v2",
        "openai_whisper-large-v3"
    ]
    
    
    func initialize(modelId: String) async throws {
        guard !isInitializing else { 
            print("🔒 WhisperKit: Already initializing, skipping duplicate request")
            return 
        }
        isInitializing = true
        
        defer { 
            isInitializing = false 
            print("🔓 WhisperKit: Initialization complete (success or failure)")
        }
        
        print("🚀 WhisperKit: Starting initialization for model: \(modelId)")
        
        do {
            let task: Task<WhisperKit?, Error>
            
            // Check if this is a KB model that needs special handling
            if modelId.starts(with: "kb_whisper-") {
                print("🇸🇪 WhisperKit: Detected KB Whisper model: \(modelId)")
                
                let variant: String
                switch modelId {
                case "kb_whisper-base-coreml":
                    variant = "base"
                    print("📦 WhisperKit: KB Base model selected")
                case "kb_whisper-small-coreml":
                    variant = "small"
                    print("📦 WhisperKit: KB Small model selected")
                case "kb_whisper-medium-coreml":
                    variant = "medium"
                    print("📦 WhisperKit: KB Medium model selected")
                case "kb_whisper-large-coreml":
                    variant = "large"
                    print("📦 WhisperKit: KB Large model selected")
                default:
                    variant = "base"
                    print("📦 WhisperKit: Default to KB Base model")
                }
                
                task = Task {
                    print("🔄 WhisperKit: Loading KB model variant: \(variant)")
                    
                    // WhisperKit DOES support custom repositories using modelRepo parameter!
                    // The key is separating the model name from the repository
                    
                    print("📍 Using WhisperKitConfig with modelRepo parameter")
                    print("  - Model: \(variant)")
                    print("  - Repository: mickekringai/kb-whisper-coreml")
                    
                    // Create config with the correct parameters
                    let config = WhisperKitConfig(
                        model: variant,  // Just "base" or "small"
                        modelRepo: "mickekringai/kb-whisper-coreml",  // Your custom repo
                        verbose: true  // Enable verbose logging
                    )
                    
                    print("🚀 Loading KB Whisper \(variant) from custom repository...")
                    
                    do {
                        let kit = try await WhisperKit(config)
                        print("✅ WhisperKit: Successfully loaded KB model '\(variant)' from mickekringai/kb-whisper-coreml")
                        return kit
                    } catch {
                        print("❌ Failed to load KB model: \(error)")
                        print("📝 Error details: \(error.localizedDescription)")
                        throw error
                    }
                }
            } else {
                print("🌍 WhisperKit: Detected standard OpenAI model: \(modelId)")
                
                // Standard WhisperKit model
                let modelName = mapModelIdToWhisperKitModel(modelId)
                print("📦 WhisperKit: Mapped to model name: \(modelName)")
                
                task = Task {
                    print("🔄 WhisperKit: Loading standard model: \(modelName)")
                    
                    // WhisperKit will automatically download the model if needed
                    let kit = try await WhisperKit(model: modelName)
                    print("✅ WhisperKit: Successfully created WhisperKit instance for: \(modelName)")
                    return kit
                }
            }
            
            currentModelId = modelId
            print("💾 WhisperKit: Set current model ID to: \(modelId)")
            
            // Wait for initialization with timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 second timeout
                print("⏰ WhisperKit: Timeout reached, cancelling initialization")
                task.cancel()
                throw TranscriptionError.timeout
            }
            
            do {
                print("⏳ WhisperKit: Waiting for model initialization...")
                whisperKit = try await task.value
                timeoutTask.cancel()
                print("✅ WhisperKit: Model initialization successful!")
                print("📊 WhisperKit: whisperKit instance = \(whisperKit != nil ? "Created" : "Nil")")
            } catch {
                timeoutTask.cancel()
                print("❌ WhisperKit: Task failed with error: \(error)")
                print("🔍 WhisperKit: Error type: \(type(of: error))")
                print("📝 WhisperKit: Error description: \(error.localizedDescription)")
                throw error
            }
        } catch {
            print("❌ WhisperKit initialization failed: \(error)")
            print("🔍 Error details:")
            print("  - Type: \(type(of: error))")
            print("  - Description: \(error.localizedDescription)")
            
            // Try to extract more details from the error
            if let errorString = String(describing: error).components(separatedBy: "\"").dropFirst().first {
                print("  - Extracted message: \(errorString)")
            }
            
            throw error
        }
    }
    
    func loadModel(_ modelName: String) async {
        print("🎯 WhisperKitService.loadModel called with: \(modelName)")
        do {
            try await initialize(modelId: modelName)
            print("✅ WhisperKitService.loadModel: Model loaded successfully")
        } catch {
            print("❌ Failed to load WhisperKit model: \(error)")
            print("  - Model requested: \(modelName)")
        }
    }
    
    func transcribe(fileURL: URL, modelId: String, language: String?) -> AsyncThrowingStream<TranscriptionUpdate, Error> {
        AsyncThrowingStream { continuation in
            Task {
                print("🎤 WhisperKitService.transcribe started")
                print("  - File: \(fileURL.lastPathComponent)")
                print("  - Model: \(modelId)")
                print("  - Language: \(language ?? "auto")")
                print("  - Current whisperKit: \(whisperKit != nil ? "Exists" : "Nil")")
                print("  - Current model: \(currentModelId ?? "None")")
                
                do {
                    // Initialize WhisperKit if needed or if model changed
                    if whisperKit == nil || currentModelId != modelId {
                        print("🔄 WhisperKit needs initialization:")
                        print("  - whisperKit is nil: \(whisperKit == nil)")
                        print("  - Model changed: \(currentModelId != modelId) (current: \(currentModelId ?? "nil"), requested: \(modelId))")
                        
                        continuation.yield(TranscriptionUpdate(
                            text: NSLocalizedString("downloading_whisperkit_model", comment: ""),
                            progress: 0.01,
                            segments: [],
                            isComplete: false
                        ))
                        
                        do {
                            print("🔧 Calling initialize with modelId: \(modelId)")
                            try await initialize(modelId: modelId)
                            print("✅ WhisperKit initialized successfully")
                        } catch {
                            print("❌ Failed to initialize WhisperKit: \(error)")
                            print("  - Will fall back to mock transcription")
                            // Fall back to mock transcription
                            await provideMockTranscription(fileURL: fileURL, continuation: continuation)
                            return
                        }
                    } else {
                        print("✅ Using existing WhisperKit instance for model: \(currentModelId ?? "unknown")")
                    }
                    
                    guard let whisperKit = whisperKit else {
                        await provideMockTranscription(fileURL: fileURL, continuation: continuation)
                        return
                    }
                    
                    // Initial progress
                    continuation.yield(TranscriptionUpdate(
                        text: NSLocalizedString("initializing_whisperkit", comment: ""),
                        progress: 0.05,
                        segments: [],
                        isComplete: false
                    ))
                    
                    // Loading audio
                    continuation.yield(TranscriptionUpdate(
                        text: NSLocalizedString("loading_audio_file", comment: ""),
                        progress: 0.1,
                        segments: [],
                        isComplete: false
                    ))
                    
                    // Get language code for transcription
                    let languageCode = language ?? "auto"
                    
                    // Get timestamp settings from UserDefaults
                    let includeTimestamps = UserDefaults.standard.bool(forKey: "includeTimestamps")
                    let wordTimestamps = UserDefaults.standard.bool(forKey: "wordTimestamps")
                    
                    // Create decoding options
                    let decodeOptions = DecodingOptions(
                        task: .transcribe,
                        language: languageCode == "auto" ? nil : languageCode,
                        usePrefillPrompt: false,
                        usePrefillCache: false,
                        skipSpecialTokens: true,
                        withoutTimestamps: !includeTimestamps,
                        wordTimestamps: wordTimestamps
                    )
                    
                    // Variables to track progress and accumulate text
                    var lastUpdateTime = Date()
                    let updateInterval: TimeInterval = 0.2 // Update every 0.2 seconds for smooth streaming
                    
                    // Keep track of all unique text segments we've seen
                    var completedSegments: [Int: String] = [:] // windowId -> final text for that window
                    var currentWindowId = -1
                    var currentWindowText = ""
                    var lastDisplayedText = ""
                    let startTime = Date()
                    var maxWindowId = 0
                    
                    // Create streaming callback
                    let streamingCallback: TranscriptionCallback = { progress in
                        let now = Date()
                        
                        // Debug: Log callback invocation
                        if progress.windowId % 10 == 0 {  // Log every 10th window to avoid spam
                            print("📝 Streaming callback: window \(progress.windowId), text length: \(progress.text.count)")
                        }
                        
                        // Always process updates, even with empty text
                        // Track the current window's text
                        if true {  // Changed from !progress.text.isEmpty to always process
                            if progress.windowId != currentWindowId {
                                // New window started - save the previous window's text if we have it
                                if currentWindowId >= 0 && !currentWindowText.isEmpty {
                                    completedSegments[currentWindowId] = currentWindowText
                                }
                                currentWindowId = progress.windowId
                            }
                            currentWindowText = progress.text
                            maxWindowId = max(maxWindowId, progress.windowId)
                            
                            // Build the complete text from all segments
                            var fullText = ""
                            
                            // Add all completed segments in order
                            let sortedWindows = completedSegments.keys.sorted()
                            for windowId in sortedWindows {
                                if let segmentText = completedSegments[windowId] {
                                    if !fullText.isEmpty {
                                        fullText += " "
                                    }
                                    fullText += segmentText
                                }
                            }
                            
                            // Add current window's progress
                            if !fullText.isEmpty && !currentWindowText.isEmpty {
                                fullText += " " + currentWindowText
                            } else if fullText.isEmpty {
                                fullText = currentWindowText
                            }
                            
                            // Only send update if text changed or enough time passed
                            let textChanged = fullText != lastDisplayedText
                            let timeElapsed = now.timeIntervalSince(lastUpdateTime) >= updateInterval
                            
                            if textChanged || timeElapsed {  // Changed from && to || to send more updates
                                lastUpdateTime = now
                                lastDisplayedText = fullText
                                
                                // Calculate progress more dynamically
                                let elapsedTime = now.timeIntervalSince(startTime)
                                let segmentCount = Double(completedSegments.count + 1)
                                
                                // Use a combination of time-based and segment-based progress
                                // Assume average transcription takes 10-30 seconds
                                let timeProgress = min(elapsedTime / 20.0, 0.9) // Time-based: 0-90% over 20 seconds
                                
                                // Segment-based progress (assuming typical audio has 5-50 segments)
                                let segmentProgress = min(segmentCount / 10.0, 0.9) // 0-90% for up to 10 segments
                                
                                // Take the maximum of both progress indicators, starting from 30%
                                let estimatedProgress = min(0.3 + max(timeProgress, segmentProgress) * 0.65, 0.95)
                                
                                // Send streaming update directly without Task wrapper
                                continuation.yield(TranscriptionUpdate(
                                    text: fullText.isEmpty ? "Transkriberar..." : fullText,
                                    progress: estimatedProgress,
                                    segments: [],
                                    isComplete: false
                                ))
                                
                                print("🔄 UI Update sent: progress=\(estimatedProgress), text length=\(fullText.count)")
                            }
                        }
                        
                        // Return true to continue transcription
                        return true
                    }
                    
                    // Transcribe with streaming callback
                    print("🎯 Starting WhisperKit transcription with model: \(currentModelId ?? "unknown")")
                    print("  - Audio file: \(fileURL.lastPathComponent)")
                    print("  - Language: \(languageCode)")
                    
                    let results = try await whisperKit.transcribe(
                        audioPath: fileURL.path,
                        decodeOptions: decodeOptions,
                        callback: streamingCallback
                    )
                    
                    print("✅ WhisperKit transcription completed")
                    
                    // Make sure to save the last window's text
                    if currentWindowId >= 0 && !currentWindowText.isEmpty {
                        completedSegments[currentWindowId] = currentWindowText
                    }
                    
                    // Process final result
                    print("🔍 Processing final results...")
                    print("  - Results count: \(results.count)")
                    
                    if let firstResult = results.first {
                        print("  - Segments count: \(firstResult.segments.count)")
                        
                        // Extract final text from all segments
                        let fullText = firstResult.segments.map { $0.text }.joined(separator: " ")
                        print("  - Total text length: \(fullText.count) characters")
                        
                        // Convert final segments to our format with word timestamps if available
                        let finalSegments = firstResult.segments.map { segment in
                            TranscriptionSegmentData(
                                start: Double(segment.start),
                                end: Double(segment.end),
                                text: segment.text,
                                words: nil // Word-level timestamps need investigation in WhisperKit API
                            )
                        }
                        
                        print("📤 Sending final transcription result to UI")
                        // Send final result
                        continuation.yield(TranscriptionUpdate(
                            text: fullText,
                            progress: 1.0,
                            segments: finalSegments,
                            isComplete: true
                        ))
                        print("✅ Final result sent successfully")
                    } else {
                        print("⚠️ No transcription results returned")
                        // No results
                        continuation.yield(TranscriptionUpdate(
                            text: "No transcription results",
                            progress: 1.0,
                            segments: [],
                            isComplete: true
                        ))
                    }
                    
                    continuation.finish()
                    
                } catch {
                    print("Transcription error: \(error)")
                    // Provide mock transcription as fallback
                    await provideMockTranscription(fileURL: fileURL, continuation: continuation)
                }
            }
        }
    }
    
    private func provideMockTranscription(fileURL: URL, continuation: AsyncThrowingStream<TranscriptionUpdate, Error>.Continuation) async {
        // Provide a mock transcription when WhisperKit fails
        continuation.yield(TranscriptionUpdate(
            text: """
            ⚠️ WhisperKit is still initializing or downloading models.
            
            This is a placeholder transcription while the system prepares.
            
            File: \(fileURL.lastPathComponent)
            
            Please try again in a moment, or check:
            1. Internet connection for model download
            2. Available disk space (models are ~40-150MB)
            3. Console logs for specific errors
            
            The transcription will work once WhisperKit finishes setup.
            """,
            progress: 1.0,
            segments: [],
            isComplete: true
        ))
        continuation.finish()
    }
}

extension TranscriptionError {
    static let timeout = TranscriptionError.modelNotFound // Reuse for now
}

extension WhisperKitService {
    private func mapModelIdToWhisperKitModel(_ modelId: String) -> String {
        switch modelId {
        case "openai_whisper-base":
            return "openai_whisper-base"
        case "openai_whisper-small":
            return "openai_whisper-small"
        case "openai_whisper-medium":
            return "openai_whisper-medium"
        case "openai_whisper-large-v2":
            return "openai_whisper-large-v2"
        case "openai_whisper-large-v3":
            return "openai_whisper-large-v3"
        case "kb_whisper-base-coreml":
            // Try without the path separator - WhisperKit might add it
            return "mickekringai/kb-whisper-coreml_base"
        case "kb_whisper-small-coreml":
            // Try without the path separator - WhisperKit might add it
            return "mickekringai/kb-whisper-coreml_small"
        default:
            return "openai_whisper-base" // Default to base model
        }
    }
}