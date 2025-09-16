import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var aboutWindow: NSWindow?
    private var preferencesWindow: NSWindow?
    private var statusBarItem: NSStatusItem?
    private var settingsManager: SettingsManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Clean up any leftover files from previous session (in case of force quit)
        cleanupTemporaryFiles(isStartup: true)
        
        setupStatusBar()
        registerGlobalHotkeys()
        checkForUpdates()
        
        // Initialize settings manager on main thread
        Task { @MainActor in
            self.settingsManager = SettingsManager()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanupTemporaryFiles(isStartup: false)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Transcribe")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Transcribe", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "New Recording", action: #selector(startNewRecording), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quick Transcribe", action: #selector(quickTranscribe), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    private func registerGlobalHotkeys() {
        // Register global hotkeys for quick access
        // Implementation would use CGEventTap or similar
    }
    
    private func checkForUpdates() {
        Task {
            // Check for app updates
            // Implementation would use Sparkle or similar
        }
    }
    
    private func cleanupTemporaryFiles(isStartup: Bool = false) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("Transcribe")
        
        print("\n🧹 ========== CLEANUP DEBUG ==========")
        print("🔄 Cleanup Type: \(isStartup ? "STARTUP (cleaning previous session)" : "SHUTDOWN (normal cleanup)")")
        print("📁 Cleaning temporary directory: \(tempDir.path)")
        print("⏰ Cleanup time: \(Date())")
        
        // List files before deletion
        if let contents = try? FileManager.default.contentsOfDirectory(at: tempDir, 
                                                                      includingPropertiesForKeys: nil, 
                                                                      options: []) {
            if isStartup {
                print("🔍 Found leftover files from previous session:")
            } else {
                print("📋 Files to be deleted:")
            }
            
            for file in contents {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let fileSize = attributes[.size] as? Int64 {
                    let sizeMB = Double(fileSize) / (1024 * 1024)
                    print("  - \(file.lastPathComponent) (\(String(format: "%.2f MB", sizeMB)))")
                } else {
                    print("  - \(file.lastPathComponent)")
                }
            }
            print("📊 Total files: \(contents.count)")
            
            if isStartup && contents.count > 0 {
                print("⚠️ These files were left from a force-quit or crash")
            }
        } else {
            print("📭 No temporary files found or directory doesn't exist")
        }
        
        // Perform cleanup
        do {
            try FileManager.default.removeItem(at: tempDir)
            print("✅ Successfully cleaned up all temporary files")
        } catch {
            print("⚠️ Cleanup note: \(error.localizedDescription)")
        }
        
        print("=====================================\n")
    }
    
    @objc func statusBarButtonClicked() {
        if let menu = statusBarItem?.menu {
            statusBarItem?.button?.performClick(nil)
        }
    }
    
    @objc func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func startNewRecording() {
        NotificationCenter.default.post(name: .startNewRecording, object: nil)
        openMainWindow()
    }
    
    @objc func quickTranscribe() {
        // Show quick transcribe floating window
        let quickTranscribeWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        quickTranscribeWindow.title = "Quick Transcribe"
        quickTranscribeWindow.center()
        quickTranscribeWindow.contentView = NSHostingView(rootView: QuickTranscribeView())
        quickTranscribeWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func showPreferences() {
        Task { @MainActor in
            if preferencesWindow == nil {
                preferencesWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false
                )
                preferencesWindow?.title = "Preferences"
                preferencesWindow?.center()
                
                // Create settings manager if needed
                if settingsManager == nil {
                    settingsManager = SettingsManager()
                }
                
                if let manager = settingsManager {
                    preferencesWindow?.contentView = NSHostingView(
                        rootView: SettingsView()
                            .environmentObject(manager)
                    )
                }
            }
            preferencesWindow?.makeKeyAndOrderFront(nil)
        }
    }
    
    func showAboutWindow() {
        if aboutWindow == nil {
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "About Transcribe"
            aboutWindow?.center()
            aboutWindow?.contentView = NSHostingView(rootView: AboutView())
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
    }
}

extension Notification.Name {
    static let startNewRecording = Notification.Name("startNewRecording")
    static let quickTranscribe = Notification.Name("quickTranscribe")
}