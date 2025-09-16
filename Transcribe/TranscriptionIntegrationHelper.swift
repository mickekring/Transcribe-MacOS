import Foundation
import SwiftUI

/// Helper class to integrate the unified transcription service into existing views
class TranscriptionIntegrationHelper {
    
    /// Updates TranscriptionViewModel to use UnifiedTranscriptionService
    /// Add this to your TranscriptionViewModel
    static func setupTranscriptionViewModel() -> String {
        return """
        // In TranscriptionViewModel.swift, replace WhisperKit usage with:
        
        @MainActor
        class TranscriptionViewModel: ObservableObject {
            @Published var transcriptionText = ""
            @Published var isTranscribing = false
            @Published var progress: Double = 0.0
            @Published var currentModel: String?
            
            private let unifiedService = UnifiedTranscriptionService()
            
            func startTranscription(fileURL: URL) async {
                isTranscribing = true
                
                do {
                    // Load selected model
                    if let model = currentModel {
                        try await unifiedService.loadModel(model)
                    }
                    
                    // Perform transcription
                    let result = try await unifiedService.transcribe(
                        audioURL: fileURL,
                        language: selectedLanguage,
                        progressHandler: { progress in
                            Task { @MainActor in
                                self.progress = progress
                            }
                        }
                    )
                    
                    // Update UI with result
                    await MainActor.run {
                        self.transcriptionText = result.text
                        self.isTranscribing = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.isTranscribing = false
                    }
                }
            }
        }
        """
    }
    
    /// Updates ContentView model dropdown to show both KB and OpenAI models
    static func updateModelDropdown() -> String {
        return """
        // In ContentView.swift, update the model dropdown:
        
        Menu {
            // Swedish Models Section
            Section("Svenska modeller") {
                ForEach(["kb-whisper-tiny", "kb-whisper-base", "kb-whisper-small", 
                         "kb-whisper-medium", "kb-whisper-large"], id: \\.self) { model in
                    Button(action: {
                        selectedModel = model
                    }) {
                        HStack {
                            Text(formatModelName(model))
                            if ModelManager.shared.isModelDownloaded(model) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Multilingual Models Section
            Section("Flerspråkiga modeller") {
                ForEach(["openai_whisper-base", "openai_whisper-small", 
                         "openai_whisper-medium", "openai_whisper-large-v2", 
                         "openai_whisper-large-v3"], id: \\.self) { model in
                    Button(action: {
                        selectedModel = model
                    }) {
                        HStack {
                            Text(formatModelName(model))
                            if ModelManager.shared.isModelDownloaded(model) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "cpu")
                Text(formatModelName(selectedModel))
                Image(systemName: "chevron.down")
            }
        }
        """
    }
    
    /// Format model names for display
    static func formatModelName(_ modelId: String) -> String {
        // KB Whisper models
        if modelId.hasPrefix("kb-whisper-") {
            let size = modelId.replacingOccurrences(of: "kb-whisper-", with: "")
            return "KB \(size.capitalized) 🇸🇪"
        }
        
        // OpenAI Whisper models
        if modelId.hasPrefix("openai_whisper-") {
            let variant = modelId.replacingOccurrences(of: "openai_whisper-", with: "")
            return "OpenAI \(variant.capitalized)"
        }
        
        return modelId
    }
    
    /// Check if model is Swedish-optimized
    static func isSwedishModel(_ modelId: String) -> Bool {
        return modelId.hasPrefix("kb-whisper")
    }
    
    /// Get recommended model for language
    static func recommendedModel(for language: String) -> String {
        switch language {
        case "sv", "Swedish", "Svenska":
            return "kb-whisper-base" // Good balance of speed and accuracy
        default:
            return "openai_whisper-base"
        }
    }
    
    /// Model comparison for UI display
    static func getModelComparison() -> [(name: String, speed: String, accuracy: String, size: String)] {
        return [
            // KB Models
            ("kb-whisper-tiny", "50x", "★★☆☆☆", "39 MB"),
            ("kb-whisper-base", "16x", "★★★☆☆", "74 MB"),
            ("kb-whisper-small", "6x", "★★★★☆", "244 MB"),
            ("kb-whisper-medium", "3x", "★★★★☆", "769 MB"),
            ("kb-whisper-large", "1x", "★★★★★", "1.5 GB"),
            
            // OpenAI Models
            ("openai_whisper-base", "20x", "★★★☆☆", "147 MB"),
            ("openai_whisper-small", "9x", "★★★★☆", "488 MB"),
            ("openai_whisper-medium", "5x", "★★★★☆", "1.5 GB"),
            ("openai_whisper-large-v2", "2x", "★★★★★", "3.1 GB"),
            ("openai_whisper-large-v3", "2x", "★★★★★", "3.1 GB")
        ]
    }
}

// MARK: - Settings View Integration

extension TranscriptionIntegrationHelper {
    
    /// Settings view for local models showing both KB and OpenAI models
    static func createLocalModelsSettingsView() -> String {
        return """
        struct LocalModelsSettingsView: View {
            @StateObject private var modelManager = ModelManager.shared
            @StateObject private var unifiedService = UnifiedTranscriptionService()
            
            var body: some View {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // KB Whisper Models
                        VStack(alignment: .leading, spacing: 16) {
                            Label("KB Whisper (Svenska)", systemImage: "flag.circle.fill")
                                .font(.headline)
                            
                            ForEach(unifiedService.getSwedishModels()) { model in
                                ModelSettingRow(
                                    model: model,
                                    onDownload: {
                                        Task {
                                            try await modelManager.downloadModel(model.id)
                                        }
                                    },
                                    onDelete: {
                                        modelManager.deleteModel(model.id)
                                    }
                                )
                            }
                        }
                        
                        Divider()
                        
                        // OpenAI Whisper Models
                        VStack(alignment: .leading, spacing: 16) {
                            Label("OpenAI Whisper (Flerspråkig)", systemImage: "globe")
                                .font(.headline)
                            
                            ForEach(unifiedService.getMultilingualModels()) { model in
                                ModelSettingRow(
                                    model: model,
                                    onToggle: { enabled in
                                        if enabled {
                                            modelManager.enabledWhisperKitModels.insert(model.id)
                                        } else {
                                            modelManager.enabledWhisperKitModels.remove(model.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        """
    }
}

// MARK: - Model Setting Row Component

struct ModelSettingRow: View {
    let model: TranscriptionModel
    var onDownload: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onToggle: ((Bool) -> Void)? = nil
    
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.system(size: 14, weight: .medium))
                
                HStack(spacing: 8) {
                    Text(model.size)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if model.language == "Swedish" {
                        Label("Swedish", systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // All models now use WhisperKit - toggle enable/disable
            Toggle("", isOn: Binding(
                get: { model.downloaded },
                set: { onToggle?($0) }
            ))
            .toggleStyle(.switch)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}