import AppKit
import WebKit

final class ClickableWebView: WKWebView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class DragHandle: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

final class BubblePanel: NSPanel {
    private var webView: ClickableWebView!
    private var dragHandle: DragHandle!
    private var anchorPoint = NSPoint.zero
    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?
    private var arrowPointsDown = false

    var onClose: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        hidesOnDeactivate = false
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovable = true
        isMovableByWindowBackground = false

        setupWebView()
        setupDragHandle()

        Speech.shared.onSpeakingChanged = { speaking in
            BubbleRenderer.shared.setSpeaking(speaking)
            if !speaking {
                BubbleRenderer.shared.clearHighlight()
            }
        }
        Speech.shared.onSpeakRange = { location, length in
            BubbleRenderer.shared.highlightRange(location: location, length: length)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let controller = WKUserContentController()
        controller.add(BubbleRenderer.shared, name: "bridge")
        config.userContentController = controller

        webView = ClickableWebView(frame: contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = BubbleRenderer.shared
        contentView?.addSubview(webView)

        BubbleRenderer.shared.panel = self
        BubbleRenderer.shared.load(into: webView)
    }

    private func setupDragHandle() {
        dragHandle = DragHandle(frame: .zero)
        dragHandle.wantsLayer = true
        dragHandle.layer?.backgroundColor = NSColor.clear.cgColor
        contentView?.addSubview(dragHandle, positioned: .above, relativeTo: webView)
        updateDragHandleFrame()
    }

    private func updateDragHandleFrame() {
        let h = contentView?.bounds.height ?? frame.height
        // RTL header: brand sits on the visual left — drag from that strip, not over buttons.
        dragHandle.frame = NSRect(x: 14, y: h - 48, width: 190, height: 36)
        dragHandle.autoresizingMask = [.width, .minYMargin]
    }

    func show(at point: NSPoint, text: String) {
        anchorPoint = Self.appKitPoint(from: point)
        let origin = clampedOrigin(for: frame.size, anchor: anchorPoint, arrowBelow: &arrowPointsDown)
        setFrameOrigin(origin)
        DebugLog.print("SHOW bubble at \(anchorPoint), panel frame \(frame)")

        BubbleRenderer.shared.show(text: text, arrowBelow: arrowPointsDown) { [weak self] in
            guard let self else { return }
            self.orderFrontRegardless()
            self.installMonitors()
            DebugLog.print("SHOW bubble at \(self.anchorPoint), panel frame \(self.frame)")
        }
    }

    func hide() {
        Speech.shared.stop()
        removeMonitors()
        orderOut(nil)
        onClose?()
    }

    func handleResize(width: CGFloat, height: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let size = NSSize(width: max(width, 120), height: max(height, 80))
            self.setContentSize(size)
            self.updateDragHandleFrame()
            var below = self.arrowPointsDown
            self.setFrameOrigin(self.clampedOrigin(for: size, anchor: self.anchorPoint, arrowBelow: &below))
            self.arrowPointsDown = below
        }
    }

    // MARK: - Positioning

    /// Converts a point that may be in Quartz top-left global coords to AppKit bottom-left.
    static func appKitPoint(from point: NSPoint) -> NSPoint {
        if NSScreen.screens.contains(where: { $0.frame.contains(point) }) {
            return point
        }
        guard let main = NSScreen.main else { return NSEvent.mouseLocation }
        let flipped = NSPoint(x: point.x, y: main.frame.maxY - point.y + main.frame.minY)
        if NSScreen.screens.contains(where: { $0.frame.contains(flipped) }) {
            return flipped
        }
        return NSEvent.mouseLocation
    }

    private func clampedOrigin(for size: NSSize, anchor: NSPoint, arrowBelow: inout Bool) -> NSPoint {
        let margin: CGFloat = 12
        let screen = NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main!
        let vf = screen.visibleFrame

        var x = anchor.x - 20
        var y = anchor.y - size.height - 14
        arrowBelow = false

        if y < vf.minY + margin {
            y = anchor.y + 14
            arrowBelow = true
        }

        x = min(max(x, vf.minX + margin), vf.maxX - size.width - margin)
        y = min(max(y, vf.minY + margin), vf.maxY - size.height - margin)

        return NSPoint(x: x, y: y)
    }

    private func installMonitors() {
        removeMonitors()

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.hide()
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }
            if event.keyCode == 53 {
                self.hide()
                return nil
            }
            return event
        }
    }

    private func removeMonitors() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }
}

final class BubbleRenderer: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    static let shared = BubbleRenderer()

    weak var panel: BubblePanel?
    private weak var webView: WKWebView?
    private(set) var currentText = ""

    private override init() {
        super.init()
    }

    func load(into webView: WKWebView) {
        self.webView = webView
        guard let url = Bundle.main.url(forResource: "bubble", withExtension: "html") else {
            DebugLog.print("ERROR: bubble.html not found in bundle — add Resources/bubble.html to Copy Bundle Resources")
            return
        }
        DebugLog.print("bubble.html path: \(url.path)")
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DebugLog.print("bubble.html loaded")
    }

    func show(text: String, arrowBelow: Bool, completion: @escaping () -> Void) {
        currentText = text
        guard let webView else { return }
        guard let json = try? JSONEncoder().encode(text),
              let jsonString = String(data: json, encoding: .utf8) else { return }

        let js = "window.showBubble(\(jsonString), \(Int(Settings.shared.fontSize)), \(arrowBelow))"
        webView.evaluateJavaScript(js) { _, error in
            if let error {
                NSLog("ClaudeRTL: showBubble error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { completion() }
        }
    }

    func setSpeaking(_ speaking: Bool) {
        guard let webView else { return }
        webView.evaluateJavaScript("window.setSpeaking(\(speaking))", completionHandler: nil)
    }

    func highlightRange(location: Int, length: Int) {
        guard let webView else { return }
        webView.evaluateJavaScript("window.highlightRange(\(location), \(length))", completionHandler: nil)
    }

    func clearHighlight() {
        guard let webView else { return }
        webView.evaluateJavaScript("window.clearHighlight()", completionHandler: nil)
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
            case "copy":
                if let text = body["text"] as? String {
                    Clipboard.write(text)
                }
            case "speak":
                if let text = body["text"] as? String {
                    Speech.shared.toggle(text)
                } else {
                    Speech.shared.toggle(self.currentText)
                }
            case "close":
                self.panel?.hide()
            case "resize":
                if let w = body["w"] as? Double, let h = body["h"] as? Double {
                    self.panel?.handleResize(width: w, height: h)
                }
            default:
                break
            }
        }
    }
}
