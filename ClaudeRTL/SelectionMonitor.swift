import AppKit
import ApplicationServices
import CoreGraphics

extension Notification.Name {
    static let selectionMonitorEventTapArmed = Notification.Name("SelectionMonitorEventTapArmed")
}

final class SelectionMonitor {
    static let shared = SelectionMonitor()

    var onArabicSelection: ((String, NSPoint) -> Void)?

    private(set) var isEventTapArmed = false

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var thread: Thread?
    private var downPoint = CGPoint.zero
    private var suppressClipboardUntil: TimeInterval = 0
    private var clipboardTimer: Timer?
    private var axPollTimer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    private init() {}

    func start() {
        startClipboardFallback()
        tryInstallEventTapIfTrusted()
        startAccessibilityPollingIfNeeded()
    }

    /// Call when the app becomes active (e.g. returning from System Settings).
    func refreshAccessibilityStatus() {
        tryInstallEventTapIfTrusted()
    }

    func markClipboardSuppressed(for duration: TimeInterval = 1.3) {
        suppressClipboardUntil = Date().timeIntervalSinceReferenceDate + duration
    }

    func noteClipboardWrite() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    static func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    // MARK: - Accessibility polling

    private func startAccessibilityPollingIfNeeded() {
        guard !isEventTapArmed else { return }
        guard axPollTimer == nil else { return }

        axPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.tryInstallEventTapIfTrusted()
        }
        if let axPollTimer {
            RunLoop.main.add(axPollTimer, forMode: .common)
        }
    }

    private func stopAccessibilityPolling() {
        axPollTimer?.invalidate()
        axPollTimer = nil
    }

    private func tryInstallEventTapIfTrusted() {
        guard Self.isAccessibilityTrusted else { return }
        guard !isEventTapArmed else { return }
        guard thread == nil else { return }

        let thread = Thread { [weak self] in
            guard let self else { return }
            if self.installEventTapOnCurrentThread() {
                DispatchQueue.main.async {
                    self.isEventTapArmed = true
                    self.stopAccessibilityPolling()
                    DebugLog.print("✅ CGEventTap armed")
                    NotificationCenter.default.post(name: .selectionMonitorEventTapArmed, object: nil)
                }
                CFRunLoopRun()
            } else {
                DispatchQueue.main.async {
                    self.thread = nil
                    DebugLog.print("Event tap create failed — will retry")
                }
            }
        }
        thread.name = "ClaudeRTL.SelectionMonitor"
        thread.start()
        self.thread = thread
    }

    // MARK: - Event tap

    private func installEventTapOnCurrentThread() -> Bool {
        let mask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                let monitor = Unmanaged<SelectionMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                monitor.handleEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        let location = event.location

        switch type {
        case .leftMouseDown:
            downPoint = location
        case .leftMouseUp:
            let dx = location.x - downPoint.x
            let dy = location.y - downPoint.y
            guard (dx * dx + dy * dy) > 36 else { return }
            guard isFrontmostClaudeApp() else { return }
            guard Settings.shared.isEnabled else { return }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureAndNotify(at: location)
            }
        default:
            break
        }
    }

    private func captureAndNotify(at location: CGPoint) {
        guard isFrontmostClaudeApp() else { return }
        markClipboardSuppressed()
        guard let text = Clipboard.captureSelection(),
              ArabicDetector.containsArabic(text) else { return }
        noteClipboardWrite()

        let point = NSEvent.mouseLocation
        DispatchQueue.main.async { [weak self] in
            self?.onArabicSelection?(text, point)
        }
    }

    // MARK: - Clipboard fallback (manual ⌘C — no Accessibility required)

    private func startClipboardFallback() {
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

        let now = Date().timeIntervalSinceReferenceDate
        guard now >= suppressClipboardUntil else { return }

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

    /// True when the frontmost app is Claude desktop (heuristic; tighten to allowlist after DEBUG confirms bundle id).
    private func isFrontmostClaudeApp() -> Bool {
        let front = NSWorkspace.shared.frontmostApplication
        let bid = front?.bundleIdentifier?.lowercased() ?? ""
        let name = front?.localizedName?.lowercased() ?? ""
        let isClaude = bid.contains("claude") || bid.contains("anthropic") || name == "claude"
        return isClaude
    }
}
