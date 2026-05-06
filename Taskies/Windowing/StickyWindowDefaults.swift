import AppKit
import Foundation

struct StickyWindowDefaults {
    private enum Key {
        static let color = "Taskies.defaultSticky.color"
        static let width = "Taskies.defaultSticky.width"
        static let height = "Taskies.defaultSticky.height"
        static let pinned = "Taskies.defaultSticky.pinned"
        static let translucent = "Taskies.defaultSticky.translucent"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func apply(to note: StickyNote) {
        if let rawColor = defaults.string(forKey: Key.color),
           let color = StickyColor(rawValue: rawColor) {
            note.color = color
        }

        let width = defaults.double(forKey: Key.width)
        let height = defaults.double(forKey: Key.height)

        if width >= Double(StickyMetrics.minWindowSize.width),
           height >= Double(StickyMetrics.minWindowSize.height) {
            note.windowW = width
            note.windowH = height
            note.expandedHeight = height
        }

        note.isPinned = defaults.bool(forKey: Key.pinned)
        note.isTranslucent = defaults.bool(forKey: Key.translucent)
    }

    func save(from note: StickyNote, windowFrame: NSRect) {
        defaults.set(note.color.rawValue, forKey: Key.color)
        defaults.set(windowFrame.width, forKey: Key.width)
        defaults.set(note.isCollapsed ? note.expandedHeight : windowFrame.height, forKey: Key.height)
        defaults.set(note.isPinned, forKey: Key.pinned)
        defaults.set(note.isTranslucent, forKey: Key.translucent)
    }
}
