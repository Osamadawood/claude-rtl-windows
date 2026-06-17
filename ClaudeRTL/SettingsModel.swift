import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class SettingsModel: ObservableObject {
    static let shared = SettingsModel()

    @Published var isEnabled: Bool {
        didSet { guard !suppressSync else { return }; Settings.shared.isEnabled = isEnabled }
    }

    @Published var triggerMode: TriggerMode {
        didSet { guard !suppressSync else { return }; Settings.shared.triggerMode = triggerMode }
    }

    @Published var fontSize: Double {
        didSet { guard !suppressSync else { return }; Settings.shared.fontSize = fontSize }
    }

    @Published private(set) var appearanceScheme: ColorScheme

    private(set) var themeMode: ThemeMode {
        didSet {
            guard !suppressSync else { return }
            Settings.shared.themeMode = themeMode
        }
    }

    @Published var launchAtLogin: Bool {
        didSet { guard !suppressSync else { return }; Settings.shared.setLaunchAtLogin(launchAtLogin) }
    }

    @Published var excludedApps: [AppRecord]
    @Published var includedApps: [AppRecord]

    func setThemeMode(_ mode: ThemeMode) {
        guard mode != themeMode else { return }
        themeMode = mode
        ThemeManager.shared.applyToAllWebViewsIfNeeded()
        let scheme = Self.resolveColorScheme(for: mode)
        if scheme != appearanceScheme {
            appearanceScheme = scheme
        }
    }

    static func resolveColorScheme(for mode: ThemeMode) -> ColorScheme {
        switch mode {
        case .light: return .light
        case .dark: return .dark
        case .auto:
            let best = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            return best == .darkAqua ? .dark : .light
        }
    }

    private var suppressSync = false

    private init() {
        let settings = Settings.shared
        suppressSync = true
        isEnabled = settings.isEnabled
        triggerMode = settings.triggerMode
        fontSize = settings.fontSize
        themeMode = settings.themeMode
        appearanceScheme = Self.resolveColorScheme(for: settings.themeMode)
        launchAtLogin = settings.isLaunchAtLoginEnabled
        excludedApps = settings.excludedAppsAlways
        includedApps = settings.includedApps
        suppressSync = false

        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.themeMode == .auto else { return }
                let scheme = Self.resolveColorScheme(for: .auto)
                if scheme != self.appearanceScheme {
                    self.appearanceScheme = scheme
                }
                ThemeManager.shared.applyToAllWebViewsIfNeeded()
            }
        }
    }

    func reloadLists() {
        excludedApps = Settings.shared.excludedAppsAlways
        includedApps = Settings.shared.includedApps
    }

    func resetFontSize() {
        fontSize = 16
        Settings.shared.resetFontSize()
    }

    func resetAllSettings() {
        Settings.shared.resetAllSettingsExceptLaunchAtLogin()
        suppressSync = true
        triggerMode = .allApps
        fontSize = 16
        themeMode = .auto
        appearanceScheme = Self.resolveColorScheme(for: .auto)
        excludedApps = []
        includedApps = []
        suppressSync = false
        ThemeManager.shared.applyToAllWebViews()
    }

    func removeExcluded(_ bundleId: String) {
        Settings.shared.removeExcludedPermanently(bundleId)
        reloadLists()
    }

    func removeIncluded(_ bundleId: String) {
        Settings.shared.removeIncludedApp(bundleId)
        reloadLists()
    }

    func addExcludedApp() {
        pickApplication { [weak self] record in
            Settings.shared.excludePermanently(bundleID: record.bundleId, name: record.name)
            self?.reloadLists()
        }
    }

    func addIncludedApp() {
        pickApplication { [weak self] record in
            Settings.shared.addIncludedApp(bundleID: record.bundleId, name: record.name)
            self?.reloadLists()
        }
    }

    func showOnboarding() {
        OnboardingWindowController.show()
    }

    private func pickApplication(completion: @escaping (AppRecord) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "اختر تطبيقًا"
        panel.message = "اختر تطبيقًا من مجلد Applications"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let name = url.deletingPathExtension().lastPathComponent
            let bundleId = Bundle(url: url)?.bundleIdentifier ?? url.path
            Task { @MainActor in
                completion(AppRecord(bundleId: bundleId, name: name))
            }
        }
    }
}
