import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var bubblePanel: BubblePanel!
    private var launchAtLoginMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLog.print("✅ applicationDidFinishLaunching CALLED")

        if let appIcon = NSImage(named: "AppIcon") ?? loadBundledIcon(named: "AppIcon", ext: "icns") {
            NSApplication.shared.applicationIconImage = appIcon
        }

        bubblePanel = BubblePanel()
        setupSelectionHandler()
        setupMenuBar()

        SelectionMonitor.shared.start()

        OnboardingWindowController.showIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        bubblePanel.hide()
    }

    // MARK: - Selection → bubble

    private func setupSelectionHandler() {
        SelectionMonitor.shared.onArabicSelection = { [weak self] text, point in
            guard Settings.shared.isEnabled else { return }
            self?.bubblePanel.show(at: point, text: text)
        }
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true

        if let button = statusItem.button {
            configureStatusBarButton(button)
        }

        let menu = NSMenu()

        let about = NSMenuItem(title: "حول Claude RTL", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let onboarding = NSMenuItem(title: "إعادة الشرح", action: #selector(showOnboarding), keyEquivalent: "")
        onboarding.target = self
        menu.addItem(onboarding)

        launchAtLoginMenuItem = NSMenuItem(
            title: "تشغيل عند بدء النظام",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.state = Settings.shared.isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "خروج", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu

        DebugLog.print("STATUS ITEM created, button=\(statusItem.button != nil)")
    }

    private func configureStatusBarButton(_ button: NSStatusBarButton) {
        button.toolTip = "Claude RTL"
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown

        if let symbol = statusBarSymbolImage() {
            button.image = symbol
            button.title = ""
        } else {
            button.image = nil
            button.title = "ع"
            button.imagePosition = .noImage
        }

        if let custom = menuBarTemplateImage() {
            button.image = custom
            button.title = ""
            button.imagePosition = .imageOnly
        }
    }

    private func statusBarSymbolImage() -> NSImage? {
        guard let symbol = NSImage(
            systemSymbolName: "character.book.closed.fill",
            accessibilityDescription: "Claude RTL"
        ) else { return nil }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let img = symbol.withSymbolConfiguration(config) ?? symbol
        img.isTemplate = true
        img.size = NSSize(width: 18, height: 18)
        return img
    }

    /// Custom menu-bar icon: black + alpha PNG rendered as template (18pt).
    private func menuBarTemplateImage() -> NSImage? {
        guard let source = NSImage(named: "MenuBarIcon"), source.isValid else { return nil }

        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.isTemplate = true
        for rep in source.representations {
            rep.size = NSSize(width: 18, height: 18)
            image.addRepresentation(rep)
        }
        guard !image.representations.isEmpty else { return nil }
        return image
    }

    private func loadBundledIcon(named: String, ext: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: named, withExtension: ext) else { return nil }
        return NSImage(contentsOf: url)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newValue = !Settings.shared.isLaunchAtLoginEnabled
        Settings.shared.setLaunchAtLogin(newValue)
        sender.state = Settings.shared.isLaunchAtLoginEnabled ? .on : .off
    }

    @objc private func showAbout() {
        AboutWindowController.show()
    }

    @objc private func showOnboarding() {
        OnboardingWindowController.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
