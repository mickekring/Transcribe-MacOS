import Foundation
import SwiftUI
import Combine

class ModelManager: ObservableObject {
    static let shared = ModelManager()
    
    @Published var downloadProgress: [String: Double] = [:]
    @Published var downloadedModels: Set<String> = []
    @Published var isDownloading: [String: Bool] = [:]
    @Published var enabledWhisperKitModels: Set<String> = []
    
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    
    // Model URLs - KB Whisper CoreML and OpenAI Whisper
    private let modelURLs: [String: String] = [
        // KB Whisper CoreML models (WhisperKit format)
        "kb_whisper-base-coreml": "whisperkit://mickekringai/kb-whisper-base-coreml",
        "kb_whisper-small-coreml": "whisperkit://mickekringai/kb-whisper-small-coreml",
        
        // OpenAI Whisper models (WhisperKit format from Hugging Face)
        "openai_whisper-base": "whisperkit://openai_whisper-base",
        "openai_whisper-small": "whisperkit://openai_whisper-small",
        "openai_whisper-medium": "whisperkit://openai_whisper-medium",
        "openai_whisper-large-v2": "whisperkit://openai_whisper-large-v2",
        "openai_whisper-large-v3": "whisperkit://openai_whisper-large-v3"
    ]
    
    private let modelSizes: [String: Int64] = [
        // KB Whisper CoreML sizes (approximate)
        "kb_whisper-base-coreml": 145_000_000,     // ~145 MB
        "kb_whisper-small-coreml": 483_000_000,    // ~483 MB
        "kb_whisper-medium-coreml": 1_530_000_000, // ~1.53 GB
        "kb_whisper-large-coreml": 3_090_000_000,  // ~3.09 GB
        
        // OpenAI Whisper sizes (WhisperKit CoreML models)
        "openai_whisper-base": 145_000_000,        // 145 MB
        "openai_whisper-small": 483_000_000,       // 483 MB
        "openai_whisper-medium": 1_530_000_000,    // 1.53 GB
        "openai_whisper-large-v2": 3_090_000_000,  // 3.09 GB
        "openai_whisper-large-v3": 3_090_000_000   // 3.09 GB
    ]
    
    private init() {
        createModelsDirectory()
        checkDownloadedModels()
        loadEnabledWhisperKitModels()
    }
    
    var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                  in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.transcribe.app"
        return appSupport.appendingPathComponent(bundleID).appendingPathComponent("Models")
    }
    
    private func createModelsDirectory() {
        try? FileManager.default.createDirectory(at: modelsDirectory, 
                                                withIntermediateDirectories: true)
    }
    
    private func checkDownloadedModels() {
        // WhisperKit models are managed separately, no need to check files
        // They're tracked via enabledWhisperKitModels
    }
    
    func isModelDownloaded(_ modelName: String) -> Bool {
        // WhisperKit models (including KB CoreML) are "downloaded" if they're enabled
        if modelName.starts(with: "openai_whisper-") || modelName.starts(with: "kb_whisper-") {
            return enabledWhisperKitModels.contains(modelName)
        }
        // Legacy KB GGML models need actual download
        return downloadedModels.contains(modelName)
    }
    
    func isWhisperKitModelEnabled(_ modelName: String) -> Bool {
        return enabledWhisperKitModels.contains(modelName)
    }
    
    func toggleWhisperKitModel(_ modelName: String) {
        if enabledWhisperKitModels.contains(modelName) {
            enabledWhisperKitModels.remove(modelName)
            downloadedModels.remove(modelName)
        } else {
            enabledWhisperKitModels.insert(modelName)
            downloadedModels.insert(modelName)
        }
        saveEnabledWhisperKitModels()
    }
    
    private func loadEnabledWhisperKitModels() {
        if let savedModels = UserDefaults.standard.array(forKey: "enabledWhisperKitModels") as? [String] {
            enabledWhisperKitModels = Set(savedModels)
            // Also add them to downloadedModels for dropdown visibility
            for model in savedModels {
                downloadedModels.insert(model)
            }
        }
    }
    
    private func saveEnabledWhisperKitModels() {
        UserDefaults.standard.set(Array(enabledWhisperKitModels), forKey: "enabledWhisperKitModels")
    }
    
    func downloadModel(_ modelName: String) {
        guard let urlString = modelURLs[modelName] else { return }
        
        // WhisperKit models don't need download, just enable/disable
        if urlString.starts(with: "whisperkit://") {
            // This shouldn't be called for WhisperKit models anymore
            // We use toggleWhisperKitModel instead
            return
        }
        
        // For KB models, download normally
        guard let url = URL(string: urlString) else { return }
        
        isDownloading[modelName] = true
        downloadProgress[modelName] = 0.0
        
        // Create a URLSession with a delegate to track progress
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: DownloadDelegate(modelName: modelName, manager: self), delegateQueue: .main)
        
        let task = session.downloadTask(with: url)
        downloadTasks[modelName] = task
        task.resume()
    }
    
    func cancelDownload(_ modelName: String) {
        downloadTasks[modelName]?.cancel()
        downloadTasks[modelName] = nil
        isDownloading[modelName] = false
        downloadProgress[modelName] = 0.0
    }
    
    func deleteModel(_ modelName: String) {
        // For WhisperKit models, just remove from set
        if modelURLs[modelName]?.starts(with: "whisperkit://") == true {
            downloadedModels.remove(modelName)
            enabledWhisperKitModels.remove(modelName)
            saveEnabledWhisperKitModels()
            // WhisperKit will clean up its own cache
            return
        }
        
        downloadedModels.remove(modelName)
    }
    
    func getModelPath(_ modelName: String) -> URL? {
        // WhisperKit models don't have a file path
        // They're managed by WhisperKit internally
        return nil
    }
    
    func getModelSizeString(_ modelName: String) -> String {
        guard let size = modelSizes[modelName] else { return "Unknown" }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// URLSession delegate to track download progress
class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let modelName: String
    weak var manager: ModelManager?
    
    init(modelName: String, manager: ModelManager) {
        self.modelName = modelName
        self.manager = manager
        super.init()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.manager?.downloadProgress[self.modelName] = progress
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let manager = manager else { return }
        
        // All downloaded models go to the same directory now
        let destinationURL = manager.modelsDirectory.appendingPathComponent("\(modelName).bin")
        
        do {
            // Remove existing file if it exists
            try? FileManager.default.removeItem(at: destinationURL)
            
            // Move downloaded file to destination
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                manager.downloadedModels.insert(self.modelName)
                manager.downloadProgress[self.modelName] = 1.0
                manager.isDownloading[self.modelName] = false
                print("Model \(self.modelName) downloaded successfully to \(destinationURL)")
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("Error saving model \(self.modelName): \(error)")
                manager.downloadProgress[self.modelName] = 0.0
                manager.isDownloading[self.modelName] = false
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("Download error for \(self.modelName): \(error)")
                self.manager?.downloadProgress[self.modelName] = 0.0
                self.manager?.isDownloading[self.modelName] = false
            }
        }
    }
}