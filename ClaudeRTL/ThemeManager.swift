import AppKit

enum ThemeMode: String, CaseIterable, Codable {
    case auto
    case light
    case dark

    var label: String {
        switch self {
        case .auto: return "تلقائي"
        case .light: return "فاتح"
        case .dark: return "داكن"
        }
    }
}

final class ThemeManager {
    static let shared = ThemeManager()

    private init() {}

    func start() {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard Settings.shared.themeMode == .auto else { return }
            self?.applyToAllWebViews()
        }
    }

    func effectiveTheme() -> String {
        switch Settings.shared.themeMode {
        case .light:
            return "light"
        case .dark:
            return "dark"
        case .auto:
            let best = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            return best == .darkAqua ? "dark" : "light"
        }
    }

    func applyToAllWebViews() {
        let theme = effectiveTheme()
        BubbleRenderer.shared.applyTheme(theme)
        OnboardingWindowController.applyThemeIfVisible(theme)
    }
}
