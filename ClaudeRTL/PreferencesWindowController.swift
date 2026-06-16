import AppKit
import UniformTypeIdentifiers
import WebKit

final class PreferencesWindowController: NSWindowController, WKNavigationDelegate, WKScriptMessageHandler {
    private static var sharedInstance: PreferencesWindowController?

    static func show() {
        if sharedInstance == nil {
            sharedInstance = PreferencesWindowController()
        }
        sharedInstance?.showWindow(nil)
        sharedInstance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private weak var webView: WKWebView?

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "إعدادات Claude RTL"
        window.minSize = NSSize(width: 480, height: 380)
        window.maxSize = NSSize(width: 640, height: 960)
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "bridge")
        let webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        window.contentView?.addSubview(webView)
        self.webView = webView

        guard let url = Bundle.main.url(forResource: "settings", withExtension: "html") else {
            DebugLog.print("ERROR: settings.html not found in bundle")
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        applyTheme(ThemeManager.shared.effectiveTheme())
        pushStateToWebView()
    }

    static func applyThemeIfOpen(_ theme: String) {
        sharedInstance?.applyTheme(theme)
    }

    func applyTheme(_ theme: String) {
        let safe = theme == "light" ? "light" : "dark"
        webView?.evaluateJavaScript(
            "document.documentElement.setAttribute('data-theme', '\(safe)')",
            completionHandler: nil
        )
    }

    func pushStateToWebView() {
        guard let webView else { return }
        let snapshot = Settings.shared.snapshot()
        guard let data = try? JSONEncoder().encode(snapshot),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.loadSettings(\(json))", completionHandler: nil)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "bridge",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch action {
            case "setEnabled":
                Settings.shared.isEnabled = body["enabled"] as? Bool ?? true
                self.pushStateToWebView()
            case "setMode":
                if let raw = body["mode"] as? String, let mode = TriggerMode(rawValue: raw) {
                    Settings.shared.triggerMode = mode
                    self.pushStateToWebView()
                }
            case "removeExcluded":
                if let id = body["bundleId"] as? String {
                    Settings.shared.removeExcludedPermanently(id)
                    self.pushStateToWebView()
                }
            case "removeIncluded":
                if let id = body["bundleId"] as? String {
                    Settings.shared.removeIncludedApp(id)
                    self.pushStateToWebView()
                }
            case "addExcluded":
                self.pickApplication { record in
                    Settings.shared.excludePermanently(bundleID: record.bundleId, name: record.name)
                    self.pushStateToWebView()
                }
            case "addIncluded":
                self.pickApplication { record in
                    Settings.shared.addIncludedApp(bundleID: record.bundleId, name: record.name)
                    self.pushStateToWebView()
                }
            case "setFontSize":
                if let size = body["size"] as? Double {
                    Settings.shared.fontSize = size
                } else if let size = body["size"] as? Int {
                    Settings.shared.fontSize = Double(size)
                }
            case "resetFontSize":
                Settings.shared.resetFontSize()
                self.pushStateToWebView()
            case "resetAllSettings":
                Settings.shared.resetAllSettingsExceptLaunchAtLogin()
                ThemeManager.shared.applyToAllWebViews()
                self.pushStateToWebView()
            case "setThemeMode":
                if let raw = body["mode"] as? String, let mode = ThemeMode(rawValue: raw) {
                    Settings.shared.themeMode = mode
                    ThemeManager.shared.applyToAllWebViews()
                    self.pushStateToWebView()
                }
            case "setLaunchAtLogin":
                let enabled = body["enabled"] as? Bool ?? false
                Settings.shared.setLaunchAtLogin(enabled)
                self.pushStateToWebView()
            case "setAutoCheckUpdates":
                let enabled = body["enabled"] as? Bool ?? true
                SparkleUpdater.shared.automaticallyChecksForUpdates = enabled
                self.pushStateToWebView()
            case "checkForUpdates":
                SparkleUpdater.shared.checkForUpdates()
            case "showOnboarding":
                OnboardingWindowController.show()
            case "openWebsite":
                if let url = URL(string: "https://grwlab.net") {
                    NSWorkspace.shared.open(url)
                }
            case "resizeWindow":
                if let height = body["height"] as? Double {
                    self.resizeToContentHeight(height)
                } else if let height = body["height"] as? Int {
                    self.resizeToContentHeight(Double(height))
                }
            default:
                break
            }
        }
    }

    private func resizeToContentHeight(_ contentHeight: CGFloat) {
        guard let window, let screen = window.screen ?? NSScreen.main else { return }
        let chrome = window.frame.height - window.contentView!.frame.height
        let maxContent = min(screen.visibleFrame.height * 0.92, 920) - chrome
        let minContent: CGFloat = 320
        let clamped = max(minContent, min(maxContent, contentHeight))
        let newFrameHeight = clamped + chrome
        guard abs(window.frame.height - newFrameHeight) > 2 else { return }
        var frame = window.frame
        let delta = newFrameHeight - frame.height
        frame.size.height = newFrameHeight
        frame.origin.y -= delta
        window.setFrame(frame, display: true, animate: true)
    }

    private func pickApplication(completion: @escaping (AppRecord) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "اختر تطبيقًا"
        panel.message = "اختر تطبيقًا من مجلد Applications"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let name = url.deletingPathExtension().lastPathComponent
            let bundleId = Bundle(url: url)?.bundleIdentifier ?? url.path
            completion(AppRecord(bundleId: bundleId, name: name))
        }
    }
}
