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

    @Published var themeMode: ThemeMode {
        didSet {
            guard !suppressSync else { return }
            Settings.shared.themeMode = themeMode
            ThemeManager.shared.applyToAllWebViews()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet { guard !suppressSync else { return }; Settings.shared.setLaunchAtLogin(launchAtLogin) }
    }

    @Published var excludedApps: [AppRecord]
    @Published var includedApps: [AppRecord]

    var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
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
                guard self?.themeMode == .auto else { return }
                self?.objectWillChange.send()
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
        ThemeManager.shared.applyToAllWebViews()
        suppressSync = true
        triggerMode = .allApps
        fontSize = 16
        themeMode = .auto
        excludedApps = []
        includedApps = []
        suppressSync = false
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
