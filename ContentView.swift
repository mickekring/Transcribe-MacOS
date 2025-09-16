import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedHistoryItem: SearchHistoryItem?
    @State private var isDraggingFile = false
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainContent
        }
        .navigationTitle("Transcribe")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                settingsButton
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDraggingFile) { providers in
            handleFileDrop(providers)
        }
    }
    
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchBar
                .padding()
            
            Divider()
            
            historyList
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
    }
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search History", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    var historyList: some View {
        List(selection: $selectedHistoryItem) {
            Section("Older") {
                ForEach(appState.searchHistory) { item in
                    HistoryItemRow(item: item)
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    var mainContent: some View {
        ZStack {
            if isDraggingFile {
                dragOverlay
            } else {
                featureGrid
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDraggingFile)
    }
    
    var featureGrid: some View {
        VStack(spacing: 20) {
            searchInput
            
            primaryFeatures
            
            secondaryFeatures
            
            Spacer()
            
            supportedFormats
        }
        .padding()
    }
    
    var searchInput: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Enter YouTube, Audio or Video File URL...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.title3)
                .onSubmit {
                    handleSearch()
                }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    var primaryFeatures: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
            FeatureCard(
                icon: "doc.badge.arrow.up",
                title: "Open Files...",
                action: openFiles
            )
            
            FeatureCard(
                icon: "mic",
                title: "New Recording",
                action: newRecording
            )
            
            FeatureCard(
                icon: "person.2",
                title: "Record Meeting",
                isBeta: true,
                action: recordMeeting
            )
            
            FeatureCard(
                icon: "play.rectangle",
                title: "Batch Transcription",
                action: batchTranscription
            )
            
            FeatureCard(
                icon: "macwindow",
                title: "Record App Audio",
                action: recordAppAudio
            )
            
            FeatureCard(
                icon: "text.bubble",
                title: "Dictation",
                isBeta: true,
                action: dictation
            )
            
            FeatureCard(
                icon: "person.2",
                title: "Transcribe Podcast",
                isBeta: true,
                action: transcribePodcast
            )
            
            FeatureCard(
                icon: "globe",
                title: "Global",
                action: globalFeature
            )
            
            FeatureCard(
                icon: "cloud",
                title: "Cloud Transcription",
                action: cloudTranscription
            )
        }
    }
    
    var secondaryFeatures: some View {
        HStack(spacing: 20) {
            SecondaryFeatureCard(
                icon: "plus.circle",
                title: "Manage\nModels",
                action: manageModels
            )
            
            SecondaryFeatureCard(
                icon: "questionmark.circle",
                title: "Support",
                action: showSupport
            )
            
            SecondaryFeatureCard(
                icon: "iphone",
                title: "Download\niOS app",
                action: downloadiOSApp
            )
        }
    }
    
    var supportedFormats: some View {
        VStack {
            Text("Or Drag & Drop Media Files to Transcribe.")
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                ForEach(["MP3", "WAV", "M4A", "M4B", "MP4", "OGG", "AAC", "MOV"], id: \.self) { format in
                    Text(format)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }
    
    var dragOverlay: some View {
        VStack {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            Text("Drop files here to transcribe")
                .font(.title2)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.accentColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 2)
                .padding()
        )
    }
    
    var settingsButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape")
        }
    }
    
    // MARK: - Actions
    
    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    func handleSearch() {
        // Implement search functionality
    }
    
    func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        // Handle file drop
        return true
    }
    
    func openFiles() {
        appState.selectedFeature = .openFiles
    }
    
    func newRecording() {
        appState.selectedFeature = .newRecording
    }
    
    func recordMeeting() {
        appState.selectedFeature = .recordMeeting
    }
    
    func batchTranscription() {
        appState.selectedFeature = .batchTranscription
    }
    
    func recordAppAudio() {
        appState.selectedFeature = .recordAppAudio
    }
    
    func dictation() {
        appState.selectedFeature = .dictation
    }
    
    func transcribePodcast() {
        appState.selectedFeature = .transcribePodcast
    }
    
    func globalFeature() {
        appState.selectedFeature = .global
    }
    
    func cloudTranscription() {
        appState.selectedFeature = .cloudTranscription
    }
    
    func manageModels() {
        // Open model management
    }
    
    func showSupport() {
        // Show support
    }
    
    func downloadiOSApp() {
        // Open App Store link
    }
    
    func openSettings() {
        // Open settings
    }
}

struct HistoryItemRow: View {
    let item: SearchHistoryItem
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(item.query.prefix(1)).uppercased())
                        .font(.caption)
                        .bold()
                )
            
            VStack(alignment: .leading) {
                Text(item.query)
                    .lineLimit(1)
                Text(item.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    var isBeta: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if isBeta {
                    HStack {
                        Spacer()
                        Text("BETA")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(4)
                    }
                } else {
                    Spacer()
                        .frame(height: 20)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(isHovered ? 0.15 : 0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
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
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(isHovered ? 0.15 : 0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}