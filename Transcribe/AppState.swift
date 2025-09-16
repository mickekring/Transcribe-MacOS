import SwiftUI

class AppState: ObservableObject {
    @Published var selectedFeature: Feature?
    @Published var isProcessing = false
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var currentUser: UserProfile = .default
    @Published var currentTranscriptionURL: URL?
    @Published var showTranscriptionView = false
    @Published var showRecordingView = false
    
    enum Feature: String, CaseIterable {
        case openFiles = "Open Files"
        case newRecording = "New Recording"
        case batchTranscription = "Batch Transcription"
    }
    
    func openFileForTranscription(_ url: URL) {
        currentTranscriptionURL = url
        showTranscriptionView = true
    }
}

struct SearchHistoryItem: Identifiable, Hashable {
    let id = UUID()
    let query: String
    let date: Date
    let results: [TranscriptionResult]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchHistoryItem, rhs: SearchHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct UserProfile {
    let id: UUID
    let name: String
    let avatar: String?
    
    static let `default` = UserProfile(id: UUID(), name: "Default", avatar: nil)
}