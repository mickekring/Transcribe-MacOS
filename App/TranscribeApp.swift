import SwiftUI

@main
struct TranscribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var transcriptionManager = TranscriptionManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(transcriptionManager)
                .environmentObject(settingsManager)
                .frame(minWidth: 800, minHeight: 600)
                .frame(idealWidth: 1200, idealHeight: 800)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Transcribe") {
                    appDelegate.showAboutWindow()
                }
            }
            
            CommandGroup(after: .appSettings) {
                Button("Preferences...") {
                    appDelegate.showPreferences()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedFeature: Feature?
    @Published var isProcessing = false
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var currentUser: UserProfile = .default
    
    enum Feature: String, CaseIterable {
        case openFiles = "Open Files"
        case newRecording = "New Recording"
        case recordMeeting = "Record Meeting"
        case batchTranscription = "Batch Transcription"
        case recordAppAudio = "Record App Audio"
        case dictation = "Dictation"
        case transcribePodcast = "Transcribe Podcast"
        case global = "Global"
        case cloudTranscription = "Cloud Transcription"
    }
}

struct SearchHistoryItem: Identifiable {
    let id = UUID()
    let query: String
    let date: Date
    let results: [TranscriptionResult]
}

struct UserProfile {
    let id: UUID
    let name: String
    let avatar: String?
    
    static let `default` = UserProfile(id: UUID(), name: "Default", avatar: nil)
}