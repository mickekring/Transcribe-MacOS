import SwiftUI

extension Color {
    static let primaryAccent = Color(red: 0.58, green: 0.42, blue: 0.98)
    static let secondaryAccent = Color(red: 0.96, green: 0.42, blue: 0.65)
    static let tertiaryAccent = Color(red: 0.42, green: 0.58, blue: 0.98)
    
    static let gradientStart = Color(red: 0.58, green: 0.42, blue: 0.98).opacity(0.15)
    static let gradientEnd = Color(red: 0.96, green: 0.42, blue: 0.65).opacity(0.05)
    
    static let cardBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let sidebarBackground = Color.white.opacity(0.98)
    static let hoverBackground = Color(red: 0.58, green: 0.42, blue: 0.98).opacity(0.08)
    
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.45)
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.65)
    
    static let borderLight = Color(red: 0.9, green: 0.9, blue: 0.92)
    static let shadowColor = Color.black.opacity(0.04)
}

extension LinearGradient {
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.primaryAccent.opacity(0.15),
            Color.secondaryAccent.opacity(0.08)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.white,
            Color.cardBackground
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let accentGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.primaryAccent,
            Color.secondaryAccent
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .sidebar
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}