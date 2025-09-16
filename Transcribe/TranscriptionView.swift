import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// Custom button style with press animation
struct TranscriptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TranscriptionView: View {
    @StateObject private var viewModel: TranscriptionViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingExportPopover = false
    @State private var displayMode: DisplayMode = .transcript
    @State private var fontSize: Double = 16
    @State private var showTimestamps = false
    
    enum DisplayMode {
        case transcript
        case segments
    }
    
    init(fileURL: URL) {
        _viewModel = StateObject(wrappedValue: TranscriptionViewModel(fileURL: fileURL))
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 40) {
                // Left side - Transcription (66%)
                transcriptionSection
                    .frame(width: geometry.size.width * 0.66)
                
                // Right side - Controls and Audio Player (30%)
                rightSidePanel
                    .frame(width: geometry.size.width * 0.30)
            }
        }
        .background(Color.white)
        .navigationTitle(viewModel.fileName)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    appState.showTranscriptionView = false
                    appState.currentTranscriptionURL = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                        Text("Back")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.primaryAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            viewModel.startTranscription()
        }
    }
    
    private var transcriptionHeader: some View {
        HStack {
            Text(localized("transcription"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            if viewModel.isTranscribing {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.primaryAccent))
            }
            
            transcriptionStats
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.borderLight)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var transcriptionStats: some View {
        HStack(spacing: 16) {
            if viewModel.duration > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(localized("duration"))
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                    Text(formatTime(viewModel.duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            
            if viewModel.isTranscribing || viewModel.transcriptionTime > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(localized("transcription_time"))
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                    Text(formatTime(viewModel.transcriptionTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(localized("words"))
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)
                Text("\(viewModel.wordCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    private var streamingIndicator: some View {
        HStack {
            HStack(spacing: 10) {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.primaryAccent))
                Text(localized("transcribing"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderLight, lineWidth: 1)
            )
            
            Spacer()
        }
        .padding(.leading, 16)
        .padding(.bottom, 16)
    }
    
    private var transcriptionContent: some View {
        Group {
            if !viewModel.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    TextEditor(text: .constant(displayMode == .segments ? formatAsSegments(viewModel.transcribedText) : viewModel.transcribedText))
                        .font(.system(size: fontSize))
                        .scrollContentBackground(.hidden)
                        .padding()
                        .onChange(of: viewModel.transcribedText) { _ in
                            // Auto-scroll to bottom when new text is added during streaming
                            if viewModel.isTranscribing {
                                // Scroll logic here
                            }
                        }
                    
                    if viewModel.isTranscribing {
                        streamingIndicator
                    }
                }
            } else {
                transcriptionProgressView
            }
        }
    }
    
    var transcriptionSection: some View {
        VStack(spacing: 0) {
            transcriptionHeader
            
            ScrollView {
                transcriptionContent
            }
            .background(Color.white)
        }
    }
    
    private var transcriptionProgressView: some View {
        VStack {
            Spacer()
            
            // Progress card with rounded corners and shadow
            VStack(spacing: 24) {
                if viewModel.isPreprocessing {
                    // Show spinner for preprocessing
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.primaryAccent))
                } else if viewModel.isProcessingChunks {
                    // Show progress bar for chunk transcription (stay visible between chunks)
                    VStack(spacing: 16) {
                        Text(String(format: localized("chunk_of"), viewModel.currentChunk, viewModel.totalChunks))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        ProgressView(value: viewModel.chunkProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(Color.primaryAccent)
                            .frame(width: 260)
                            .scaleEffect(y: 2)
                    }
                } else if viewModel.showSingleFileProgress {
                    // Show progress bar for single file transcription
                    VStack(spacing: 16) {
                        Text(viewModel.statusMessage.isEmpty ? localized("transcribing") : viewModel.statusMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        ProgressView(value: viewModel.singleFileProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(Color.primaryAccent)
                            .frame(width: 260)
                            .scaleEffect(y: 2)
                    }
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.primaryAccent))
                }
                
                Text(viewModel.statusMessage.isEmpty ? localized("preparing_audio_file") : viewModel.statusMessage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderLight, lineWidth: 1)
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cardBackground.opacity(0.5))
    }
    
    var rightSidePanel: some View {
        VStack(spacing: 0) {
            
            // Main content area
            VStack(alignment: .leading, spacing: 30) {
                // Display Mode Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized("display_mode"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 8) {
                        Button(action: { displayMode = .transcript }) {
                            VStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20))
                                Text(localized("transcript"))
                                    .font(.system(size: 11))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .padding(.vertical, 12)
                            .foregroundColor(displayMode == .transcript ? .white : .primaryAccent)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(displayMode == .transcript ? LinearGradient.accentGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(LinearGradient.accentGradient, lineWidth: displayMode == .transcript ? 0 : 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(TranscriptionButtonStyle())
                        
                        Button(action: { displayMode = .segments }) {
                            VStack(spacing: 6) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 20))
                                Text(localized("segments"))
                                    .font(.system(size: 11))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .padding(.vertical, 12)
                            .foregroundColor(displayMode == .segments ? .white : .primaryAccent)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(displayMode == .segments ? LinearGradient.accentGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(LinearGradient.accentGradient, lineWidth: displayMode == .segments ? 0 : 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(TranscriptionButtonStyle())
                    }
                    .padding(.horizontal, 20)
                }
                
                // Save/Copy Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized("save_copy"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 20)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                    // Export button with custom dropdown
                    Button(action: { showingExportPopover.toggle() }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                            Text(localized("save_as"))
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.primaryAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LinearGradient.accentGradient, lineWidth: 1.5)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(TranscriptionButtonStyle())
                    .popover(isPresented: $showingExportPopover) {
                        VStack(alignment: .leading, spacing: 0) {
                            Button(action: {
                                viewModel.exportAsText()
                                showingExportPopover = false
                            }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 14))
                                        .frame(width: 20)
                                    Text("Text (.txt)")
                                        .font(.system(size: 13))
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(Color.clear)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        .frame(width: 140)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    
                    // Copy button
                    Button(action: { viewModel.copyToClipboard() }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16))
                            Text(localized("copy_text"))
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                        }
                        .foregroundColor(.primaryAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LinearGradient.accentGradient, lineWidth: 1.5)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(TranscriptionButtonStyle())
                    }
                    .padding(.horizontal, 20)
                }
                
                // Options Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized("options"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Font Size Slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localized("font_size"))
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            
                            HStack(spacing: 12) {
                                Text("A")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textTertiary)
                                
                                ZStack {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    Slider(value: $fontSize, in: 14...24, step: 2)
                                        .tint(.primaryAccent)
                                }
                                
                                Text("A")
                                    .font(.system(size: 24))
                                    .foregroundColor(.textTertiary)
                            }
                        }
                        
                        // Show Timestamps Toggle
                        HStack {
                            Text(localized("show_timestamps"))
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $showTimestamps)
                                .toggleStyle(SwitchToggleStyle(tint: .primaryAccent))
                                .labelsHidden()
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 30)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.white)
            
            // Audio player at bottom
            audioPlayerSection
        }
        .background(Color.white)
    }
    
    var audioPlayerSection: some View {
        VStack(spacing: 0) {
            // Audio player content
            VStack(spacing: 20) {
                // Player controls
                VStack(spacing: 16) {
                    // Time slider
                    VStack(spacing: 4) {
                        Slider(value: $viewModel.currentTime, in: 0...viewModel.duration) { editing in
                            if !editing {
                                viewModel.seek(to: viewModel.currentTime)
                            }
                        }
                        .tint(.primaryAccent)
                        
                        HStack {
                            Text(formatTime(viewModel.currentTime))
                                .font(.system(size: 11))
                                .foregroundColor(.textTertiary)
                            Spacer()
                            Text(formatTime(viewModel.duration))
                                .font(.system(size: 11))
                                .foregroundColor(.textTertiary)
                        }
                    }
                    
                    // Playback controls
                    HStack(spacing: 20) {
                        Button(action: { viewModel.skipBackward() }) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 20))
                                .foregroundStyle(LinearGradient.accentGradient)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { viewModel.togglePlayPause() }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(LinearGradient.accentGradient)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { viewModel.skipForward() }) {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 20))
                                .foregroundStyle(LinearGradient.accentGradient)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Speed control
                    VStack(spacing: 4) {
                        Text(localized("speed"))
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                                Button(action: { viewModel.playbackSpeed = speed }) {
                                    Text("\(speed, specifier: "%.2g")x")
                                        .font(.system(size: 12, weight: viewModel.playbackSpeed == speed ? .semibold : .regular))
                                        .foregroundColor(viewModel.playbackSpeed == speed ? .primaryAccent : .textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // File info at bottom
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Fil")
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                        Text(viewModel.fileName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(localized("duration"))
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                        Text(formatTime(viewModel.duration))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    
                    VStack(alignment: .trailing) {
                        Text(localized("format"))
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                        Text(viewModel.fileFormat)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.top, 12)
            }
            .padding()
            .background(Color.white)
        }
        .background(Color.white)
    }
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatAsSegments(_ text: String) -> String {
        // Split text into sentences and add line breaks
        let sentences = text.replacingOccurrences(of: ". ", with: ".\n\n")
                           .replacingOccurrences(of: "! ", with: "!\n\n")
                           .replacingOccurrences(of: "? ", with: "?\n\n")
        return sentences
    }
}

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var transcribedText = ""
    @Published var isTranscribing = false
    @Published var progress: Double = 0
    @Published var wordCount = 0
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackSpeed: Double = 1.0 {
        didSet {
            audioPlayer?.rate = Float(playbackSpeed)
        }
    }
    @Published var segments: [TranscriptionSegmentData] = []
    @Published var elapsedTime: Double = 0
    @Published var estimatedTimeRemaining: Double = 0
    @Published var errorMessage: String?
    @Published var transcriptionTime: Double = 0
    @Published var statusMessage: String = ""
    @Published var currentChunk = 0
    @Published var totalChunks = 0
    @Published var chunkProgress: Double = 0
    @Published var isPreprocessing = false
    @Published var showSingleFileProgress = false
    @Published var singleFileProgress: Double = 0
    @Published var isProcessingChunks = false
    
    let fileURL: URL
    var fileName: String {
        fileURL.lastPathComponent
    }
    
    var fileFormat: String {
        fileURL.pathExtension.uppercased()
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var transcriptionService: TranscriptionService?  // For WhisperKit streaming
    private let unifiedTranscriptionService = UnifiedTranscriptionService()  // For KB models
    private var bergetService: BergetTranscriptionService?
    private var transcriptionStartTime: Date?
    private var transcriptionTimer: Timer?
    
    // Get selected model and language from UserDefaults
    @AppStorage("selectedTranscriptionModel") private var selectedModel: String = "kb-whisper-small"
    @AppStorage("bergetAPIKey") private var bergetKey: String = ""
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        setupAudioPlayer()
    }
    
    func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true // Enable rate adjustment
            audioPlayer?.rate = Float(playbackSpeed)
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    func startTranscription() {
        isTranscribing = true
        transcriptionStartTime = Date()
        
        // Start timer to update transcription time
        transcriptionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = self.transcriptionStartTime {
                self.transcriptionTime = Date().timeIntervalSince(startTime)
            }
        }
        
        // Get selected language
        let selectedLanguage = LanguageManager.shared.selectedLanguage.code == "auto" ? nil : LanguageManager.shared.selectedLanguage.code
        
        // Determine which service to use based on selected model
        if selectedModel == "berget-kb-whisper-large" {
            // Use Berget service
            startBergetTranscription(language: selectedLanguage)
        } else {
            // Use local WhisperKit service
            startLocalTranscription()
        }
    }
    
    private func startLocalTranscription() {
        statusMessage = localized("processing_local_model")
        
        // All local models now use WhisperKit (streaming)
        // This includes OpenAI models and KB CoreML models
        startWhisperKitTranscription()
    }
    
    private func startWhisperKitTranscription() {
        // Original streaming WhisperKit implementation
        transcriptionService = TranscriptionService()
        
        Task {
            do {
                // Stream transcription updates
                for try await update in transcriptionService!.transcribe(fileURL: fileURL) {
                    await MainActor.run {
                        self.transcribedText = update.text
                        self.progress = update.progress
                        self.segments = update.segments
                        self.wordCount = update.text.split(separator: " ").count
                        
                        if !update.text.isEmpty {
                            self.statusMessage = ""
                        }
                        
                        if update.isComplete {
                            self.finishTranscription()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleTranscriptionError(error)
                }
            }
        }
    }
    
    private func startBergetTranscription(language: String?) {
        guard !bergetKey.isEmpty else {
            handleTranscriptionError(CloudTranscriptionError.apiError("Berget API key not configured"))
            return
        }
        
        statusMessage = localized("preparing_audio_file")
        bergetService = BergetTranscriptionService(apiKey: bergetKey)
        
        Task {
            do {
                // Preprocess audio
                await MainActor.run {
                    self.isPreprocessing = true
                }
                
                let processedAudio = try await AudioPreprocessor.shared.preprocessAudio(
                    url: fileURL,
                    onProgress: { message in
                        DispatchQueue.main.async {
                            self.statusMessage = message
                        }
                    }
                )
                
                await MainActor.run {
                    self.isPreprocessing = false
                    self.totalChunks = processedAudio.chunks.count
                }
                
                if processedAudio.chunks.count > 1 {
                    // Handle chunked transcription
                    await transcribeChunksWithBerget(processedAudio: processedAudio, language: language)
                } else {
                    // Single file transcription
                    await transcribeSingleFileWithBerget(url: processedAudio.chunks[0].url, language: language)
                }
                
                // Cleanup temporary files
                AudioPreprocessor.shared.cleanupProcessedAudio(processedAudio)
            } catch {
                await MainActor.run {
                    self.handleTranscriptionError(error)
                }
            }
        }
    }
    
    private func transcribeSingleFileWithBerget(url: URL, language: String?) async {
        await MainActor.run {
            self.statusMessage = localized("sending_audio_berget")
            self.showSingleFileProgress = true
            self.singleFileProgress = 0
        }
        
        // Get duration for progress estimation
        let asset = AVAsset(url: url)
        let duration = try? await asset.load(.duration)
        let durationInSeconds = duration != nil ? CMTimeGetSeconds(duration!) : 60.0
        let expectedTime = max(durationInSeconds / 9.0, 2.0) // 9x realtime with minimum 2 seconds
        
        // Start progress timer
        var progressTimer: Timer?
        await MainActor.run {
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.singleFileProgress = min(self.singleFileProgress + (0.1 / expectedTime), 0.95)
            }
        }
        
        bergetService?.transcribe(
            audioURL: url,
            language: language,
            onProgress: { text in
                DispatchQueue.main.async {
                    self.transcribedText = text
                    self.wordCount = text.split(separator: " ").count
                    self.statusMessage = localized("transcribing")
                    self.singleFileProgress = min(self.singleFileProgress, 0.8) // Update progress if we get intermediate results
                }
            },
            completion: { result in
                progressTimer?.invalidate()
                DispatchQueue.main.async {
                    self.singleFileProgress = 1.0
                    self.showSingleFileProgress = false
                    
                    switch result {
                    case .success(let transcriptionResult):
                        self.transcribedText = transcriptionResult.text
                        self.segments = transcriptionResult.segments.map { segment in
                            TranscriptionSegmentData(
                                start: segment.start,
                                end: segment.end,
                                text: segment.text,
                                words: nil
                            )
                        }
                        self.wordCount = transcriptionResult.text.split(separator: " ").count
                        self.finishTranscription()
                    case .failure(let error):
                        self.handleTranscriptionError(error)
                    }
                }
            }
        )
    }
    
    @MainActor
    private func transcribeChunksWithBerget(processedAudio: AudioPreprocessor.ProcessedAudio, language: String?) async {
        var transcriptionResults: [(chunk: AudioPreprocessor.AudioChunk, result: TranscriptionResult)] = []
        
        // Set flag to indicate we're processing chunks
        self.isProcessingChunks = true
        
        for (index, chunk) in processedAudio.chunks.enumerated() {
            self.currentChunk = index + 1
            self.statusMessage = String(format: localized("transcribing_chunk"), index + 1, processedAudio.chunks.count)
            self.chunkProgress = 0
            
            // Start a timer to simulate progress (9x realtime)
            let chunkDuration = chunk.endTime - chunk.startTime
            let expectedTime = chunkDuration / 9.0
            var progressTimer: Timer?
            
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.chunkProgress = min(self.chunkProgress + (0.1 / expectedTime), 0.95)
            }
            
            await withCheckedContinuation { continuation in
                bergetService?.transcribe(
                    audioURL: chunk.url,
                    language: language,
                    onProgress: { text in
                        DispatchQueue.main.async {
                            // Update chunk progress
                            self.chunkProgress = 0.5
                        }
                    },
                    completion: { result in
                        progressTimer?.invalidate()
                        
                        DispatchQueue.main.async {
                            self.chunkProgress = 1.0
                            
                            switch result {
                            case .success(let transcriptionResult):
                                transcriptionResults.append((chunk: chunk, result: transcriptionResult))
                                // Don't show text until all chunks are done
                                
                            case .failure(let error):
                                print("Chunk \(index) failed: \(error)")
                            }
                            
                            continuation.resume()
                        }
                    }
                )
            }
        }
        
        // Merge results
        if !transcriptionResults.isEmpty {
            await MainActor.run {
                self.statusMessage = localized("merging_results")
                
                let mergedResult = AudioPreprocessor.shared.mergeChunkedTranscriptions(transcriptionResults)
                
                if mergedResult.text.isEmpty && transcriptionResults.count > 0 {
                    // Fallback: just concatenate all texts if merge failed
                    self.transcribedText = transcriptionResults.map { $0.result.text }.joined(separator: " ")
                    self.segments = []
                } else {
                    self.transcribedText = mergedResult.text
                    self.segments = mergedResult.segments.map { segment in
                        TranscriptionSegmentData(
                            start: segment.start,
                            end: segment.end,
                            text: segment.text,
                            words: nil
                        )
                    }
                }
                
                self.wordCount = self.transcribedText.split(separator: " ").count
                self.isProcessingChunks = false
                self.finishTranscription()
            }
        } else {
            await MainActor.run {
                self.isProcessingChunks = false
                self.handleTranscriptionError(CloudTranscriptionError.apiError("No transcription results received"))
            }
        }
    }
    
    private func finishTranscription() {
        self.isTranscribing = false
        self.estimatedTimeRemaining = 0
        self.transcriptionTimer?.invalidate()
        self.transcriptionTimer = nil
        // Keep the final transcription time displayed
        if let startTime = self.transcriptionStartTime {
            self.transcriptionTime = Date().timeIntervalSince(startTime)
        }
        // Reset chunk tracking
        self.currentChunk = 0
        self.totalChunks = 0
        self.chunkProgress = 0
        self.isPreprocessing = false
        self.showSingleFileProgress = false
        self.singleFileProgress = 0
        self.isProcessingChunks = false
        self.statusMessage = ""
    }
    
    private func handleTranscriptionError(_ error: Error) {
        self.isTranscribing = false
        self.errorMessage = error.localizedDescription
        print("Transcription error: \(error)")
        
        // Stop timer on error
        self.transcriptionTimer?.invalidate()
        self.transcriptionTimer = nil
        
        // Reset all progress tracking
        self.currentChunk = 0
        self.totalChunks = 0
        self.chunkProgress = 0
        self.isPreprocessing = false
        self.isProcessingChunks = false
        self.showSingleFileProgress = false
        self.singleFileProgress = 0
        
        // Show error in UI
        let modelName = getModelDisplayName(selectedModel)
        self.transcribedText = """
        ⚠️ Transcription Error
        
        Model: \(modelName)
        Error: \(error.localizedDescription)
        
        Please check:
        1. API key is configured (for cloud models)
        2. Model is downloaded (for local models)
        3. Audio file is valid
        4. Internet connection (for cloud models)
        """
    }
    
    private func getModelDisplayName(_ modelId: String) -> String {
        switch modelId {
        case "berget-kb-whisper-large": return "KB Whisper Large (Berget)"
        default: return modelId
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
            timer?.invalidate()
        } else {
            audioPlayer?.rate = Float(playbackSpeed) // Apply current speed
            audioPlayer?.play()
            startTimer()
        }
        isPlaying.toggle()
    }
    
    func skipForward() {
        let newTime = min(currentTime + 10, duration)
        seek(to: newTime)
    }
    
    func skipBackward() {
        let newTime = max(currentTime - 10, 0)
        seek(to: newTime)
    }
    
    func seek(to time: Double) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.currentTime = self.audioPlayer?.currentTime ?? 0
        }
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcribedText, forType: .string)
    }
    
    func exportAsText() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Transcription"
        savePanel.message = "Choose where to save the transcription"
        savePanel.nameFieldStringValue = "\(fileName.replacingOccurrences(of: ".\(fileURL.pathExtension)", with: ""))_transcription.txt"
        savePanel.allowedContentTypes = [.plainText]
        savePanel.allowsOtherFileTypes = false
        savePanel.isExtensionHidden = false
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try self.transcribedText.write(to: url, atomically: true, encoding: .utf8)
                    print("✅ Transcription saved to: \(url.path)")
                } catch {
                    print("❌ Failed to save transcription: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct TranscriptionSegmentData {
    let start: Double
    let end: Double
    let text: String
    let words: [WordTimestamp]?
}

struct WordTimestamp {
    let word: String
    let start: Double
    let end: Double
    let confidence: Float
}