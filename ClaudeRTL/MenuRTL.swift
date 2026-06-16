import AppKit

enum MenuRTL {
    static func configure(_ menu: NSMenu) {
        menu.userInterfaceLayoutDirection = .rightToLeft
    }

    static func item(
        _ title: String,
        action: Selector?,
        target: AnyObject?,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: action, keyEquivalent: keyEquivalent)
        item.target = target
        item.attributedTitle = attributedTitle(title)
        item.userInterfaceLayoutDirection = .rightToLeft
        return item
    }

    static func submenuItem(_ title: String, action: Selector?, target: AnyObject?) -> NSMenuItem {
        item(title, action: action, target: target)
    }

    static func setTitle(_ item: NSMenuItem, _ title: String) {
        item.attributedTitle = attributedTitle(title)
    }

    static func attributedTitle(_ title: String) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.baseWritingDirection = .rightToLeft
        style.alignment = .right
        return NSAttributedString(
            string: title,
            attributes: [
                .paragraphStyle: style,
                .font: NSFont.menuFont(ofSize: NSFont.systemFontSize),
            ]
        )
    }
}
