import AppKit

@MainActor
final class StickyColorMenuController: NSObject, NSMenuDelegate {
    static let shared = StickyColorMenuController()

    private let menu = NSMenu(title: "Color")

    private override init() {
        super.init()
        menu.autoenablesItems = false
        menu.delegate = self
    }

    func install() {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }

        let menuItem: NSMenuItem
        let needsInsert: Bool

        if let existingItem = mainMenu.item(withTitle: "Color") {
            menuItem = existingItem
            needsInsert = false
        } else {
            menuItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
            needsInsert = true
        }

        let isInstalled = menuItem.submenu === menu
        menuItem.submenu = menu

        if isInstalled, !menu.items.isEmpty {
            return
        }

        if needsInsert {
            if let windowIndex = mainMenu.items.firstIndex(where: { $0.title == "Window" }) {
                mainMenu.insertItem(menuItem, at: windowIndex)
            } else if let helpIndex = mainMenu.items.firstIndex(where: { $0.title == "Help" }) {
                mainMenu.insertItem(menuItem, at: helpIndex)
            } else {
                mainMenu.addItem(menuItem)
            }
        }

        if menu.items.isEmpty {
            rebuildItems()
        } else {
            updateItems()
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateItems()
    }

    @objc private func setColor(_ sender: NSMenuItem) {
        guard let color = sender.representedObject as? StickyColor else { return }
        StickyWindowCoordinator.shared.setColorForActiveSticky(color)
        updateItems()
    }

    private func rebuildItems() {
        menu.removeAllItems()

        for color in StickyColor.allCases {
            let item = NSMenuItem(
                title: color.displayName,
                action: #selector(setColor(_:)),
                keyEquivalent: keyEquivalent(for: color)
            )
            item.keyEquivalentModifierMask = [.command]
            item.target = self
            item.representedObject = color
            item.image = swatchImage(for: color)
            menu.addItem(item)
        }

        updateItems()
    }

    private func updateItems() {
        let coordinator = StickyWindowCoordinator.shared

        for item in menu.items {
            guard let color = item.representedObject as? StickyColor else { continue }
            item.isEnabled = coordinator.hasActiveSticky
            item.state = coordinator.activeStickyColor == color ? .on : .off
        }
    }

    private func keyEquivalent(for color: StickyColor) -> String {
        switch color {
        case .yellow: return "1"
        case .blue: return "2"
        case .green: return "3"
        case .pink: return "4"
        case .purple: return "5"
        case .gray: return "6"
        }
    }

    private func swatchImage(for color: StickyColor) -> NSImage {
        let size = NSSize(width: 38, height: 14)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor(color.palette.paperTop).setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()

        image.isTemplate = false
        return image
    }
}
