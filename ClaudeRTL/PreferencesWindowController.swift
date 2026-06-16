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
        window.setContentSize(NSSize(
            width: SettingsMetrics.windowWidth,
            height: SettingsMetrics.windowHeight
        ))
        window.minSize = NSSize(
            width: SettingsMetrics.windowMinWidth,
            height: SettingsMetrics.windowMinHeight
        )
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
