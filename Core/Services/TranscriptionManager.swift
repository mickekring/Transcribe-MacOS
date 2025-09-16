import Foundation
import Combine
import AVFoundation

@MainActor
class TranscriptionManager: ObservableObject {
    @Published var isTranscribing = false
    @Published var currentProgress: Double = 0
    @Published var currentTask: String = ""
    @Published var transcriptionQueue: [TranscriptionJob] = []
    @Published var completedTranscriptions: [TranscriptionResult] = []
    @Published var error: TranscriptionError?
    
    private var cancellables = Set<AnyCancellable>()
    private let transcriptionService: TranscriptionService
    private let audioProcessor: AudioProcessor
    
    init() {
        self.transcriptionService = KBWhisperService()
        self.audioProcessor = AudioProcessor()
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor queue changes
        $transcriptionQueue
            .sink { [weak self] queue in
                if !queue.isEmpty && !(self?.isTranscribing ?? false) {
                    Task {
                        await self?.processNextJob()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func transcribeFile(_ url: URL, options: TranscriptionOptions = TranscriptionOptions()) {
        let job = TranscriptionJob(
            id: UUID(),
            fileURL: url,
            options: options,
            status: .pending
        )
        transcriptionQueue.append(job)
    }
    
    func transcribeFiles(_ urls: [URL], options: TranscriptionOptions = TranscriptionOptions()) {
        let jobs = urls.map { url in
            TranscriptionJob(
                id: UUID(),
                fileURL: url,
                options: options,
                status: .pending
            )
        }
        transcriptionQueue.append(contentsOf: jobs)
    }
    
    func cancelTranscription(_ jobId: UUID) {
        if let index = transcriptionQueue.firstIndex(where: { $0.id == jobId }) {
            transcriptionQueue.remove(at: index)
        }
    }
    
    func cancelAllTranscriptions() {
        transcriptionQueue.removeAll()
        isTranscribing = false
    }
    
    private func processNextJob() async {
        guard !transcriptionQueue.isEmpty else { return }
        
        isTranscribing = true
        let job = transcriptionQueue.removeFirst()
        
        do {
            currentTask = "Processing \(job.fileURL.lastPathComponent)"
            
            // Validate audio file
            let audioFile = try await audioProcessor.validateFile(job.fileURL)
            
            // Preprocess if needed
            currentTask = "Preprocessing audio..."
            let processedURL = try await audioProcessor.preprocess(audioFile, options: job.options)
            
            // Transcribe
            currentTask = "Transcribing..."
            let result = try await transcriptionService.transcribe(
                audioPath: processedURL,
                options: job.options,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.currentProgress = progress
                    }
                }
            )
            
            // Save result
            completedTranscriptions.append(result)
            
            // Cleanup
            if processedURL != job.fileURL {
                try? FileManager.default.removeItem(at: processedURL)
            }
            
        } catch {
            self.error = error as? TranscriptionError ?? .unknown(error)
        }
        
        currentProgress = 0
        currentTask = ""
        isTranscribing = false
        
        // Process next job if any
        if !transcriptionQueue.isEmpty {
            await processNextJob()
        }
    }
}

struct TranscriptionJob: Identifiable {
    let id: UUID
    let fileURL: URL
    let options: TranscriptionOptions
    var status: JobStatus
    
    enum JobStatus {
        case pending
        case processing
        case completed
        case failed(Error)
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case invalidAudioFile
    case unsupportedFormat
    case processingFailed(String)
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Transcription model is not loaded"
        case .invalidAudioFile:
            return "Invalid audio file"
        case .unsupportedFormat:
            return "Unsupported audio format"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

protocol TranscriptionService {
    func transcribe(audioPath: URL, options: TranscriptionOptions, progressHandler: ((Double) -> Void)?) async throws -> TranscriptionResult
    func loadModel(_ model: WhisperModel) async throws
    func unloadModel()
    var isModelLoaded: Bool { get }
}

class AudioProcessor {
    func validateFile(_ url: URL) async throws -> AudioFile {
        let asset = AVAsset(url: url)
        
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw TranscriptionError.invalidAudioFile
        }
        
        let duration = try await asset.load(.duration).seconds
        let formatDescriptions = try await audioTrack.load(.formatDescriptions)
        
        guard let formatDescription = formatDescriptions.first else {
            throw TranscriptionError.invalidAudioFile
        }
        
        let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription as! CMAudioFormatDescription)
        let sampleRate = Int(audioStreamBasicDescription?.pointee.mSampleRate ?? 0)
        let channels = Int(audioStreamBasicDescription?.pointee.mChannelsPerFrame ?? 0)
        
        return AudioFile(
            url: url,
            duration: duration,
            format: url.pathExtension.uppercased(),
            sampleRate: sampleRate,
            channels: channels
        )
    }
    
    func preprocess(_ audioFile: AudioFile, options: TranscriptionOptions) async throws -> URL {
        // If file is already in correct format, return as is
        if audioFile.format == "WAV" && audioFile.sampleRate == 16000 {
            return audioFile.url
        }
        
        // Convert to WAV 16kHz for Whisper
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        let asset = AVAsset(url: audioFile.url)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw TranscriptionError.processingFailed("Failed to create export session")
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .wav
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            return outputURL
        } else {
            throw TranscriptionError.processingFailed(exportSession.error?.localizedDescription ?? "Export failed")
        }
    }
}