import AppKit
import WebKit

final class OnboardingWindowController: NSWindowController, WKNavigationDelegate, WKScriptMessageHandler {
    private static var sharedInstance: OnboardingWindowController?

    static func showIfNeeded() {
        guard !Settings.shared.didOnboard else { return }
        show()
    }

    static func show() {
        if sharedInstance == nil {
            sharedInstance = OnboardingWindowController()
        }
        sharedInstance?.showWindow(nil)
        sharedInstance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private weak var webView: WKWebView?

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 580),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Claude RTL"
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

        guard let url = Bundle.main.url(forResource: "onboarding", withExtension: "html") else {
            DebugLog.print("ERROR: onboarding.html not found in bundle")
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DebugLog.print("onboarding.html loaded")
        applyTheme(ThemeManager.shared.effectiveTheme())
    }

    static func applyThemeIfVisible(_ theme: String) {
        sharedInstance?.applyTheme(theme)
    }

    private func applyTheme(_ theme: String) {
        let safe = theme == "light" ? "light" : "dark"
        webView?.evaluateJavaScript(
            "document.documentElement.setAttribute('data-theme', '\(safe)')",
            completionHandler: nil
        )
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "bridge",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        DispatchQueue.main.async {
            switch action {
            case "finish":
                Settings.shared.didOnboard = true
                self.window?.close()
                PreferencesWindowController.show()
            default:
                break
            }
        }
    }
}
