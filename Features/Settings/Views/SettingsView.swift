import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTab = "general"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")
            
            TranscriptionSettingsView()
                .tabItem {
                    Label("Transcription", systemImage: "waveform")
                }
                .tag("transcription")
            
            APISettingsView()
                .tabItem {
                    Label("API Keys", systemImage: "key")
                }
                .tag("api")
            
            RecordingSettingsView()
                .tabItem {
                    Label("Recording", systemImage: "mic")
                }
                .tag("recording")
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "lock")
                }
                .tag("privacy")
        }
        .frame(width: 600, height: 400)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Show in Menu Bar", isOn: $settingsManager.showStatusBarIcon)
                Toggle("Launch at Startup", isOn: $settingsManager.launchAtStartup)
                Toggle("Minimize to Menu Bar", isOn: $settingsManager.minimizeToStatusBar)
            }
            
            Section("Language") {
                Picker("Default Language", selection: $settingsManager.defaultLanguage) {
                    Text("Swedish").tag("sv")
                    Text("English").tag("en")
                    Text("Norwegian").tag("no")
                    Text("Danish").tag("da")
                }
                
                Toggle("Auto-detect Language", isOn: $settingsManager.enableAutoLanguageDetection)
            }
            
            Section("Storage") {
                Toggle("Auto-save Transcriptions", isOn: $settingsManager.autoSaveTranscriptions)
                
                if settingsManager.autoSaveTranscriptions {
                    HStack {
                        Text("Save Location:")
                        TextField("Default location", text: $settingsManager.transcriptionSaveLocation)
                            .textFieldStyle(.roundedBorder)
                        Button("Choose...") {
                            chooseDirectory()
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            settingsManager.transcriptionSaveLocation = panel.url?.path ?? ""
        }
    }
}

struct TranscriptionSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var downloadedModels: [WhisperModel] = []
    
    var body: some View {
        Form {
            Section("Model Selection") {
                Picker("Default Model", selection: Binding(
                    get: { WhisperModel(rawValue: settingsManager.defaultModel) ?? .base },
                    set: { settingsManager.defaultModel = $0.rawValue }
                )) {
                    ForEach(WhisperModel.allCases, id: \.self) { model in
                        HStack {
                            Text(model.displayName)
                            Spacer()
                            Text("\(model.sizeInMB) MB")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(model)
                    }
                }
                
                Button("Manage Models") {
                    openModelManager()
                }
            }
            
            Section("Output") {
                Picker("Default Format", selection: Binding(
                    get: { OutputFormat(rawValue: settingsManager.defaultOutputFormat) ?? .text },
                    set: { settingsManager.defaultOutputFormat = $0.rawValue }
                )) {
                    ForEach(OutputFormat.allCases, id: \.self) { format in
                        Text(format.rawValue.uppercased()).tag(format)
                    }
                }
                
                Toggle("Include Timestamps", isOn: $settingsManager.enableTimestamps)
                Toggle("Speaker Diarization", isOn: $settingsManager.enableSpeakerDiarization)
            }
            
            Section("LLM Enhancement") {
                Toggle("Enable LLM Processing", isOn: $settingsManager.enableLLMEnhancement)
                
                if settingsManager.enableLLMEnhancement {
                    Picker("Preferred Provider", selection: $settingsManager.preferredLLMProvider) {
                        Text("Ollama (Local)").tag("ollama")
                        Text("OpenAI").tag("openai")
                        Text("Groq").tag("groq")
                        Text("Berget").tag("berget")
                    }
                }
            }
        }
        .padding()
        .onAppear {
            loadDownloadedModels()
        }
    }
    
    func loadDownloadedModels() {
        downloadedModels = ModelManager.shared.getDownloadedModels()
    }
    
    func openModelManager() {
        // Open model manager window
    }
}

struct APISettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var tempOpenAIKey = ""
    @State private var tempGroqKey = ""
    @State private var tempBergetKey = ""
    @State private var isValidatingOpenAI = false
    @State private var isValidatingGroq = false
    @State private var isValidatingBerget = false
    
    var body: some View {
        Form {
            Section("OpenAI") {
                HStack {
                    SecureField("API Key", text: $tempOpenAIKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Save") {
                        saveOpenAIKey()
                    }
                    .disabled(tempOpenAIKey.isEmpty)
                    
                    if isValidatingOpenAI {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
                
                Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
            }
            
            Section("Groq") {
                HStack {
                    SecureField("API Key", text: $tempGroqKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Save") {
                        saveGroqKey()
                    }
                    .disabled(tempGroqKey.isEmpty)
                    
                    if isValidatingGroq {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
                
                Link("Get API Key", destination: URL(string: "https://console.groq.com/keys")!)
                    .font(.caption)
            }
            
            Section("Berget AI") {
                HStack {
                    SecureField("API Key", text: $tempBergetKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Save") {
                        saveBergetKey()
                    }
                    .disabled(tempBergetKey.isEmpty)
                    
                    if isValidatingBerget {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
                
                Link("Get API Key", destination: URL(string: "https://berget.ai")!)
                    .font(.caption)
            }
            
            Section("Ollama") {
                HStack {
                    Text("Host:")
                    TextField("http://127.0.0.1:11434", text: $settingsManager.ollamaHost)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Test Connection") {
                        testOllamaConnection()
                    }
                }
                
                if !settingsManager.ollamaModels.isEmpty {
                    Picker("Default Model", selection: $settingsManager.selectedOllamaModel) {
                        Text("None").tag("")
                        ForEach(settingsManager.ollamaModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            loadExistingKeys()
        }
    }
    
    func loadExistingKeys() {
        tempOpenAIKey = settingsManager.openAIKey.isEmpty ? "" : "••••••••"
        tempGroqKey = settingsManager.groqKey.isEmpty ? "" : "••••••••"
        tempBergetKey = settingsManager.bergetKey.isEmpty ? "" : "••••••••"
    }
    
    func saveOpenAIKey() {
        isValidatingOpenAI = true
        Task {
            if await settingsManager.validateAPIKey(tempOpenAIKey, for: .openai) {
                settingsManager.saveAPIKey(tempOpenAIKey, for: .openai)
                await MainActor.run {
                    tempOpenAIKey = "••••••••"
                }
            }
            await MainActor.run {
                isValidatingOpenAI = false
            }
        }
    }
    
    func saveGroqKey() {
        isValidatingGroq = true
        Task {
            if await settingsManager.validateAPIKey(tempGroqKey, for: .groq) {
                settingsManager.saveAPIKey(tempGroqKey, for: .groq)
                await MainActor.run {
                    tempGroqKey = "••••••••"
                }
            }
            await MainActor.run {
                isValidatingGroq = false
            }
        }
    }
    
    func saveBergetKey() {
        isValidatingBerget = true
        Task {
            if await settingsManager.validateAPIKey(tempBergetKey, for: .berget) {
                settingsManager.saveAPIKey(tempBergetKey, for: .berget)
                await MainActor.run {
                    tempBergetKey = "••••••••"
                }
            }
            await MainActor.run {
                isValidatingBerget = false
            }
        }
    }
    
    func testOllamaConnection() {
        Task {
            await settingsManager.checkOllamaConnection()
        }
    }
}

struct RecordingSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section("Quality") {
                Picker("Recording Quality", selection: $settingsManager.recordingQuality) {
                    Text("Low (8kHz)").tag("low")
                    Text("Medium (16kHz)").tag("medium")
                    Text("High (44.1kHz)").tag("high")
                    Text("Ultra (48kHz)").tag("ultra")
                }
            }
            
            Section("Processing") {
                Toggle("Noise Reduction", isOn: $settingsManager.enableNoiseReduction)
                Toggle("Trim Silence", isOn: $settingsManager.enableSilenceTrimming)
            }
            
            Section("Limits") {
                HStack {
                    Text("Max Duration:")
                    TextField("seconds", value: $settingsManager.maxRecordingDuration, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("seconds (\(formatDuration(settingsManager.maxRecordingDuration)))")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section("Data") {
                Toggle("Local-only Mode", isOn: $settingsManager.localOnlyMode)
                    .help("Disable all cloud features and API calls")
                
                Toggle("Clear History on Quit", isOn: $settingsManager.clearHistoryOnQuit)
                
                Button("Clear All Data") {
                    clearAllData()
                }
                .foregroundColor(.red)
            }
            
            Section("Analytics") {
                Toggle("Share Analytics", isOn: $settingsManager.enableAnalytics)
                    .help("Help improve Transcribe by sharing anonymous usage data")
            }
            
            Section("Export/Import") {
                HStack {
                    Button("Export Settings") {
                        exportSettings()
                    }
                    
                    Button("Import Settings") {
                        importSettings()
                    }
                }
                
                Button("Reset to Defaults") {
                    settingsManager.resetToDefaults()
                }
                .foregroundColor(.orange)
            }
        }
        .padding()
    }
    
    func clearAllData() {
        // Show confirmation dialog and clear data
    }
    
    func exportSettings() {
        guard let data = settingsManager.exportSettings() else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "transcribe-settings.json"
        
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
    
    func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url,
           let data = try? Data(contentsOf: url) {
            settingsManager.importSettings(from: data)
        }
    }
}