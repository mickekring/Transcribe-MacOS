import SwiftUI
import AVFoundation
import AppKit

struct RecordingView: View {
    @StateObject private var audioRecorder = AudioRecorderManager()
    @EnvironmentObject var appState: AppState
    @State private var showingTranscription = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isPlaying = false
    @State private var playbackTime: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    appState.showRecordingView = false
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                        Text("Tillbaka")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.primaryAccent)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Ny inspelning")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Placeholder for balance
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Tillbaka")
                }
                .opacity(0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color.borderLight)
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Main content
            VStack(spacing: 40) {
                Spacer()
                
                // Recording visualization
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.borderLight, lineWidth: 2)
                        .frame(width: 200, height: 200)
                    
                    // Pulsing animation when recording
                    if audioRecorder.isRecording {
                        Circle()
                            .fill(Color.primaryAccent.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .scaleEffect(audioRecorder.isRecording ? 1.1 : 1.0)
                            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: audioRecorder.isRecording)
                    }
                    
                    // Center button
                    Button(action: {
                        if audioRecorder.isRecording {
                            stopRecording()
                        } else if audioRecorder.hasRecording {
                            // Show options
                        } else {
                            startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(audioRecorder.isRecording ? Color.red : Color.primaryAccent)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(audioRecorder.isRecording ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: audioRecorder.isRecording)
                }
                
                // Time display
                VStack(spacing: 8) {
                    if audioRecorder.isRecording || audioRecorder.hasRecording {
                        Text(formatTime(audioRecorder.isRecording ? recordingTime : audioRecorder.recordingDuration))
                            .font(.system(size: 32, weight: .medium, design: .monospaced))
                            .foregroundColor(.textPrimary)
                        
                        Text(audioRecorder.isRecording ? "Spelar in..." : "Inspelning klar")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("Tryck för att börja spela in")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Controls when recording is done
                if audioRecorder.hasRecording && !audioRecorder.isRecording {
                    HStack(spacing: 24) {
                        // Play/Pause button
                        Button(action: togglePlayback) {
                            HStack(spacing: 8) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                Text(isPlaying ? "Pausa" : "Spela upp")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.borderLight, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Start over button
                        Button(action: {
                            audioRecorder.deleteRecording()
                            recordingTime = 0
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Börja om")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.borderLight, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Transcribe button
                    Button(action: {
                        if let recordingURL = audioRecorder.recordingURL {
                            appState.showRecordingView = false
                            appState.currentTranscriptionURL = recordingURL
                            appState.showTranscriptionView = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                            Text("Transkribera")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.primaryAccent, Color.secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .onDisappear {
            timer?.invalidate()
            audioPlayer?.stop()
        }
        .alert("Mikrofontillstånd krävs", isPresented: $showPermissionAlert) {
            Button("OK") { }
        } message: {
            Text("För att spela in ljud behöver Transcribe tillgång till din mikrofon. Gå till Systeminställningar > Säkerhet & Integritet > Mikrofon och aktivera Transcribe.")
        }
    }
    
    private func startRecording() {
        // Check permission first
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            audioRecorder.startRecording()
            recordingTime = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingTime += 0.1
            }
        case .denied, .restricted:
            showPermissionAlert = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.audioRecorder.startRecording()
                        self.recordingTime = 0
                        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                            self.recordingTime += 0.1
                        }
                    } else {
                        self.showPermissionAlert = true
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    private func stopRecording() {
        audioRecorder.stopRecording()
        timer?.invalidate()
        timer = nil
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            guard let url = audioRecorder.recordingURL else { 
                print("No recording URL available")
                return 
            }
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: url.path) {
                print("Recording file doesn't exist at: \(url.path)")
                return
            }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                
                if audioPlayer?.play() == true {
                    isPlaying = true
                    print("Playing recording from: \(url)")
                    
                    // Stop playback when finished
                    DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                        self.isPlaying = false
                    }
                } else {
                    print("Failed to start playback")
                }
            } catch {
                print("Failed to create audio player: \(error)")
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// Audio Recorder Manager
class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingURL: URL?
    
    private var audioRecorder: AVAudioRecorder?
    
    override init() {
        super.init()
        checkMicrophonePermission()
    }
    
    private func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if !granted {
                    print("Microphone permission denied")
                }
            }
        case .denied, .restricted:
            print("Microphone permission denied or restricted")
        @unknown default:
            break
        }
    }
    
    func startRecording() {
        let audioFilename = getTemporaryDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // Debug logging
        print("\n🎤 ========== RECORDING STORAGE DEBUG ==========")
        print("📁 Storage Type: TEMPORARY (auto-cleanup on app quit)")
        print("📍 Full Path: \(audioFilename.path)")
        print("📂 Directory: \(audioFilename.deletingLastPathComponent().path)")
        print("🗑️ Auto-cleanup: YES - File will be deleted when app quits")
        print("⏰ Started at: \(Date())")
        print("===============================================\n")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            if audioRecorder?.record() == true {
                recordingURL = audioFilename
                isRecording = true
                hasRecording = false
                print("✅ Recording started successfully")
            } else {
                print("❌ Failed to start recording")
            }
        } catch {
            print("Failed to create audio recorder: \(error)")
        }
    }
    
    func stopRecording() {
        guard let recorder = audioRecorder else {
            print("No audio recorder available")
            return
        }
        
        recordingDuration = recorder.currentTime
        recorder.stop()
        isRecording = false
        
        // Verify the file was created
        if let url = recordingURL, FileManager.default.fileExists(atPath: url.path) {
            hasRecording = true
            
            // Get file size for debugging
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? Int64 {
                let sizeMB = Double(fileSize) / (1024 * 1024)
                print("\n✅ ========== RECORDING SAVED ==========")
                print("📍 Location: \(url.path)")
                print("📊 File size: \(String(format: "%.2f MB", sizeMB)) (\(fileSize) bytes)")
                print("⏱️ Duration: \(String(format: "%.1f seconds", recordingDuration))")
                print("🗑️ Will auto-delete: YES (on app quit)")
                print("=======================================\n")
            }
        } else {
            hasRecording = false
            print("Recording file not found after stopping")
        }
    }
    
    func deleteRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        hasRecording = false
        recordingDuration = 0
    }
    
    private func getTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Transcribe")
            .appendingPathComponent("Recordings")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: tempDir, 
                                                withIntermediateDirectories: true, 
                                                attributes: nil)
        return tempDir
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
            hasRecording = false
        }
    }
}