import AppKit

@MainActor
final class StickyFontMenuController: NSObject {
    static let shared = StickyFontMenuController()

    private let menu = NSMenu(title: "Font")

    private override init() {
        super.init()
    }

    func install() {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }

        let removedViewMenu = removeViewMenu(from: mainMenu)

        let menuItem: NSMenuItem
        let needsInsert: Bool

        if let existingItem = mainMenu.item(withTitle: "Font") {
            menuItem = existingItem
            needsInsert = false
        } else {
            menuItem = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
            needsInsert = true
        }

        let isInstalled = menuItem.submenu === menu
        menuItem.submenu = menu

        if isInstalled, !removedViewMenu, !menu.items.isEmpty {
            return
        }

        if needsInsert {
            let insertIndex = mainMenu.items.firstIndex { item in
                item.title == "Color" || item.title == "Window" || item.title == "Help"
            }

            if let insertIndex {
                mainMenu.insertItem(menuItem, at: insertIndex)
            } else {
                mainMenu.addItem(menuItem)
            }
        }

        if menu.items.isEmpty {
            rebuildItems()
        }

        NSFontManager.shared.setFontMenu(menu)
    }

    private func removeViewMenu(from mainMenu: NSMenu) -> Bool {
        var didRemove = false

        while let viewItem = mainMenu.item(withTitle: "View") {
            mainMenu.removeItem(viewItem)
            didRemove = true
        }

        return didRemove
    }

    private func rebuildItems() {
        menu.removeAllItems()
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Show Fonts",
                systemImage: "textformat",
                action: #selector(NSFontManager.orderFrontFontPanel(_:)),
                keyEquivalent: "t",
                target: NSFontManager.shared
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Bold",
                systemImage: "bold",
                action: #selector(NSFontManager.addFontTrait(_:)),
                keyEquivalent: "b",
                tag: Int(NSFontTraitMask.boldFontMask.rawValue),
                target: NSFontManager.shared
            )
        )
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Italic",
                systemImage: "italic",
                action: #selector(NSFontManager.addFontTrait(_:)),
                keyEquivalent: "i",
                tag: Int(NSFontTraitMask.italicFontMask.rawValue),
                target: NSFontManager.shared
            )
        )
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Underline",
                systemImage: "underline",
                action: NSSelectorFromString("underline:"),
                keyEquivalent: "u"
            )
        )
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Strikethrough",
                systemImage: "strikethrough",
                action: NSSelectorFromString("strikethrough:")
            )
        )
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Outline",
                systemImage: "circle.circle",
                action: NSSelectorFromString("outline:")
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Bigger",
                systemImage: "textformat.size.larger",
                action: #selector(NSFontManager.modifyFont(_:)),
                keyEquivalent: "+",
                tag: Int(NSFontAction.sizeUpFontAction.rawValue),
                target: NSFontManager.shared
            )
        )
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Smaller",
                systemImage: "textformat.size.smaller",
                action: #selector(NSFontManager.modifyFont(_:)),
                keyEquivalent: "-",
                tag: Int(NSFontAction.sizeDownFontAction.rawValue),
                target: NSFontManager.shared
            )
        )
        menu.addItem(.separator())
        menu.addItem(StickyMenuItemFactory.makeSubmenuItem("Kern", submenu: kernMenu()))
        menu.addItem(StickyMenuItemFactory.makeSubmenuItem("Ligature", submenu: ligatureMenu()))
        menu.addItem(StickyMenuItemFactory.makeSubmenuItem("Baseline", submenu: baselineMenu()))
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Show Colors",
                systemImage: "paintpalette",
                action: #selector(NSApplication.orderFrontColorPanel(_:)),
                keyEquivalent: "c",
                modifiers: [.command, .shift],
                target: NSApp
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Copy Style",
                systemImage: "doc.on.doc",
                action: NSSelectorFromString("copyFont:"),
                keyEquivalent: "c",
                modifiers: [.command, .option]
            )
        )
        menu.addItem(
            StickyMenuItemFactory.makeItem(
                "Paste Style",
                systemImage: "clipboard",
                action: NSSelectorFromString("pasteFont:"),
                keyEquivalent: "v",
                modifiers: [.command, .option]
            )
        )
    }

    private func kernMenu() -> NSMenu {
        let menu = NSMenu(title: "Kern")
        menu.addItem(StickyMenuItemFactory.makeItem("Use Default", action: NSSelectorFromString("useStandardKerning:")))
        menu.addItem(StickyMenuItemFactory.makeItem("Use None", action: NSSelectorFromString("turnOffKerning:")))
        menu.addItem(.separator())
        menu.addItem(StickyMenuItemFactory.makeItem("Tighten", action: NSSelectorFromString("tightenKerning:")))
        menu.addItem(StickyMenuItemFactory.makeItem("Loosen", action: NSSelectorFromString("loosenKerning:")))
        return menu
    }

    private func ligatureMenu() -> NSMenu {
        let menu = NSMenu(title: "Ligature")
        menu.addItem(StickyMenuItemFactory.makeItem("Use Default", action: NSSelectorFromString("useStandardLigatures:")))
        menu.addItem(StickyMenuItemFactory.makeItem("Use None", action: NSSelectorFromString("turnOffLigatures:")))
        menu.addItem(StickyMenuItemFactory.makeItem("Use All", action: NSSelectorFromString("useAllLigatures:")))
        return menu
    }

    private func baselineMenu() -> NSMenu {
        let menu = NSMenu(title: "Baseline")
        menu.addItem(StickyMenuItemFactory.makeItem("Use Default", action: NSSelectorFromString("unscript:")))
        menu.addItem(.separator())
        menu.addItem(StickyMenuItemFactory.makeItem("Superscript", action: NSSelectorFromString("superscript:")))
        menu.addItem(StickyMenuItemFactory.makeItem("Subscript", action: NSSelectorFromString("subscript:")))
        menu.addItem(.separator())
        menu.addItem(StickyMenuItemFactory.makeItem("Raise", action: NSSelectorFromString("raiseBaseline:")))
        menu.addItem(StickyMenuItemFactory.makeItem("Lower", action: NSSelectorFromString("lowerBaseline:")))
        return menu
    }
}
