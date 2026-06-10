import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var bubblePanel: BubblePanel!
    private var enabledMenuItem: NSMenuItem!
    private var fontSizeMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLog.print("✅ applicationDidFinishLaunching CALLED")

        if let appIcon = NSImage(named: "AppIcon") ?? loadBundledIcon(named: "AppIcon", ext: "icns") {
            NSApplication.shared.applicationIconImage = appIcon
        }

        bubblePanel = BubblePanel()
        setupSelectionHandler()
        setupMenuBar()

        if !SelectionMonitor.isAccessibilityTrusted {
            _ = SelectionMonitor.requestAccessibilityPermission()
        }
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
            button.image = menuBarImage()
            button.title = "ع"
            button.imagePosition = button.image != nil ? .imageLeading : .noImage
            button.imageScaling = .scaleProportionallyDown
            button.toolTip = "Claude RTL"
            DebugLog.print("Menu bar: title=\(button.title), image=\(button.image != nil), reps=\(button.image?.representations.count ?? 0)")
        }

        let menu = NSMenu()

        enabledMenuItem = NSMenuItem(
            title: Settings.shared.isEnabled ? "تعطيل" : "تفعيل",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledMenuItem.target = self
        menu.addItem(enabledMenuItem)

        menu.addItem(.separator())

        let smaller = NSMenuItem(title: "خط أصغر (−)", action: #selector(decreaseFont), keyEquivalent: "")
        smaller.target = self
        menu.addItem(smaller)

        fontSizeMenuItem = NSMenuItem(title: fontSizeLabel(), action: nil, keyEquivalent: "")
        fontSizeMenuItem.isEnabled = false
        menu.addItem(fontSizeMenuItem)

        let larger = NSMenuItem(title: "خط أكبر (+)", action: #selector(increaseFont), keyEquivalent: "")
        larger.target = self
        menu.addItem(larger)

        menu.addItem(.separator())

        launchAtLoginMenuItem = NSMenuItem(
            title: "تشغيل عند بدء النظام",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.state = Settings.shared.isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "حول Claude RTL", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let onboarding = NSMenuItem(title: "إعادة الشرح", action: #selector(showOnboarding), keyEquivalent: "")
        onboarding.target = self
        menu.addItem(onboarding)

        let quit = NSMenuItem(title: "خروج", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func fontSizeLabel() -> String {
        "حجم الخط: \(Int(Settings.shared.fontSize))px"
    }

    private func menuBarImage() -> NSImage? {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.isTemplate = false
        var added = false

        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let rep = NSBitmapImageRep(data: data) {
            rep.size = NSSize(width: 18, height: 18)
            image.addRepresentation(rep)
            added = true
        }
        if let url = Bundle.main.url(forResource: "MenuBarIcon@2x", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let rep = NSBitmapImageRep(data: data) {
            rep.size = NSSize(width: 18, height: 18)
            image.addRepresentation(rep)
            added = true
        }
        if !added {
            added = addAssetRepresentation(to: image, named: "MenuBarIcon")
                || addAssetRepresentation(to: image, named: "AppIcon")
        }
        return added ? image : nil
    }

    private func addAssetRepresentation(to image: NSImage, named: String) -> Bool {
        guard let source = NSImage(named: named), source.isValid else { return false }
        for rep in source.representations {
            rep.size = NSSize(width: 18, height: 18)
            image.addRepresentation(rep)
        }
        return !image.representations.isEmpty
    }

    private func loadBundledIcon(named: String, ext: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: named, withExtension: ext) else { return nil }
        return NSImage(contentsOf: url)
    }

    @objc private func toggleEnabled() {
        Settings.shared.isEnabled.toggle()
        enabledMenuItem.title = Settings.shared.isEnabled ? "تعطيل" : "تفعيل"
        if !Settings.shared.isEnabled {
            bubblePanel.hide()
        }
    }

    @objc private func decreaseFont() {
        Settings.shared.fontSize = max(12, Settings.shared.fontSize - 1)
        fontSizeMenuItem.title = fontSizeLabel()
    }

    @objc private func increaseFont() {
        Settings.shared.fontSize = min(22, Settings.shared.fontSize + 1)
        fontSizeMenuItem.title = fontSizeLabel()
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
