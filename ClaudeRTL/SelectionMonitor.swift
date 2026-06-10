import AppKit
import ApplicationServices
import CoreGraphics

final class SelectionMonitor {
    static let shared = SelectionMonitor()

    var onArabicSelection: ((String, NSPoint) -> Void)?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var thread: Thread?
    private var downPoint = CGPoint.zero
    private var suppressClipboardUntil: TimeInterval = 0
    private var clipboardTimer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    private init() {}

    func start() {
        guard thread == nil else { return }
        let thread = Thread { [weak self] in
            self?.runEventTap()
        }
        thread.name = "ClaudeRTL.SelectionMonitor"
        thread.start()
        self.thread = thread

        startClipboardFallback()
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

    // MARK: - Event tap

    private func runEventTap() {
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
            NSLog("ClaudeRTL: event tap unavailable — using ⌘C fallback only")
            CFRunLoopRun()
            return
        }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        CFRunLoopRun()
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
            guard frontmostAppName() == "Claude" else { return }
            guard Settings.shared.isEnabled else { return }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureAndNotify(at: location)
            }
        default:
            break
        }
    }

    private func captureAndNotify(at location: CGPoint) {
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
        DebugLog.print("CLIP tick: changeCount=\(changeCount)")

        let now = Date().timeIntervalSinceReferenceDate
        guard now >= suppressClipboardUntil else { return }

        let current = NSPasteboard.general.string(forType: .string) ?? ""
        guard !current.isEmpty, containsArabic(current) else { return }

        DebugLog.print("ARABIC detected, showing bubble")
        let point = NSEvent.mouseLocation
        onArabicSelection?(current, point)
    }

    private func containsArabic(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
    }

    private func frontmostAppName() -> String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
    }
}
