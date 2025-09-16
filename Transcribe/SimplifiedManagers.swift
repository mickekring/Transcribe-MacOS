import Foundation
import SwiftUI
import Combine

// Simplified managers that don't have external dependencies for initial build

@MainActor
class TranscriptionManager: ObservableObject {
    @Published var isTranscribing = false
    @Published var currentProgress: Double = 0
    @Published var currentTask: String = ""
    @Published var completedTranscriptions: [TranscriptionResult] = []
    
    init() {
        // Simplified init without dependencies
    }
    
    func transcribeFile(_ url: URL) {
        // Placeholder implementation
        isTranscribing = true
        currentTask = "Transcribing \(url.lastPathComponent)"
        
        // Simulate transcription
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isTranscribing = false
            self?.currentTask = ""
            self?.currentProgress = 0
        }
    }
}

@MainActor
class SettingsManager: ObservableObject {
    @AppStorage("defaultLanguage") var defaultLanguage: String = "sv"
    @AppStorage("enableAutoLanguageDetection") var enableAutoLanguageDetection: Bool = true
    @AppStorage("enableTimestamps") var enableTimestamps: Bool = true
    @AppStorage("enableSpeakerDiarization") var enableSpeakerDiarization: Bool = false
    @AppStorage("preferredLLMProvider") var preferredLLMProvider: String = "ollama"
    @AppStorage("enableLLMEnhancement") var enableLLMEnhancement: Bool = false
    @AppStorage("autoSaveTranscriptions") var autoSaveTranscriptions: Bool = true
    @AppStorage("transcriptionSaveLocation") var transcriptionSaveLocation: String = ""
    
    // API Keys (stored in UserDefaults, should use Keychain in production)
    @AppStorage("bergetAPIKey") var bergetKey: String = ""
    
    // Ollama settings
    @AppStorage("ollamaHost") var ollamaHost: String = "http://127.0.0.1:11434"
    @Published var ollamaModels: [String] = []
    @Published var ollamaConnectionStatus: String = ""
    @AppStorage("selectedOllamaModel") var selectedOllamaModel: String = ""
    
    // Recording settings
    @AppStorage("recordingQuality") var recordingQuality: String = "high"
    @AppStorage("enableNoiseReduction") var enableNoiseReduction: Bool = true
    @AppStorage("enableSilenceTrimming") var enableSilenceTrimming: Bool = true
    @AppStorage("maxRecordingDuration") var maxRecordingDuration: Int = 14400
    
    // UI Settings
    @AppStorage("showStatusBarIcon") var showStatusBarIcon: Bool = true
    @AppStorage("launchAtStartup") var launchAtStartup: Bool = false
    @AppStorage("minimizeToStatusBar") var minimizeToStatusBar: Bool = false
    
    // Privacy settings
    @AppStorage("enableAnalytics") var enableAnalytics: Bool = false
    @AppStorage("localOnlyMode") var localOnlyMode: Bool = false
    @AppStorage("clearHistoryOnQuit") var clearHistoryOnQuit: Bool = false
    
    // Default model and output format as simple strings
    @AppStorage("defaultModel") var defaultModel: String = "kb-whisper-base"
    @AppStorage("defaultOutputFormat") var defaultOutputFormat: String = "txt"
    
    init() {
        // Simplified init
    }
    
    func saveAPIKey(_ key: String, for provider: APIKeyType) {
        // Simplified implementation
        switch provider {
        case .berget:
            bergetKey = key
        }
    }
    
    func validateAPIKey(_ key: String, for provider: APIKeyType) async -> Bool {
        // Simplified validation
        return !key.isEmpty
    }
    
    func checkOllamaConnection() async {
        // Real Ollama API check
        await MainActor.run {
            self.ollamaConnectionStatus = "Connecting..."
        }
        
        guard let url = URL(string: "\(ollamaHost)/api/tags") else {
            await MainActor.run {
                self.ollamaModels = []
                self.ollamaConnectionStatus = "Invalid URL"
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.ollamaModels = []
                    self.ollamaConnectionStatus = "Connection failed"
                }
                return
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { $0["name"] as? String }
                await MainActor.run {
                    self.ollamaModels = modelNames
                    self.ollamaConnectionStatus = modelNames.isEmpty ? "Connected (no models installed)" : "Connected (\(modelNames.count) models)"
                }
            } else {
                await MainActor.run {
                    self.ollamaModels = []
                    self.ollamaConnectionStatus = "Connected (no models found)"
                }
            }
        } catch {
            print("Ollama connection error: \(error)")
            await MainActor.run {
                self.ollamaModels = []
                self.ollamaConnectionStatus = "Not running (start Ollama first)"
            }
        }
    }
    
    func resetToDefaults() {
        defaultLanguage = "sv"
        enableAutoLanguageDetection = true
        // Reset other settings...
    }
}

enum APIKeyType: String {
    case berget = "Berget"
}