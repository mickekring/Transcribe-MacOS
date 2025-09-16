import Foundation

struct TranscriptionResult: Identifiable, Codable {
    let id: UUID
    let text: String
    let segments: [TranscriptionSegment]
    let language: String
    let duration: TimeInterval
    let timestamp: Date
    let modelUsed: String
    
    init(id: UUID = UUID(), text: String, segments: [TranscriptionSegment], language: String, duration: TimeInterval, timestamp: Date, modelUsed: String) {
        self.id = id
        self.text = text
        self.segments = segments
        self.language = language
        self.duration = duration
        self.timestamp = timestamp
        self.modelUsed = modelUsed
    }
    
    var formattedText: String {
        segments.map { $0.text }.joined(separator: " ")
    }
}

struct TranscriptionSegment: Codable {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval
    let text: String
    let confidence: Float?
    let speaker: String?
}

struct TranscriptionOptions {
    var language: String = "auto"
    var model: WhisperModel = .base
    var task: TranscriptionTask = .transcribe
    var temperature: Float = 0.0
    var enableTimestamps: Bool = true
    var enableSpeakerDiarization: Bool = false
    var outputFormat: OutputFormat = .text
}

enum TranscriptionTask: String, CaseIterable {
    case transcribe
    case translate
}

enum OutputFormat: String, CaseIterable {
    case text = "txt"
    case srt = "srt"
    case vtt = "vtt"
    case json = "json"
    case docx = "docx"
}

enum WhisperModel: String, CaseIterable {
    case tiny = "kb-whisper-tiny"
    case base = "kb-whisper-base"
    case small = "kb-whisper-small"
    case medium = "kb-whisper-medium"
    case large = "kb-whisper-large"
    
    var displayName: String {
        switch self {
        case .tiny: return "Tiny (Fast)"
        case .base: return "Base (Balanced)"
        case .small: return "Small (Good)"
        case .medium: return "Medium (Better)"
        case .large: return "Large (Best)"
        }
    }
    
    var sizeInMB: Int {
        switch self {
        case .tiny: return 39
        case .base: return 74
        case .small: return 244
        case .medium: return 769
        case .large: return 1550
        }
    }
}

struct AudioFile: Identifiable {
    let id = UUID()
    let url: URL
    let duration: TimeInterval
    let format: String
    let sampleRate: Int
    let channels: Int
    
    var fileName: String {
        url.lastPathComponent
    }
    
    var fileSizeInMB: Double {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes?[.size] as? Int64 ?? 0
        return Double(fileSize) / (1024 * 1024)
    }
}