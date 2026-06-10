import Foundation
import ServiceManagement

final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let enabled = "enabled"
        static let fontSize = "fontSize"
        static let launchAtLogin = "launchAtLogin"
        static let didOnboard = "didOnboard"
    }

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
