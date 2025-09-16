import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("appLanguage") var appLanguage: String = "en" {
        didSet {
            updateLanguage()
        }
    }
    
    @Published var currentLanguage: String = "en"
    
    private init() {
        currentLanguage = appLanguage
    }
    
    func updateLanguage() {
        currentLanguage = appLanguage
        // Force UI refresh
        objectWillChange.send()
    }
    
    func localizedString(_ key: String) -> String {
        let bundle = languageBundle()
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
    
    private func languageBundle() -> Bundle {
        let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj")
        return path != nil ? Bundle(path: path!) ?? Bundle.main : Bundle.main
    }
}

// Convenience function for localization
func localized(_ key: String) -> String {
    LocalizationManager.shared.localizedString(key)
}

// SwiftUI View Extension for easier localization
extension Text {
    init(localizedKey: String) {
        self.init(localized(localizedKey))
    }
}