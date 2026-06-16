import AppKit
import Foundation
import ServiceManagement

enum TriggerMode: String, CaseIterable, Codable {
    case allApps
    case claudeOnly
    case customList

    var label: String {
        switch self {
        case .allApps: return "كل التطبيقات"
        case .claudeOnly: return "Claude فقط"
        case .customList: return "قائمة مخصّصة"
        }
    }
}

struct AppRecord: Codable, Equatable {
    var bundleId: String
    var name: String
}

struct AppRecordDTO: Encodable {
    let bundleId: String
    let name: String
    let icon: String?
}

struct SettingsSnapshot: Encodable {
    let enabled: Bool
    let mode: String
    let excluded: [AppRecordDTO]
    let included: [AppRecordDTO]
    let fontSize: Int
    let themeMode: String
    let effectiveTheme: String
    let launchAtLogin: Bool
    let autoCheckUpdates: Bool
    let version: String
}

final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let enabled = "enabled"
        static let fontSize = "fontSize"
        static let launchAtLogin = "launchAtLogin"
        static let didOnboard = "didOnboard"
        static let triggerMode = "triggerMode"
        static let includedBundleIDs = "includedBundleIDs"
        static let excludedBundleIDsAlways = "excludedBundleIDsAlways"
        static let excludedAppsAlways = "excludedAppsAlways"
        static let includedApps = "includedApps"
        static let themeMode = "themeMode"
    }

    /// Session-only exclusions; cleared on each launch.
    private(set) var excludedBundleIDsSession = Set<String>()

    var isEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.enabled) == nil { return true }
            return defaults.bool(forKey: Keys.enabled)
        }
        set { defaults.set(newValue, forKey: Keys.enabled) }
    }

    var fontSize: Double {
        get {
            let value = defaults.double(forKey: Keys.fontSize)
            return value > 0 ? value : 16
        }
        set { defaults.set(newValue, forKey: Keys.fontSize) }
    }

    var didOnboard: Bool {
        get { defaults.bool(forKey: Keys.didOnboard) }
        set { defaults.set(newValue, forKey: Keys.didOnboard) }
    }

    var triggerMode: TriggerMode {
        get {
            guard let raw = defaults.string(forKey: Keys.triggerMode),
                  let mode = TriggerMode(rawValue: raw) else { return .allApps }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.triggerMode) }
    }

    var themeMode: ThemeMode {
        get {
            guard let raw = defaults.string(forKey: Keys.themeMode),
                  let mode = ThemeMode(rawValue: raw) else { return .auto }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.themeMode) }
    }

    var excludedAppsAlways: [AppRecord] {
        get {
            if let data = defaults.data(forKey: Keys.excludedAppsAlways),
               let records = try? JSONDecoder().decode([AppRecord].self, from: data) {
                return records
            }
            let ids = defaults.stringArray(forKey: Keys.excludedBundleIDsAlways) ?? []
            return ids.map { AppRecord(bundleId: $0, name: displayName(for: $0)) }
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.excludedAppsAlways)
            }
            excludedBundleIDsAlways = newValue.map(\.bundleId)
        }
    }

    var includedApps: [AppRecord] {
        get {
            if let data = defaults.data(forKey: Keys.includedApps),
               let records = try? JSONDecoder().decode([AppRecord].self, from: data) {
                return records
            }
            let ids = defaults.stringArray(forKey: Keys.includedBundleIDs) ?? []
            return ids.map { AppRecord(bundleId: $0, name: displayName(for: $0)) }
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.includedApps)
            }
            includedBundleIDs = newValue.map(\.bundleId)
        }
    }

    var includedBundleIDs: [String] {
        get { defaults.stringArray(forKey: Keys.includedBundleIDs) ?? [] }
        set { defaults.set(newValue, forKey: Keys.includedBundleIDs) }
    }

    var excludedBundleIDsAlways: [String] {
        get { defaults.stringArray(forKey: Keys.excludedBundleIDsAlways) ?? [] }
        set { defaults.set(newValue, forKey: Keys.excludedBundleIDsAlways) }
    }

    func snapshot() -> SettingsSnapshot {
        SettingsSnapshot(
            enabled: isEnabled,
            mode: triggerMode.rawValue,
            excluded: excludedAppsAlways.map(appDTO),
            included: includedApps.map(appDTO),
            fontSize: Int(fontSize),
            themeMode: themeMode.rawValue,
            effectiveTheme: ThemeManager.shared.effectiveTheme(),
            launchAtLogin: isLaunchAtLoginEnabled,
            autoCheckUpdates: SparkleUpdater.shared.automaticallyChecksForUpdates,
            version: Self.versionLabel()
        )
    }

    private func appDTO(_ app: AppRecord) -> AppRecordDTO {
        AppRecordDTO(
            bundleId: app.bundleId,
            name: app.name,
            icon: AppIconHelper.dataURL(forBundleIdentifier: app.bundleId)
        )
    }

    func resetFontSize() {
        fontSize = 16
    }

    func resetAllSettingsExceptLaunchAtLogin() {
        triggerMode = .allApps
        excludedAppsAlways = []
        includedApps = []
        excludedBundleIDsSession = []
        fontSize = 16
        themeMode = .auto
    }

    static func versionLabel() -> String {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    }

    func excludeForSession(bundleID: String) {
        guard !bundleID.isEmpty else { return }
        excludedBundleIDsSession.insert(bundleID)
    }

    func excludePermanently(bundleID: String, name: String? = nil) {
        guard !bundleID.isEmpty else { return }
        var list = excludedAppsAlways
        guard !list.contains(where: { $0.bundleId == bundleID }) else { return }
        list.append(AppRecord(bundleId: bundleID, name: name ?? displayName(for: bundleID)))
        excludedAppsAlways = list
    }

    func removeExcludedPermanently(_ bundleID: String) {
        excludedAppsAlways = excludedAppsAlways.filter { $0.bundleId != bundleID }
    }

    func addIncludedApp(bundleID: String, name: String) {
        guard !bundleID.isEmpty else { return }
        var list = includedApps
        guard !list.contains(where: { $0.bundleId == bundleID }) else { return }
        list.append(AppRecord(bundleId: bundleID, name: name))
        includedApps = list
    }

    func removeIncludedApp(_ bundleID: String) {
        includedApps = includedApps.filter { $0.bundleId != bundleID }
    }

    func displayName(for bundleID: String) -> String {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == bundleID }?
            .localizedName ?? bundleID
    }

    var isLaunchAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled, .requiresApproval:
                return true
            default:
                return false
            }
        }
        return defaults.bool(forKey: Keys.launchAtLogin)
    }

    func setLaunchAtLogin(_ on: Bool) {
        defaults.set(on, forKey: Keys.launchAtLogin)
        guard #available(macOS 13.0, *) else { return }
        if on {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    static func isClaudeApp(bundleID: String, localizedName: String?) -> Bool {
        let bid = bundleID.lowercased()
        let name = localizedName?.lowercased() ?? ""
        return bid.contains("claude") || bid.contains("anthropic") || name == "claude"
    }
}

enum ArabicDetector {
    private static let pattern = try! NSRegularExpression(
        pattern: "[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\uFB50-\\uFDFF\\uFE70-\\uFEFF]",
        options: []
    )

    static func containsArabic(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return pattern.firstMatch(in: text, options: [], range: range) != nil
    }
}
