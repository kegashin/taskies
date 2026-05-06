import AppKit

@MainActor
enum StickyMenuItemFactory {
    static func makeItem(
        _ title: String,
        systemImage: String? = nil,
        action: Selector,
        keyEquivalent: String = "",
        modifiers: NSEvent.ModifierFlags = [.command],
        tag: Int = 0,
        target: AnyObject? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = keyEquivalent.isEmpty ? [] : modifiers
        item.target = target
        item.tag = tag
        item.image = systemImage.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: title) }
        item.image?.isTemplate = true
        return item
    }

    static func makeSubmenuItem(_ title: String, submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }
}
