import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    private static var sharedInstance: PreferencesWindowController?

    static func show() {
        if sharedInstance == nil {
            sharedInstance = PreferencesWindowController()
        }
        sharedInstance?.showWindow(nil)
        sharedInstance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private init() {
        let hosting = NSHostingController(rootView: SettingsRootView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "الإعدادات"
        window.setContentSize(NSSize(width: 520, height: 440))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
