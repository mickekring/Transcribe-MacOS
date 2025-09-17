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
                .frame(minWidth: 1100, minHeight: 700)
                .frame(idealWidth: 1400, idealHeight: 850)
                .preferredColorScheme(.light)
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
                .navigationTitle("")
        }
    }
}
