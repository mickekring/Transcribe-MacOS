import Foundation
import CoreML

class KBWhisperService: TranscriptionService {
    private var whisperModel: WhisperMLModel?
    private var currentModel: WhisperModel?
    private let modelManager = ModelManager.shared
    
    var isModelLoaded: Bool {
        whisperModel != nil
    }
    
    init() {
        Task {
            // Load default model
            try? await loadModel(.base)
        }
    }
    
    func loadModel(_ model: WhisperModel) async throws {
        // Check if model is already loaded
        if currentModel == model && isModelLoaded {
            return
        }
        
        // Unload current model
        unloadModel()
        
        // Download model if needed
        let modelPath = try await modelManager.ensureModelDownloaded(model)
        
        // Load the model
        whisperModel = try await WhisperMLModel(contentsOf: modelPath)
        currentModel = model
    }
    
    func unloadModel() {
        whisperModel = nil
        currentModel = nil
    }
    
    func transcribe(
        audioPath: URL,
        options: TranscriptionOptions,
        progressHandler: ((Double) -> Void)?
    ) async throws -> TranscriptionResult {
        
        guard let model = whisperModel else {
            throw TranscriptionError.modelNotLoaded
        }
        
        // Load and prepare audio
        let audioData = try await loadAudioData(from: audioPath)
        
        // Split audio into chunks for processing
        let chunks = splitAudioIntoChunks(audioData, chunkSize: 30.0) // 30 second chunks
        
        var allSegments: [TranscriptionSegment] = []
        var fullText = ""
        
        for (index, chunk) in chunks.enumerated() {
            progressHandler?(Double(index) / Double(chunks.count))
            
            // Process chunk
            let chunkResult = try await processAudioChunk(chunk, with: model, options: options)
            
            // Append results
            allSegments.append(contentsOf: chunkResult.segments)
            fullText += chunkResult.text + " "
        }
        
        progressHandler?(1.0)
        
        return TranscriptionResult(
            text: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            segments: allSegments,
            language: options.language == "auto" ? detectLanguage(from: fullText) : options.language,
            duration: audioData.duration,
            timestamp: Date(),
            modelUsed: currentModel?.rawValue ?? "unknown"
        )
    }
    
    private func loadAudioData(from url: URL) async throws -> AudioData {
        // Implementation to load and convert audio to proper format
        // This would use AVFoundation to load the audio file
        // and convert it to the format expected by the model
        
        // Placeholder implementation
        return AudioData(
            samples: [],
            sampleRate: 16000,
            duration: 0
        )
    }
    
    private func splitAudioIntoChunks(_ audioData: AudioData, chunkSize: Double) -> [AudioData] {
        // Split audio into manageable chunks
        // Whisper performs better with ~30 second chunks
        
        let samplesPerChunk = Int(chunkSize * Double(audioData.sampleRate))
        var chunks: [AudioData] = []
        
        var currentIndex = 0
        while currentIndex < audioData.samples.count {
            let endIndex = min(currentIndex + samplesPerChunk, audioData.samples.count)
            let chunkSamples = Array(audioData.samples[currentIndex..<endIndex])
            
            chunks.append(AudioData(
                samples: chunkSamples,
                sampleRate: audioData.sampleRate,
                duration: Double(chunkSamples.count) / Double(audioData.sampleRate)
            ))
            
            currentIndex = endIndex
        }
        
        return chunks
    }
    
    private func processAudioChunk(
        _ audioData: AudioData,
        with model: WhisperMLModel,
        options: TranscriptionOptions
    ) async throws -> ChunkResult {
        // Process audio chunk through the model
        // This would involve:
        // 1. Converting audio to mel spectrogram
        // 2. Running through the model
        // 3. Decoding the output tokens
        // 4. Post-processing the text
        
        // Placeholder implementation
        return ChunkResult(
            text: "Transcribed text",
            segments: []
        )
    }
    
    private func detectLanguage(from text: String) -> String {
        // Simple language detection
        // In production, this would use a proper language detection model
        
        let swedishWords = ["och", "är", "det", "som", "på", "av", "för", "med", "har", "inte"]
        let englishWords = ["the", "and", "is", "it", "of", "to", "in", "that", "have", "for"]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        let swedishCount = words.filter { swedishWords.contains($0) }.count
        let englishCount = words.filter { englishWords.contains($0) }.count
        
        if swedishCount > englishCount {
            return "sv"
        } else {
            return "en"
        }
    }
}

// Placeholder types - these would be replaced with actual WhisperKit implementation
struct WhisperMLModel {
    init(contentsOf url: URL) async throws {
        // Load CoreML model
    }
}

struct AudioData {
    let samples: [Float]
    let sampleRate: Int
    let duration: TimeInterval
}

struct ChunkResult {
    let text: String
    let segments: [TranscriptionSegment]
}

// Model Manager for downloading and managing models
class ModelManager {
    static let shared = ModelManager()
    
    private let modelDirectory: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelDirectory = appSupport.appendingPathComponent("Transcribe/Models")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
    }
    
    func ensureModelDownloaded(_ model: WhisperModel) async throws -> URL {
        let modelPath = modelDirectory.appendingPathComponent(model.rawValue)
        
        // Check if model exists
        if FileManager.default.fileExists(atPath: modelPath.path) {
            return modelPath
        }
        
        // Download model
        return try await downloadModel(model, to: modelPath)
    }
    
    private func downloadModel(_ model: WhisperModel, to destination: URL) async throws -> URL {
        // Download model from Hugging Face
        let modelURL = getModelURL(for: model)
        
        let (tempURL, _) = try await URLSession.shared.download(from: modelURL)
        
        // Move to destination
        try FileManager.default.moveItem(at: tempURL, to: destination)
        
        return destination
    }
    
    private func getModelURL(for model: WhisperModel) -> URL {
        // Construct Hugging Face URL for the model
        let baseURL = "https://huggingface.co/KBLab/"
        let modelPath = "\(model.rawValue)/resolve/main/model.mlmodelc"
        return URL(string: baseURL + modelPath)!
    }
    
    func deleteModel(_ model: WhisperModel) throws {
        let modelPath = modelDirectory.appendingPathComponent(model.rawValue)
        try FileManager.default.removeItem(at: modelPath)
    }
    
    func getDownloadedModels() -> [WhisperModel] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: modelDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents.compactMap { url in
            WhisperModel(rawValue: url.lastPathComponent)
        }
    }
    
    func getModelSize(_ model: WhisperModel) -> Int64 {
        let modelPath = modelDirectory.appendingPathComponent(model.rawValue)
        let attributes = try? FileManager.default.attributesOfItem(atPath: modelPath.path)
        return attributes?[.size] as? Int64 ?? 0
    }
}