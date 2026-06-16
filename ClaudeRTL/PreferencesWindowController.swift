import AppKit

final class PreferencesWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    private static var sharedInstance: PreferencesWindowController?

    static func show() {
        if sharedInstance == nil {
            sharedInstance = PreferencesWindowController()
        }
        sharedInstance?.reloadFromSettings()
        sharedInstance?.showWindow(nil)
        sharedInstance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var modeButtons: [TriggerMode: NSButton] = [:]
    private var customSection: NSView!
    private var excludedTable: NSTableView!
    private var includedTable: NSTableView!
    private var bundleIDField: NSTextField!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "إعدادات Claude RTL"
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
        let root = FlippedView(frame: NSRect(x: 0, y: 0, width: 480, height: 520))
        root.userInterfaceLayoutDirection = .rightToLeft

        var y: CGFloat = 16

        let modeLabel = label("وضع التشغيل", bold: true)
        modeLabel.frame = NSRect(x: 20, y: y, width: 440, height: 20)
        root.addSubview(modeLabel)
        y += 28

        for mode in TriggerMode.allCases {
            let btn = NSButton(radioButtonWithTitle: mode.label, target: self, action: #selector(triggerModeChanged(_:)))
            btn.frame = NSRect(x: 36, y: y, width: 420, height: 22)
            btn.tag = TriggerMode.allCases.firstIndex(of: mode) ?? 0
            root.addSubview(btn)
            modeButtons[mode] = btn
            y += 26
        }
        y += 8

        let excludedLabel = label("التطبيقات المستثناة دائمًا", bold: true)
        excludedLabel.frame = NSRect(x: 20, y: y, width: 440, height: 20)
        root.addSubview(excludedLabel)
        y += 24

        excludedTable = makeTableView()
        excludedTable.frame = NSRect(x: 20, y: y, width: 440, height: 100)
        root.addSubview(scrollView(for: excludedTable))
        y += 108

        let removeExcluded = NSButton(title: "إزالة المحدّد", target: self, action: #selector(removeSelectedExcluded))
        removeExcluded.bezelStyle = .rounded
        removeExcluded.frame = NSRect(x: 20, y: y, width: 120, height: 28)
        root.addSubview(removeExcluded)
        y += 40

        customSection = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 200))
        var cy: CGFloat = 0

        let includedLabel = label("التطبيقات المسموح بها (قائمة مخصّصة)", bold: true)
        includedLabel.frame = NSRect(x: 20, y: cy, width: 440, height: 20)
        customSection.addSubview(includedLabel)
        cy += 24

        includedTable = makeTableView()
        includedTable.frame = NSRect(x: 20, y: cy, width: 440, height: 80)
        customSection.addSubview(scrollView(for: includedTable))
        cy += 88

        bundleIDField = NSTextField(string: "")
        bundleIDField.placeholderString = "com.example.app"
        bundleIDField.frame = NSRect(x: 20, y: cy, width: 280, height: 24)
        customSection.addSubview(bundleIDField)

        let addFront = NSButton(title: "إضافة الأمامي", target: self, action: #selector(addFrontmostApp))
        addFront.bezelStyle = .rounded
        addFront.frame = NSRect(x: 310, y: cy - 2, width: 70, height: 28)
        customSection.addSubview(addFront)

        let addID = NSButton(title: "إضافة", target: self, action: #selector(addBundleIDFromField))
        addID.bezelStyle = .rounded
        addID.frame = NSRect(x: 388, y: cy - 2, width: 72, height: 28)
        customSection.addSubview(addID)
        cy += 36

        let removeIncluded = NSButton(title: "إزالة المحدّد", target: self, action: #selector(removeSelectedIncluded))
        removeIncluded.bezelStyle = .rounded
        removeIncluded.frame = NSRect(x: 20, y: cy, width: 120, height: 28)
        customSection.addSubview(removeIncluded)

        customSection.frame = NSRect(x: 0, y: y, width: 480, height: cy + 36)
        root.addSubview(customSection)
        y += customSection.frame.height + 8

        let done = NSButton(title: "تم", target: self, action: #selector(closeWindow))
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"
        done.frame = NSRect(x: 200, y: y, width: 80, height: 32)
        root.addSubview(done)

        return root
    }

    private func label(_ text: String, bold: Bool = false) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = bold ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
        field.alignment = .right
        return field
    }

    private func makeTableView() -> NSTableView {
        let table = NSTableView(frame: .zero)
        table.headerView = nil
        table.rowHeight = 22
        table.usesAlternatingRowBackgroundColors = true
        table.dataSource = self
        table.delegate = self
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("id"))
        col.title = "Bundle ID"
        col.width = 420
        table.addTableColumn(col)
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        return table
    }

    private func scrollView(for table: NSTableView) -> NSScrollView {
        let scroll = NSScrollView(frame: table.frame)
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.documentView = table
        return scroll
    }

    func reloadFromSettings() {
        let mode = Settings.shared.triggerMode
        for (m, btn) in modeButtons {
            btn.state = (m == mode) ? .on : .off
        }
        customSection.isHidden = mode != .customList
        excludedTable.reloadData()
        includedTable.reloadData()
    }

    @objc private func triggerModeChanged(_ sender: NSButton) {
        for (mode, btn) in modeButtons {
            if btn === sender {
                Settings.shared.triggerMode = mode
                btn.state = .on
            } else {
                btn.state = .off
            }
        }
        customSection.isHidden = Settings.shared.triggerMode != .customList
    }

    @objc private func removeSelectedExcluded() {
        let row = excludedTable.selectedRow
        guard row >= 0 else { return }
        let id = Settings.shared.excludedBundleIDsAlways[row]
        Settings.shared.removeExcludedPermanently(id)
        excludedTable.reloadData()
    }

    @objc private func removeSelectedIncluded() {
        let row = includedTable.selectedRow
        guard row >= 0 else { return }
        let id = Settings.shared.includedBundleIDs[row]
        Settings.shared.removeIncludedBundleID(id)
        includedTable.reloadData()
    }

    @objc private func addFrontmostApp() {
        guard let bid = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        Settings.shared.addIncludedBundleID(bid)
        includedTable.reloadData()
    }

    @objc private func addBundleIDFromField() {
        let bid = bundleIDField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bid.isEmpty else { return }
        Settings.shared.addIncludedBundleID(bid)
        bundleIDField.stringValue = ""
        includedTable.reloadData()
    }

    @objc private func closeWindow() {
        window?.close()
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === excludedTable {
            return Settings.shared.excludedBundleIDsAlways.count
        }
        return Settings.shared.includedBundleIDs.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableView === excludedTable {
            return Settings.shared.excludedBundleIDsAlways[row]
        }
        return Settings.shared.includedBundleIDs[row]
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
