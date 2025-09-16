import Foundation
import SwiftUI
import Security

@MainActor
class SettingsManager: ObservableObject {
    @AppStorage("defaultModel") var defaultModel: String = WhisperModel.base.rawValue
    @AppStorage("defaultLanguage") var defaultLanguage: String = "sv"
    @AppStorage("enableAutoLanguageDetection") var enableAutoLanguageDetection: Bool = true
    @AppStorage("enableTimestamps") var enableTimestamps: Bool = true
    @AppStorage("enableSpeakerDiarization") var enableSpeakerDiarization: Bool = false
    @AppStorage("preferredLLMProvider") var preferredLLMProvider: String = "ollama"
    @AppStorage("enableLLMEnhancement") var enableLLMEnhancement: Bool = false
    @AppStorage("defaultOutputFormat") var defaultOutputFormat: String = OutputFormat.text.rawValue
    @AppStorage("autoSaveTranscriptions") var autoSaveTranscriptions: Bool = true
    @AppStorage("transcriptionSaveLocation") var transcriptionSaveLocation: String = ""
    
    // API Keys (stored in Keychain)
    @Published var openAIKey: String = ""
    @Published var groqKey: String = ""
    @Published var bergetKey: String = ""
    
    // Ollama settings
    @AppStorage("ollamaHost") var ollamaHost: String = "http://127.0.0.1:11434"
    @Published var ollamaModels: [String] = []
    @AppStorage("selectedOllamaModel") var selectedOllamaModel: String = ""
    
    // Recording settings
    @AppStorage("recordingQuality") var recordingQuality: String = "high"
    @AppStorage("enableNoiseReduction") var enableNoiseReduction: Bool = true
    @AppStorage("enableSilenceTrimming") var enableSilenceTrimming: Bool = true
    @AppStorage("maxRecordingDuration") var maxRecordingDuration: Int = 14400 // 4 hours in seconds
    
    // UI Settings
    @AppStorage("showStatusBarIcon") var showStatusBarIcon: Bool = true
    @AppStorage("launchAtStartup") var launchAtStartup: Bool = false
    @AppStorage("minimizeToStatusBar") var minimizeToStatusBar: Bool = false
    
    // Privacy settings
    @AppStorage("enableAnalytics") var enableAnalytics: Bool = false
    @AppStorage("localOnlyMode") var localOnlyMode: Bool = false
    @AppStorage("clearHistoryOnQuit") var clearHistoryOnQuit: Bool = false
    
    private let keychainService = "com.transcribe.macos"
    
