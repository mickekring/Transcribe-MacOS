import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedSection = "general"
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundStyle(LinearGradient.accentGradient)
                    Text(localized("settings"))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                
                Divider()
                    .foregroundColor(.borderLight)
                
                // Menu Items
                ScrollView {
                    VStack(spacing: 2) {
                        // General Section
                        SectionHeader(title: localized("general").uppercased())
                        
                        SettingsMenuItem(
                            icon: "gearshape",
                            title: localized("general"),
                            isSelected: selectedSection == "general",
                            action: { selectedSection = "general" }
                        )
                        
                        SettingsMenuItem(
                            icon: "key",
                            title: localized("api_keys"),
                            isSelected: selectedSection == "api",
                            action: { selectedSection = "api" }
                        )
                        
                        // Transcribe Section
                        SectionHeader(title: localized("transcription").uppercased())
                            .padding(.top, 16)
                        
                        SettingsMenuItem(
                            icon: "laptopcomputer",
                            title: localized("local_models"),
                            isSelected: selectedSection == "local_models",
                            action: { selectedSection = "local_models" }
                        )
                        
                        SettingsMenuItem(
                            icon: "cloud",
                            title: localized("cloud_models"),
                            isSelected: selectedSection == "cloud_models",
                            action: { selectedSection = "cloud_models" }
                        )
                        
                        // Language Models Section
                        SectionHeader(title: localized("language_models").uppercased())
                            .padding(.top, 16)
                        
                        SettingsMenuItem(
                            icon: "laptopcomputer",
                            title: localized("local_models"),
                            isSelected: selectedSection == "llm_local",
                            action: { selectedSection = "llm_local" }
                        )
                        
                        SettingsMenuItem(
                            icon: "cloud",
                            title: localized("cloud_models"),
                            isSelected: selectedSection == "llm_cloud",
                            action: { selectedSection = "llm_cloud" }
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                }
            }
            .background(Color.white)
            .navigationSplitViewColumnWidth(min: 320, ideal: 340, max: 380)
            .toolbar(removing: .sidebarToggle)
            
        } detail: {
            // Detail view based on selection
            ZStack {
                LinearGradient.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    switch selectedSection {
                    case "general":
                        GeneralSettingsView()
                    case "local_models":
                        LocalModelsView()
                    case "cloud_models":
                        CloudModelsView()
                    case "api":
                        APIKeysView()
                    case "llm_local":
                        LLMLocalModelsView()
                    case "llm_cloud":
                        LLMCloudModelsView()
                    default:
                        GeneralSettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("")
        .frame(width: 1040, height: 640)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.accentGradient)
                Text(localized("general"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 32) {
                // App Language
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text(localized("app_language"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        } icon: {
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundStyle(LinearGradient.accentGradient)
                        }
                        
                        Picker("", selection: $localizationManager.appLanguage) {
                            Text(localized("english")).tag("en")
                            Text(localized("swedish")).tag("sv")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                        .onChange(of: localizationManager.appLanguage) { newValue in
                            localizationManager.updateLanguage()
                        }
                        
                        Text(localized("app_language_description"))
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct LocalModelsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var modelManager = ModelManager.shared
    @State private var selectedModel = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.accentGradient)
                Text(localized("local_models"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                // KB Whisper Models Card
                SettingsCard {
                    VStack(alignment: .leading, spacing: 15) {
                        Label {
                            Text("KB Whisper")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        } icon: {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Finjusterade av Kungliga Biblioteket för svenska (laddas ner vid första användning)")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        VStack(spacing: 10) {
                            WhisperKitModelRow(
                                modelId: "kb_whisper-base-coreml",
                                name: "KB Whisper Base",
                                size: modelManager.getModelSizeString("kb_whisper-base-coreml"),
                                description: localized("balanced_speed_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("kb_whisper-base-coreml"),
                                onToggle: { modelManager.toggleWhisperKitModel("kb_whisper-base-coreml") }
                            )
                            
                            WhisperKitModelRow(
                                modelId: "kb_whisper-small-coreml",
                                name: "KB Whisper Small",
                                size: modelManager.getModelSizeString("kb_whisper-small-coreml"),
                                description: localized("good_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("kb_whisper-small-coreml"),
                                onToggle: { modelManager.toggleWhisperKitModel("kb_whisper-small-coreml") }
                            )
                            
                            WhisperKitModelRow(
                                modelId: "kb_whisper-medium-coreml",
                                name: "KB Whisper Medium",
                                size: modelManager.getModelSizeString("kb_whisper-medium-coreml"),
                                description: localized("high_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("kb_whisper-medium-coreml"),
                                onToggle: { modelManager.toggleWhisperKitModel("kb_whisper-medium-coreml") }
                            )
                            
                            WhisperKitModelRow(
                                modelId: "kb_whisper-large-coreml",
                                name: "KB Whisper Large",
                                size: modelManager.getModelSizeString("kb_whisper-large-coreml"),
                                description: localized("highest_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("kb_whisper-large-coreml"),
                                onToggle: { modelManager.toggleWhisperKitModel("kb_whisper-large-coreml") }
                            )
                        }
                    }
                }
                
                // OpenAI Whisper Models Card
                SettingsCard {
                    VStack(alignment: .leading, spacing: 15) {
                        Label {
                            Text("Whisper")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        } icon: {
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                        
                        Text("OpenAI:s flerspråkiga modeller (laddas ner vid första användning)")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        VStack(spacing: 10) {
                            WhisperKitModelRow(
                                modelId: "openai_whisper-base",
                                name: "Whisper Base",
                                size: modelManager.getModelSizeString("openai_whisper-base"),
                                description: localized("balanced_speed_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("openai_whisper-base"),
                                onToggle: { modelManager.toggleWhisperKitModel("openai_whisper-base") }
                            )
                            
                            WhisperKitModelRow(
                                modelId: "openai_whisper-small",
                                name: "Whisper Small",
                                size: modelManager.getModelSizeString("openai_whisper-small"),
                                description: localized("good_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("openai_whisper-small"),
                                onToggle: { modelManager.toggleWhisperKitModel("openai_whisper-small") }
                            )
                            
                            WhisperKitModelRow(
                                modelId: "openai_whisper-medium",
                                name: "Whisper Medium",
                                size: modelManager.getModelSizeString("openai_whisper-medium"),
                                description: localized("high_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("openai_whisper-medium"),
                                onToggle: { modelManager.toggleWhisperKitModel("openai_whisper-medium") }
                            )
                            
                            WhisperKitModelRow(
                                modelId: "openai_whisper-large-v2",
                                name: "Whisper Large v2",
                                size: modelManager.getModelSizeString("openai_whisper-large-v2"),
                                description: localized("high_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("openai_whisper-large-v2"),
                                onToggle: { modelManager.toggleWhisperKitModel("openai_whisper-large-v2") }
                            )
                            
                            WhisperKitModelRow(
                                modelId: "openai_whisper-large-v3",
                                name: "Whisper Large v3",
                                size: modelManager.getModelSizeString("openai_whisper-large-v3"),
                                description: localized("best_accuracy"),
                                isEnabled: modelManager.isWhisperKitModelEnabled("openai_whisper-large-v3"),
                                onToggle: { modelManager.toggleWhisperKitModel("openai_whisper-large-v3") }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct CloudModelsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @AppStorage("bergetTranscriptionEnabled") private var bergetEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cloud")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.accentGradient)
                Text(localized("cloud_models"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Berget (First - GDPR safe)
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Label {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Berget 🇸🇪")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                }
                            } icon: {
                                Image(systemName: "cloud")
                                    .font(.system(size: 18))
                                    .foregroundStyle(LinearGradient.accentGradient)
                            }
                            
                            Text("GDPR-säker - All data stannar i Sverige")
                                .font(.system(size: 13))
                                .foregroundColor(.textPrimary)
                            
                            if settingsManager.bergetKey.isEmpty {
                                Text(localized("api_key_required"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                            
                            Divider()
                            
                            // KB Whisper Large model
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("KB Whisper Large")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("Svensk optimerad transkribering")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $bergetEnabled)
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .disabled(settingsManager.bergetKey.isEmpty)
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct WhisperKitModelRow: View {
    let modelId: String
    let name: String
    let size: String
    let description: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                    
                    if isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(size)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ModelRow: View {
    let modelId: String
    let name: String
    let size: String
    let description: String
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                    
                    if isDownloaded {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(size)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
            
            if isDownloading {
                HStack(spacing: 8) {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 80)
                    
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 35)
                }
            } else if isDownloaded {
                Button(action: onDelete) {
                    Text(localized("remove"))
                        .font(.caption)
                        .frame(width: 70)
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: onDownload) {
                    Text(localized("download"))
                        .font(.caption)
                        .frame(width: 70)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CloudModelRow: View {
    let provider: String
    let model: String
    let status: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(provider)
                    .font(.system(size: 13, weight: .medium))
                
                Text(model)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .foregroundColor(status == "Available" ? .green : .orange)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct APIKeysView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var tempBergetKey = ""
    @State private var showBergetKey = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "key")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.accentGradient)
                Text(localized("api_keys"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 32) {
                // Berget
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Berget 🇸🇪")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        } icon: {
                            Image(systemName: "mountain.2")
                                .font(.system(size: 18))
                                .foregroundStyle(LinearGradient.accentGradient)
                        }
                        
                        Text("Svensk GDPR-säker molntjänst för transkribering")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        HStack {
                            if showBergetKey {
                                TextField(localized("api_key"), text: $tempBergetKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 400)
                            } else {
                                SecureField(localized("api_key"), text: $tempBergetKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 400)
                            }
                            
                            Button(action: { showBergetKey.toggle() }) {
                                Image(systemName: showBergetKey ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                            
                            Button(localized("save")) {
                                settingsManager.saveAPIKey(tempBergetKey, for: .berget)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            .disabled(tempBergetKey.isEmpty)
                            
                            if !settingsManager.bergetKey.isEmpty {
                                Button(localizationManager.currentLanguage == "sv" ? "Ta bort" : "Remove") {
                                    settingsManager.saveAPIKey("", for: .berget)
                                    tempBergetKey = ""
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                            }
                        }
                        
                        Link(localized("get_api_key_berget"), destination: URL(string: "https://berget.ai")!)
                            .font(.system(size: 12))
                            .foregroundColor(.primaryAccent)
                    }
                }
                
                // Ollama
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Ollama")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        } icon: {
                            Image(systemName: "server.rack")
                                .font(.system(size: 18))
                                .foregroundStyle(LinearGradient.accentGradient)
                        }
                        
                        Text(localized("ollama_description"))
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        HStack {
                            TextField(localized("host_url"), text: $settingsManager.ollamaHost)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 400)
                            
                            Button(localized("test_connection")) {
                                Task {
                                    await settingsManager.checkOllamaConnection()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                        }
                        
                        if !settingsManager.ollamaConnectionStatus.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: settingsManager.ollamaModels.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(settingsManager.ollamaModels.isEmpty ? .orange : .green)
                                Text(settingsManager.ollamaConnectionStatus)
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        if !settingsManager.ollamaModels.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localized("available_models"))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                
                                ForEach(settingsManager.ollamaModels, id: \.self) { model in
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.green)
                                        Text(model)
                                            .font(.system(size: 12))
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            tempBergetKey = settingsManager.bergetKey
        }
    }
}

struct LLMLocalModelsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var enabledModels: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.accentGradient)
                Text(localized("local_models"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Ollama Models
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Label {
                                Text("Ollama")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                            } icon: {
                                Image(systemName: "laptopcomputer")
                                    .font(.system(size: 18))
                                    .foregroundStyle(LinearGradient.accentGradient)
                            }
                            
                            Text(localized("ollama_description"))
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            
                            Divider()
                            
                            // Connection Status
                            HStack {
                                Text(localized("host_url") + ":")
                                    .font(.subheadline)
                                TextField("", text: $settingsManager.ollamaHost)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                                
                                Button(localized("test_connection")) {
                                    Task {
                                        await settingsManager.checkOllamaConnection()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            if !settingsManager.ollamaConnectionStatus.isEmpty {
                                Text(settingsManager.ollamaConnectionStatus)
                                    .font(.caption)
                                    .foregroundColor(settingsManager.ollamaConnectionStatus.contains("Connected") ? .green : .orange)
                            }
                            
                            // Available Models
                            if !settingsManager.ollamaModels.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(settingsManager.ollamaModels, id: \.self) { model in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(model)
                                                    .font(.system(size: 13, weight: .medium))
                                                Text("Local language model")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Toggle("", isOn: Binding(
                                                get: { enabledModels.contains(model) },
                                                set: { enabled in
                                                    if enabled {
                                                        enabledModels.insert(model)
                                                    } else {
                                                        enabledModels.remove(model)
                                                    }
                                                }
                                            ))
                                            .toggleStyle(.switch)
                                            .controlSize(.small)
                                        }
                                        .padding(12)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            Task {
                await settingsManager.checkOllamaConnection()
            }
        }
    }
}

struct LLMCloudModelsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var enabledBergetModels: Set<String> = []
    
    let bergetModels = [
        "Llama 3.3 70B Instruct",
        "Mistral Small 3.1 24B Instruct",
        "GPT-OSS-120B"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "cloud")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.accentGradient)
                Text(localized("cloud_models"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Berget Models (First - GDPR safe)
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Label {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Berget 🇸🇪")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                }
                            } icon: {
                                Image(systemName: "cloud")
                                    .font(.system(size: 18))
                                    .foregroundStyle(LinearGradient.accentGradient)
                            }
                            
                            Text("GDPR-säker - All data stannar i Sverige")
                                .font(.system(size: 13))
                                .foregroundColor(.textPrimary)
                            
                            if settingsManager.bergetKey.isEmpty {
                                Text(localized("api_key_required"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                            
                            Divider()
                            
                            VStack(spacing: 8) {
                                ForEach(bergetModels, id: \.self) { model in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(model)
                                                .font(.system(size: 13, weight: .medium))
                                            Text("Svensk värdlösning")
                                                .font(.system(size: 11))
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: Binding(
                                            get: { enabledBergetModels.contains(model) },
                                            set: { enabled in
                                                if enabled {
                                                    enabledBergetModels.insert(model)
                                                } else {
                                                    enabledBergetModels.remove(model)
                                                }
                                            }
                                        ))
                                        .toggleStyle(.switch)
                                        .controlSize(.small)
                                        .disabled(settingsManager.bergetKey.isEmpty)
                                    }
                                    .padding(12)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct PromptRow: View {
    let title: String
    @State var prompt: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
            
            TextEditor(text: $prompt)
                .font(.caption)
                .frame(height: 60)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .shadowColor, radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderLight, lineWidth: 1)
        )
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

struct SettingsMenuItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? LinearGradient.accentGradient : LinearGradient(
                        colors: [Color.textSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.hoverBackground : (isHovered ? Color.hoverBackground.opacity(0.5) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}
