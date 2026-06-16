import Foundation
import ServiceManagement

enum TriggerMode: String, CaseIterable {
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

    var includedBundleIDs: [String] {
        get { defaults.stringArray(forKey: Keys.includedBundleIDs) ?? [] }
        set { defaults.set(newValue, forKey: Keys.includedBundleIDs) }
    }

    var excludedBundleIDsAlways: [String] {
        get { defaults.stringArray(forKey: Keys.excludedBundleIDsAlways) ?? [] }
        set { defaults.set(newValue, forKey: Keys.excludedBundleIDsAlways) }
    }

    func excludeForSession(bundleID: String) {
        guard !bundleID.isEmpty else { return }
        excludedBundleIDsSession.insert(bundleID)
    }

    func excludePermanently(bundleID: String) {
        guard !bundleID.isEmpty else { return }
        var list = excludedBundleIDsAlways
        guard !list.contains(bundleID) else { return }
        list.append(bundleID)
        excludedBundleIDsAlways = list
    }

    func removeIncludedBundleID(_ bundleID: String) {
        includedBundleIDs = includedBundleIDs.filter { $0 != bundleID }
    }

    func addIncludedBundleID(_ bundleID: String) {
        guard !bundleID.isEmpty, !includedBundleIDs.contains(bundleID) else { return }
        includedBundleIDs = includedBundleIDs + [bundleID]
    }

    func removeExcludedPermanently(_ bundleID: String) {
        excludedBundleIDsAlways = excludedBundleIDsAlways.filter { $0 != bundleID }
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
