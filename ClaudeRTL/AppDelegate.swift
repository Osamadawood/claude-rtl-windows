import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var bubblePanel: BubblePanel!
    private var excludeAppMenuItem: NSMenuItem!
    private var frontmostBundleIDForMenu: String?
    private var lastExternalApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLog.print("✅ applicationDidFinishLaunching CALLED")

        NSApp.userInterfaceLayoutDirection = .rightToLeft

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
            self?.lastExternalApp = app
        }

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
        menu.delegate = self
        MenuRTL.configure(menu)

        let preferences = MenuRTL.item("الإعدادات…", action: #selector(showPreferences), target: self, keyEquivalent: ",")
        menu.addItem(preferences)

        excludeAppMenuItem = MenuRTL.item("إيقاف على …", action: nil, target: nil)
        let excludeSubmenu = NSMenu()
        MenuRTL.configure(excludeSubmenu)
        excludeSubmenu.addItem(MenuRTL.submenuItem("هذه الجلسة", action: #selector(excludeFrontmostSession), target: self))
        excludeSubmenu.addItem(MenuRTL.submenuItem("دائمًا", action: #selector(excludeFrontmostAlways), target: self))
        excludeAppMenuItem.submenu = excludeSubmenu
        menu.addItem(excludeAppMenuItem)

        menu.addItem(.separator())

        let quit = MenuRTL.item("خروج", action: #selector(quit), target: self, keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu

        DebugLog.print("STATUS ITEM created, button=\(statusItem.button != nil)")
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateExcludeMenuTitle()
    }

    private func updateExcludeMenuTitle() {
        let front = NSWorkspace.shared.frontmostApplication
        let targetApp: NSRunningApplication?
        if front?.bundleIdentifier == Bundle.main.bundleIdentifier {
            targetApp = lastExternalApp
        } else {
            targetApp = front
        }

        frontmostBundleIDForMenu = targetApp?.bundleIdentifier
        let name = targetApp?.localizedName ?? "التطبيق"
        MenuRTL.setTitle(excludeAppMenuItem, "إيقاف على \(name)")
        excludeAppMenuItem.isEnabled = targetApp?.bundleIdentifier != nil
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

    @objc private func showPreferences() {
        PreferencesWindowController.show()
    }

    @objc private func excludeFrontmostSession() {
        guard let bundleID = frontmostBundleIDForMenu ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        Settings.shared.excludeForSession(bundleID: bundleID)
    }

    @objc private func excludeFrontmostAlways() {
        guard let bundleID = frontmostBundleIDForMenu else { return }
        Settings.shared.excludePermanently(bundleID: bundleID)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
