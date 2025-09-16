import SwiftUI
import AVFoundation

struct QuickTranscribeView: View {
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var transcriptionManager = TranscriptionManager()
    @State private var transcriptionText = ""
    @State private var isRecording = false
    @State private var isTranscribing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Quick Transcribe")
                .font(.title2)
                .bold()
            
            if isRecording {
                audioWaveform
            }
            
            ScrollView {
                Text(transcriptionText.isEmpty ? "Start recording to transcribe..." : transcriptionText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 150)
            
            HStack(spacing: 20) {
                recordButton
                
                if !transcriptionText.isEmpty {
                    copyButton
                    clearButton
                }
            }
            
            if isTranscribing {
                ProgressView("Transcribing...")
                    .progressViewStyle(.linear)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    var audioWaveform: some View {
        HStack(spacing: 2) {
            ForEach(0..<20, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: CGFloat.random(in: 10...40))
                    .animation(.easeInOut(duration: 0.2).repeatForever(), value: isRecording)
            }
        }
        .frame(height: 50)
    }
    
    var recordButton: some View {
        Button(action: toggleRecording) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(isRecording ? .red : .accentColor)
        }
        .buttonStyle(.plain)
    }
    
    var copyButton: some View {
        Button(action: copyToClipboard) {
            Label("Copy", systemImage: "doc.on.clipboard")
        }
    }
    
    var clearButton: some View {
        Button(action: clearTranscription) {
            Label("Clear", systemImage: "trash")
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        recorder.startRecording()
        isRecording = true
    }
    
    func stopRecording() {
        let audioURL = recorder.stopRecording()
        isRecording = false
        
        if let url = audioURL {
            transcribeAudio(url)
        }
    }
    
    func transcribeAudio(_ url: URL) {
        isTranscribing = true
        
        Task {
            transcriptionManager.transcribeFile(url)
            
            // Wait for transcription to complete
            for await _ in transcriptionManager.$completedTranscriptions.values {
                if let lastTranscription = transcriptionManager.completedTranscriptions.last {
                    await MainActor.run {
                        transcriptionText = lastTranscription.text
                        isTranscribing = false
                    }
                    break
                }
            }
        }
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcriptionText, forType: .string)
    }
    
    func clearTranscription() {
        transcriptionText = ""
    }
}

class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
            recordingURL = audioFilename
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        return recordingURL
    }
}