import AppKit

final class StickyPanel: NSPanel {
    var stickyNote: StickyNote?
    var windowDelegate: StickyWindowDelegate?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
