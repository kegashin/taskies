import AppKit

@MainActor
final class StickyFileMenuController: NSObject, NSMenuDelegate {
    static let shared = StickyFileMenuController()

    private enum ItemTag {
        static let close = 1
        static let exportText = 2
        static let exportAll = 3
        static let print = 4
    }

    private let menu = NSMenu(title: "File")

    private override init() {
        super.init()
        menu.autoenablesItems = false
        menu.delegate = self
    }

    func install() {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }

        let fileItem: NSMenuItem
        let needsInsert: Bool

        if let existingItem = mainMenu.item(withTitle: "File") {
            fileItem = existingItem
            needsInsert = false
        } else {
            fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
            needsInsert = true
        }

        let isInstalled = fileItem.submenu === menu
        fileItem.submenu = menu

        if needsInsert {
            mainMenu.insertItem(fileItem, at: min(1, mainMenu.items.count))
        }

        if isInstalled, !menu.items.isEmpty {
            return
        } else if menu.items.isEmpty {
            rebuildItems()
        } else {
            updateItems()
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateItems()
    }

    @objc private func newNote(_ sender: NSMenuItem) {
        StickyWindowCoordinator.shared.createNewSticky()
    }

    @objc private func closeNote(_ sender: NSMenuItem) {
        StickyWindowCoordinator.shared.hideActiveSticky()
    }

    @objc private func importText(_ sender: NSMenuItem) {
        StickyWindowCoordinator.shared.importTextFile()
    }

    @objc private func exportText(_ sender: NSMenuItem) {
        StickyWindowCoordinator.shared.exportActiveStickyText()
    }

    @objc private func exportAll(_ sender: NSMenuItem) {
        StickyWindowCoordinator.shared.exportAllStickiesToNotes()
    }

    @objc private func printNote(_ sender: NSMenuItem) {
        StickyWindowCoordinator.shared.printActiveSticky()
    }

    private func rebuildItems() {
        menu.removeAllItems()
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "New Note",
                systemImage: "plus",
                action: #selector(newNote(_:)),
                keyEquivalent: "n",
                target: self
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Close",
                systemImage: "xmark",
                action: #selector(closeNote(_:)),
                keyEquivalent: "w",
                tag: ItemTag.close,
                target: self
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Import Text...",
                systemImage: "square.and.arrow.down",
                action: #selector(importText(_:)),
                target: self
            )
        )
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Export Text...",
                systemImage: "square.and.arrow.up",
                action: #selector(exportText(_:)),
                tag: ItemTag.exportText,
                target: self
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Export All to Notes...",
                systemImage: "note.text",
                action: #selector(exportAll(_:)),
                tag: ItemTag.exportAll,
                target: self
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Print...",
                systemImage: "printer",
                action: #selector(printNote(_:)),
                keyEquivalent: "p",
                tag: ItemTag.print,
                target: self
            )
        )
        updateItems()
    }

    private func updateItems() {
        let coordinator = StickyWindowCoordinator.shared

        for item in menu.items {
            switch item.tag {
            case ItemTag.close, ItemTag.exportText, ItemTag.print:
                item.isEnabled = coordinator.hasActiveSticky
            case ItemTag.exportAll:
                item.isEnabled = coordinator.hasAnySticky
            default:
                item.isEnabled = true
            }
        }
    }
}
