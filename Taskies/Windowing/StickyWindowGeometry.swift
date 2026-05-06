import AppKit

enum StickyWindowGeometry {
    static func placeNew(_ note: StickyNote, existingWindowCount: Int) {
        let offset = CGFloat((existingWindowCount % 8) * 28)
        let size = StickyMetrics.defaultWindowSize
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 900, height: 700)

        note.windowW = size.width
        note.windowH = size.height
        note.expandedHeight = size.height
        note.windowX = visibleFrame.minX + 72 + offset
        note.windowY = visibleFrame.maxY - size.height - 72 - offset
    }

    static func applyResizeLimits(to window: NSWindow, isCollapsed: Bool) {
        if isCollapsed {
            window.minSize = NSSize(width: StickyMetrics.minCollapsedWidth, height: StickyNote.collapsedHeight)
            window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: StickyNote.collapsedHeight)
        } else {
            window.minSize = StickyMetrics.minWindowSize
            window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
    }

    static func applyState(to window: NSWindow, from note: StickyNote) {
        window.level = note.isPinned ? .floating : .normal
        window.alphaValue = note.isTranslucent ? 0.86 : 1.0
    }
}
