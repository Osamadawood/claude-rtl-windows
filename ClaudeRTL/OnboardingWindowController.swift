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
    private var axStatusTimer: Timer?
    private var armedObserver: NSObjectProtocol?

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 680),
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

        armedObserver = NotificationCenter.default.addObserver(
            forName: .selectionMonitorEventTapArmed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pushAxStatusToWebView()
        }

        guard let url = Bundle.main.url(forResource: "onboarding", withExtension: "html") else {
            DebugLog.print("ERROR: onboarding.html not found in bundle")
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    deinit {
        axStatusTimer?.invalidate()
        if let armedObserver {
            NotificationCenter.default.removeObserver(armedObserver)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DebugLog.print("onboarding.html loaded")
        startAxStatusUpdates()
    }

    private func startAxStatusUpdates() {
        axStatusTimer?.invalidate()
        axStatusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pushAxStatusToWebView()
        }
        if let axStatusTimer {
            RunLoop.main.add(axStatusTimer, forMode: .common)
        }
        pushAxStatusToWebView()
    }

    private func pushAxStatusToWebView() {
        let trusted = SelectionMonitor.isAccessibilityTrusted
        let armed = SelectionMonitor.shared.isEventTapArmed
        let js = "window.setAxStatus && window.setAxStatus(\(trusted), \(armed))"
        webView?.evaluateJavaScript(js, completionHandler: nil)
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
            case "openAccessibility":
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
                SelectionMonitor.shared.refreshAccessibilityStatus()
            case "relaunch":
                self.relaunchApp()
            case "finish":
                Settings.shared.didOnboard = true
                self.axStatusTimer?.invalidate()
                self.window?.close()
            default:
                break
            }
        }
    }

    private func relaunchApp() {
        let url = Bundle.main.bundleURL
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            NSApp.terminate(nil)
        }
    }
}
