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
        guard !current.isEmpty, containsArabic(current) else { return }
        guard isFrontmostClaudeApp() else { return }

        DebugLog.print("ARABIC detected in Claude, showing bubble")
        let point = NSEvent.mouseLocation
        onArabicSelection?(current, point)
    }

    private func containsArabic(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
    }

    /// True when the frontmost app is Claude desktop (heuristic).
    private func isFrontmostClaudeApp() -> Bool {
        let front = NSWorkspace.shared.frontmostApplication
        let bid = front?.bundleIdentifier?.lowercased() ?? ""
        let name = front?.localizedName?.lowercased() ?? ""
        return bid.contains("claude") || bid.contains("anthropic") || name == "claude"
    }
}
