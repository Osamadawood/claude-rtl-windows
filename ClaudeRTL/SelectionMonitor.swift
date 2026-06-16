import AppKit

final class SelectionMonitor {
    static let shared = SelectionMonitor()

    var onArabicSelection: ((String, NSPoint) -> Void)?

    private var clipboardTimer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    private init() {}

    func start() {
        startClipboardPolling()
    }

    func noteClipboardWrite() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    // MARK: - Clipboard polling (⌘C)

    private func startClipboardPolling() {
        lastChangeCount = NSPasteboard.general.changeCount
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.pollClipboard()
        }
        if let clipboardTimer {
            RunLoop.main.add(clipboardTimer, forMode: .common)
        }
    }

    private func pollClipboard() {
        guard Settings.shared.isEnabled else { return }

        let changeCount = NSPasteboard.general.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount
        DebugLog.print("CLIP tick: changeCount=\(changeCount), frontmost=\(NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "nil")")

        let current = NSPasteboard.general.string(forType: .string) ?? ""
        guard !current.isEmpty, ArabicDetector.containsArabic(current) else { return }
        guard shouldShowForFrontmostApp() else { return }

        DebugLog.print("ARABIC detected, showing bubble")
        let point = NSEvent.mouseLocation
        onArabicSelection?(current, point)
    }

    private func shouldShowForFrontmostApp() -> Bool {
        let front = NSWorkspace.shared.frontmostApplication
        let bundleID = front?.bundleIdentifier ?? ""

        if Settings.shared.excludedBundleIDsSession.contains(bundleID) { return false }
        if Settings.shared.excludedBundleIDsAlways.contains(bundleID) { return false }

        switch Settings.shared.triggerMode {
        case .allApps:
            return true
        case .claudeOnly:
            return Settings.isClaudeApp(bundleID: bundleID, localizedName: front?.localizedName)
        case .customList:
            return Settings.shared.includedBundleIDs.contains(bundleID)
        }
    }
}
