import SwiftUI

struct AboutView: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Transcribe")
                .font(.largeTitle)
                .bold()
            
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Advanced audio transcription for macOS")
                .font(.body)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                featureRow("Swedish-optimized with KB Whisper")
                featureRow("Local & cloud LLM processing")
                featureRow("Privacy-focused design")
                featureRow("Built with Swift & SwiftUI")
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Link("Website", destination: URL(string: "https://transcribe.app")!)
                Link("Support", destination: URL(string: "https://transcribe.app/support")!)
                Link("Privacy Policy", destination: URL(string: "https://transcribe.app/privacy")!)
            }
            .font(.caption)
            
            Text("© 2025 Transcribe. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 400)
    }
    
    func featureRow(_ text: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.body)
        }
    }
}