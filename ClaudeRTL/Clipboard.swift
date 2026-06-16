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
}