    init() {
        loadAPIKeys()
        Task {
            await checkOllamaConnection()
        }
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey(_ key: String, for provider: APIProvider) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.rawValue,
            kSecValueData as String: key.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete existing key
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            switch provider {
            case .openai:
                openAIKey = key
            case .groq:
                groqKey = key
            case .berget:
                bergetKey = key
            }
        }
    }
    
    func loadAPIKeys() {
        openAIKey = loadAPIKey(for: .openai) ?? ""
        groqKey = loadAPIKey(for: .groq) ?? ""
        bergetKey = loadAPIKey(for: .berget) ?? ""
    }
    
    private func loadAPIKey(for provider: APIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            return key
        }
        
        return nil
    }
    
    func deleteAPIKey(for provider: APIProvider) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
        
        switch provider {
        case .openai:
            openAIKey = ""
        case .groq:
            groqKey = ""
        case .berget:
            bergetKey = ""
        }
    }
    
    // MARK: - Ollama Management
    
    func checkOllamaConnection() async {
        guard let url = URL(string: "\(ollamaHost)/api/tags") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let response = try? JSONDecoder().decode(OllamaModelsResponse.self, from: data) {
                await MainActor.run {
                    self.ollamaModels = response.models.map { $0.name }
                }
            }
        } catch {
            print("Failed to connect to Ollama: \(error)")
            await MainActor.run {
                self.ollamaModels = []
            }
        }
    }
    
    // MARK: - Validation
    
    func validateAPIKey(_ key: String, for provider: APIProvider) async -> Bool {
        switch provider {
        case .openai:
            return await validateOpenAIKey(key)
        case .groq:
            return await validateGroqKey(key)
        case .berget:
            return await validateBergetKey(key)
        }
    }
    
    private func validateOpenAIKey(_ key: String) async -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/models") else { return false }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func validateGroqKey(_ key: String) async -> Bool {
        guard let url = URL(string: "https://api.groq.com/openai/v1/models") else { return false }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func validateBergetKey(_ key: String) async -> Bool {
        // Placeholder - implement when Berget API details are available
        return true
    }
    
    // MARK: - Export/Import Settings
    
    func exportSettings() -> Data? {
        let settings = ExportableSettings(
            defaultModel: defaultModel,
            defaultLanguage: defaultLanguage,
            enableAutoLanguageDetection: enableAutoLanguageDetection,
            enableTimestamps: enableTimestamps,
            enableSpeakerDiarization: enableSpeakerDiarization,
            preferredLLMProvider: preferredLLMProvider,
            enableLLMEnhancement: enableLLMEnhancement,
            defaultOutputFormat: defaultOutputFormat,
            autoSaveTranscriptions: autoSaveTranscriptions,
            transcriptionSaveLocation: transcriptionSaveLocation,
            ollamaHost: ollamaHost,
            selectedOllamaModel: selectedOllamaModel,
            recordingQuality: recordingQuality,
            enableNoiseReduction: enableNoiseReduction,
            enableSilenceTrimming: enableSilenceTrimming,
            maxRecordingDuration: maxRecordingDuration,
            showStatusBarIcon: showStatusBarIcon,
            launchAtStartup: launchAtStartup,
            minimizeToStatusBar: minimizeToStatusBar,
            enableAnalytics: enableAnalytics,
            localOnlyMode: localOnlyMode,
            clearHistoryOnQuit: clearHistoryOnQuit
        )
        
        return try? JSONEncoder().encode(settings)
    }
    
    func importSettings(from data: Data) {
        guard let settings = try? JSONDecoder().decode(ExportableSettings.self, from: data) else { return }
        
        defaultModel = settings.defaultModel
        defaultLanguage = settings.defaultLanguage
        enableAutoLanguageDetection = settings.enableAutoLanguageDetection
        enableTimestamps = settings.enableTimestamps
        enableSpeakerDiarization = settings.enableSpeakerDiarization
        preferredLLMProvider = settings.preferredLLMProvider
        enableLLMEnhancement = settings.enableLLMEnhancement
        defaultOutputFormat = settings.defaultOutputFormat
        autoSaveTranscriptions = settings.autoSaveTranscriptions
        transcriptionSaveLocation = settings.transcriptionSaveLocation
        ollamaHost = settings.ollamaHost
        selectedOllamaModel = settings.selectedOllamaModel
        recordingQuality = settings.recordingQuality
        enableNoiseReduction = settings.enableNoiseReduction
        enableSilenceTrimming = settings.enableSilenceTrimming
        maxRecordingDuration = settings.maxRecordingDuration
        showStatusBarIcon = settings.showStatusBarIcon
        launchAtStartup = settings.launchAtStartup
        minimizeToStatusBar = settings.minimizeToStatusBar
        enableAnalytics = settings.enableAnalytics
        localOnlyMode = settings.localOnlyMode
        clearHistoryOnQuit = settings.clearHistoryOnQuit
    }
    
    func resetToDefaults() {
        // Reset all settings to defaults
        defaultModel = WhisperModel.base.rawValue
        defaultLanguage = "sv"
        enableAutoLanguageDetection = true
        enableTimestamps = true
        enableSpeakerDiarization = false
        preferredLLMProvider = "ollama"
        enableLLMEnhancement = false
        defaultOutputFormat = OutputFormat.text.rawValue
        autoSaveTranscriptions = true
        transcriptionSaveLocation = ""
        ollamaHost = "http://127.0.0.1:11434"
        selectedOllamaModel = ""
        recordingQuality = "high"
        enableNoiseReduction = true
        enableSilenceTrimming = true
        maxRecordingDuration = 14400
        showStatusBarIcon = true
        launchAtStartup = false
        minimizeToStatusBar = false
        enableAnalytics = false
        localOnlyMode = false
        clearHistoryOnQuit = false
    }
}

enum APIProvider: String {
    case openai = "OpenAI"
    case groq = "Groq"
    case berget = "Berget"
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
    let modified_at: String
    let size: Int64
}

struct ExportableSettings: Codable {
    let defaultModel: String
    let defaultLanguage: String
    let enableAutoLanguageDetection: Bool
    let enableTimestamps: Bool
    let enableSpeakerDiarization: Bool
    let preferredLLMProvider: String
    let enableLLMEnhancement: Bool
    let defaultOutputFormat: String
    let autoSaveTranscriptions: Bool
    let transcriptionSaveLocation: String
    let ollamaHost: String
    let selectedOllamaModel: String
    let recordingQuality: String
    let enableNoiseReduction: Bool
    let enableSilenceTrimming: Bool
    let maxRecordingDuration: Int
    let showStatusBarIcon: Bool
    let launchAtStartup: Bool
    let minimizeToStatusBar: Bool
    let enableAnalytics: Bool
    let localOnlyMode: Bool
    let clearHistoryOnQuit: Bool
}