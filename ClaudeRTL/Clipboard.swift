import AppKit

enum Clipboard {
    static func read() -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }

    static func write(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        SelectionMonitor.shared.noteClipboardWrite()
    }

    /// Simulates ⌘C, waits for new clipboard content, then restores the previous clip.
    static func captureSelection() -> String? {
        let old = read()
        synthesizeCommandC()

        var captured: String?
        for _ in 0..<8 {
            Thread.sleep(forTimeInterval: 0.05)
            let current = read()
            if !current.isEmpty && current != old {
                captured = current
                break
            }
        }

        write(old)
        SelectionMonitor.shared.noteClipboardWrite()
        return captured
    }

    private static func synthesizeCommandC() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
