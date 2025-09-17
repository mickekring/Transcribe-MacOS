import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var modelManager = ModelManager.shared
    @State private var searchText = ""
    @State private var selectedHistoryItem: SearchHistoryItem?
    @State private var isDraggingFile = false
    @AppStorage("selectedTranscriptionModel") private var selectedModel: String = "kb-whisper-small"
    @AppStorage("bergetTranscriptionEnabled") private var bergetTranscriptionEnabled = false
    @State private var showAllLanguages = false
    @State private var showLanguagePopover = false
    @State private var showModelPopover = false
    @State private var showFileImporter = false
    @State private var showYouTubeView = false
    
    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            if appState.showRecordingView {
                RecordingView()
            } else if appState.showTranscriptionView, let url = appState.currentTranscriptionURL {
                TranscriptionView(fileURL: url)
            } else {
                mainContent
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack(spacing: 8) {
                    languageDropdown
                    modelDropdown
                    settingsButton
                }
                .padding(.top, 16)
                .padding(.trailing, 12)
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .onDrop(of: [.fileURL], isTargeted: $isDraggingFile) { providers in
            handleFileDrop(providers)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio, .movie, .mp3, .wav, .mpeg4Audio, .quickTimeMovie, .mpeg4Movie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appState.openFileForTranscription(url)
                }
            case .failure(let error):
                print("File import error: \(error)")
            }
        }
        .sheet(isPresented: $showYouTubeView) {
            YouTubeTranscriptionView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowTranscriptionView"))) { notification in
            if let userInfo = notification.userInfo,
               let fileURL = userInfo["fileURL"] as? URL {
                appState.openFileForTranscription(fileURL)
            }
        }
    }
    
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(LinearGradient.accentGradient)
                    Text("Transcribe")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                .padding(.top, 20)
                
                searchBar
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            Divider()
                .foregroundColor(.borderLight)
            
            historyList
        }
        .background(Color.white)
    }
    
    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.textTertiary)
            TextField(localized("search_history"), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.borderLight, lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    var historyList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(localized("older"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textTertiary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                VStack(spacing: 2) {
                    ForEach(appState.searchHistory) { item in
                        HistoryItemRow(item: item)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedHistoryItem?.id == item.id ? Color.hoverBackground : Color.clear)
                            )
                            .onTapGesture {
                                selectedHistoryItem = item
                            }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    var mainContent: some View {
        ZStack {
            // Background layers
            ZStack {
                // Background image with very low opacity
                GeometryReader { geometry in
                    Image("background-image2")  // Your image from Assets
                        .resizable()
                        .scaledToFill()  // Ensures image fills entire space
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()  // Clips any overflow
                        .ignoresSafeArea()
                        .opacity(0.12)  // 8% opacity - adjust to taste (0.05-0.15)
                        .blur(radius: 1)  // Slight blur for subtlety
                }
                .ignoresSafeArea()
                
                // Purple gradient overlay
                LinearGradient.primaryGradient
                    .ignoresSafeArea()
                    .opacity(0.92)  // 92% opacity to let image subtly show through
            }
            
            if isDraggingFile {
                dragOverlay
            } else {
                featureGrid
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDraggingFile)
    }
    
    var featureGrid: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 32) {
                VStack(spacing: 24) {
                    Text(localized("transcribe"))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.accentGradient)
                    
                    Text(localized("drag_drop_hint"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                
                primaryFeatures
            }
            
            Spacer()
            
            footerSection
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
    }
    
    var footerSection: some View {
        VStack(spacing: 12) {
            Text(localizationManager.currentLanguage == "sv" ? "En prototyp av Micke Kring - mickekring.se" : "A prototype by Micke Kring - mickekring.se")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
            
            Button(action: {
                // TODO: Show support view
            }) {
                Text(localizationManager.currentLanguage == "sv" ? "Hjälp / Support" : "Help / Support")
                    .font(.system(size: 12))
                    .foregroundColor(.primaryAccent)
                    .underline()
            }
            .buttonStyle(.plain)
            
            // Version and build number
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    var primaryFeatures: some View {
        HStack(spacing: 20) {
            FeatureCard(
                icon: "doc.badge.arrow.up.fill",
                title: "Öppna filer",
                action: openFiles
            )
            
            FeatureCard(
                icon: "mic.circle.fill",
                title: localized("new_recording"),
                action: newRecording
            )
            
            FeatureCard(
                icon: "play.rectangle.fill",
                title: "YouTube",
                action: {
                    showYouTubeView = true
                }
            )
        }
    }
    
    
    var dragOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.98))
                .shadow(color: Color.primaryAccent.opacity(0.2), radius: 30, y: 10)
                .padding(40)
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LinearGradient.accentGradient)
                }
                
                VStack(spacing: 8) {
                    Text(localized("drop_files_here"))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Release to start transcription")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    var settingsButton: some View {
        SettingsLink {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundStyle(LinearGradient.accentGradient)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    func handleSearch() {
        // Implement search functionality
    }
    
    func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, error in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            // Check if it's a supported audio/video file
            let supportedExtensions = ["mp3", "wav", "m4a", "m4b", "mp4", "ogg", "aac", "mov", "flac", "opus", "webm"]
            if supportedExtensions.contains(url.pathExtension.lowercased()) {
                DispatchQueue.main.async {
                    self.isDraggingFile = false
                    self.appState.openFileForTranscription(url)
                }
            }
        }
        return true
    }
    
    func openFiles() {
        showFileImporter = true
    }
    
    func newRecording() {
        appState.showRecordingView = true
    }
    
    func batchTranscription() {
        // TODO: Implement batch transcription
        print("Batch transcription not yet implemented")
    }
    
    func showSupport() {
        // Show support
        if let url = URL(string: "https://transcribe.app/support") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Dropdown Views
    
    var languageDropdown: some View {
        Button(action: {
            showLanguagePopover.toggle()
        }) {
            HStack(spacing: 6) {
                if languageManager.selectedLanguage.code == "auto" {
                    Image(systemName: "globe")
                        .font(.system(size: 18))
                        .foregroundStyle(LinearGradient.accentGradient)
                } else {
                    Text(getLanguageFlag(languageManager.selectedLanguage.code))
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized("language"))
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    Text(languageManager.selectedLanguage.localizedName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.black)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showLanguagePopover) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(TranscriptionLanguage.commonLanguages) { language in
                    Button(action: {
                        languageManager.selectLanguage(language)
                        showLanguagePopover = false
                    }) {
                        HStack {
                            if language.code == "auto" {
                                Image(systemName: "globe")
                                    .font(.system(size: 16))
                                    .foregroundStyle(LinearGradient.accentGradient)
                                    .frame(width: 20)
                            } else {
                                Text(getLanguageFlag(language.code))
                                    .font(.system(size: 16))
                            }
                            Text(language.localizedName)
                                .foregroundColor(.primary)
                            Spacer()
                            if languageManager.selectedLanguage.id == language.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                Text(localized("more_languages"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                
                ForEach(TranscriptionLanguage.allLanguages.filter { lang in
                    !TranscriptionLanguage.commonLanguages.contains(where: { $0.id == lang.id })
                }) { language in
                    Button(action: {
                        languageManager.selectLanguage(language)
                        showLanguagePopover = false
                    }) {
                        HStack {
                            Text(getLanguageFlag(language.code))
                                .font(.system(size: 16))
                            Text(language.localizedName)
                                .foregroundColor(.primary)
                            Spacer()
                            if languageManager.selectedLanguage.id == language.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(width: 200)
        }
    }
    
    var modelDropdown: some View {
        Button(action: {
            showModelPopover.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: getModelIcon(selectedModel))
                    .font(.system(size: 18))
                    .foregroundStyle(LinearGradient.accentGradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized("model"))
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    Text(selectedModel.isEmpty ? localized("select_model") : getModelDisplayName(selectedModel))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedModel.isEmpty ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color.black)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showModelPopover) {
            VStack(alignment: .leading, spacing: 0) {
                // Local models section
                if !modelManager.downloadedModels.isEmpty {
                    Text(localized("local_models"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                    // KB Whisper CoreML models
                    let kbModels = modelManager.downloadedModels.filter { 
                        $0.starts(with: "kb_whisper-")
                    }.sorted()
                    if !kbModels.isEmpty {
                        ForEach(kbModels, id: \.self) { modelId in
                            Button(action: {
                                selectedModel = modelId
                                showModelPopover = false
                            }) {
                                HStack {
                                    Image(systemName: "laptopcomputer")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(getModelDisplayName(modelId))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedModel == modelId {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onHover { isHovered in
                                if isHovered {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                    
                    // OpenAI Whisper models
                    let whisperModels = modelManager.downloadedModels.filter { $0.starts(with: "openai_whisper-") }.sorted()
                    if !whisperModels.isEmpty {
                        if !kbModels.isEmpty {
                            Divider().padding(.horizontal, 12)
                        }
                        
                        ForEach(whisperModels, id: \.self) { modelId in
                            Button(action: {
                                selectedModel = modelId
                                showModelPopover = false
                            }) {
                                HStack {
                                    Image(systemName: "laptopcomputer")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(getModelDisplayName(modelId))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedModel == modelId {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onHover { isHovered in
                                if isHovered {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                }
                
                // Cloud models section
                if bergetTranscriptionEnabled {
                    Text(localized("cloud_models"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                    
                    if bergetTranscriptionEnabled && !settingsManager.bergetKey.isEmpty {
                        Button(action: {
                            selectedModel = "berget-kb-whisper-large"
                            showModelPopover = false
                        }) {
                            HStack {
                                Image(systemName: "cloud")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("KB Whisper Large (Berget)")
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedModel == "berget-kb-whisper-large" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { isHovered in
                            if isHovered {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(width: 220)
        }
    }
    
    func getModelDisplayName(_ modelId: String) -> String {
        switch modelId {
        case "kb_whisper-base-coreml": return "KB Whisper Base"
        case "kb_whisper-small-coreml": return "KB Whisper Small"
        case "kb_whisper-medium-coreml": return "KB Whisper Medium"
        case "kb_whisper-large-coreml": return "KB Whisper Large"
        case "openai_whisper-base": return "Whisper Base"
        case "openai_whisper-small": return "Whisper Small"
        case "openai_whisper-medium": return "Whisper Medium"
        case "openai_whisper-large-v2": return "Whisper Large v2"
        case "openai_whisper-large-v3": return "Whisper Large v3"
        case "berget-kb-whisper-large": return "KB Whisper Large (Berget)"
        default: return modelId // Return the modelId itself as fallback
        }
    }
    
    func getLanguageFlag(_ code: String) -> String {
        switch code {
        case "auto": return "🌐"
        case "sv": return "🇸🇪"
        case "en": return "🇬🇧"
        case "ar": return "🇸🇦"
        case "zh": return "🇨🇳"
        case "da": return "🇩🇰"
        case "nl": return "🇳🇱"
        case "fi": return "🇫🇮"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "hi": return "🇮🇳"
        case "it": return "🇮🇹"
        case "ja": return "🇯🇵"
        case "ko": return "🇰🇷"
        case "no": return "🇳🇴"
        case "pl": return "🇵🇱"
        case "pt": return "🇵🇹"
        case "ru": return "🇷🇺"
        case "es": return "🇪🇸"
        case "tr": return "🇹🇷"
        case "uk": return "🇺🇦"
        default: return "🏳️"
        }
    }
    
    func getModelIcon(_ modelId: String) -> String {
        if modelId.starts(with: "kb_whisper-") || modelId.starts(with: "openai_whisper-") {
            return "laptopcomputer"
        } else if modelId == "berget-kb-whisper-large" {
            return "cloud"
        } else if modelId.starts(with: "cloud-") {
            return "cloud.fill"
        } else {
            return "cube"
        }
    }
}

struct HistoryItemRow: View {
    let item: SearchHistoryItem
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 36, height: 36)
                
                Text(String(item.query.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryAccent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.query)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(item.date, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    var gradient: LinearGradient = LinearGradient.accentGradient
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundColor(.primaryAccent)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 160, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: isHovered ? Color.primaryAccent.opacity(0.2) : .shadowColor, 
                           radius: isHovered ? 20 : 10, 
                           y: isHovered ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primaryAccent.opacity(isHovered ? 0.3 : 0), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

struct SecondaryFeatureCard: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 80, height: 80)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.textSecondary, Color.textTertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 160, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.6))
                    .shadow(color: isHovered ? Color.shadowColor.opacity(0.15) : .shadowColor, 
                           radius: isHovered ? 20 : 10, 
                           y: isHovered ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.borderLight.opacity(isHovered ? 1 : 0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}
