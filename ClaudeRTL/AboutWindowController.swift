import AppKit

final class AboutWindowController: NSWindowController {
    private static var sharedInstance: AboutWindowController?

    static func show() {
        if sharedInstance == nil {
            sharedInstance = AboutWindowController()
        }
        sharedInstance?.showWindow(nil)
        sharedInstance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Claude RTL"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.contentView = buildContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildContentView() -> NSView {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 360))

        let icon = NSImageView(frame: NSRect(x: 186, y: 280, width: 48, height: 48))
        icon.image = NSApplication.shared.applicationIconImage ?? NSImage(named: "AppIcon")
        icon.imageScaling = .scaleProportionallyUpOrDown
        root.addSubview(icon)

        let name = NSTextField(labelWithString: "Claude RTL")
        name.font = .boldSystemFont(ofSize: 20)
        name.alignment = .center
        name.frame = NSRect(x: 24, y: 248, width: 372, height: 26)
        root.addSubview(name)

        let versionString = Self.versionLabel()
        let version = NSTextField(labelWithString: versionString)
        version.font = .systemFont(ofSize: 13)
        version.textColor = .secondaryLabelColor
        version.alignment = .center
        version.frame = NSRect(x: 24, y: 224, width: 372, height: 20)
        root.addSubview(version)

        let credit = NSButton(title: "by GRW Lab — grwlab.net", target: self, action: #selector(openWebsite))
        credit.isBordered = false
        credit.font = .systemFont(ofSize: 13, weight: .medium)
        credit.contentTintColor = NSColor(red: 0.76, green: 0.37, blue: 0.24, alpha: 1)
        credit.frame = NSRect(x: 24, y: 196, width: 372, height: 22)
        root.addSubview(credit)

        let disclaimer = NSTextField(wrappingLabelWithString: Self.disclaimerText)
        disclaimer.font = .systemFont(ofSize: 12)
        disclaimer.textColor = .secondaryLabelColor
        disclaimer.alignment = .center
        disclaimer.frame = NSRect(x: 32, y: 72, width: 356, height: 112)
        root.addSubview(disclaimer)

        let ok = NSButton(title: "OK", target: self, action: #selector(closeAbout))
        ok.bezelStyle = .rounded
        ok.keyEquivalent = "\r"
        ok.frame = NSRect(x: 170, y: 24, width: 80, height: 32)
        root.addSubview(ok)

        return root
    }

    private static func versionLabel() -> String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private static let disclaimerText =
        "Claude RTL is an independent tool from GRW Lab. It is not affiliated with, endorsed by, or supported by Anthropic. “Claude” is a trademark of Anthropic."

    @objc private func openWebsite() {
        if let url = URL(string: "https://grwlab.net") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func closeAbout() {
        window?.close()
    }
}
