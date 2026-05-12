import AppKit

@MainActor
final class StickyWindowDelegate: NSObject, NSWindowDelegate {
    let stickyNote: StickyNote
    let store: StickyStore
    let onClose: (UUID) -> Void
    let onBecomeKey: (UUID) -> Void
    let onResignKey: (UUID) -> Void
    var isAnimating = false
    var savesFrameOnClose = true

    private var pendingSaveTask: Task<Void, Never>?
    private var pendingFrame: NSRect?

    init(
        stickyNote: StickyNote,
        store: StickyStore,
        onClose: @escaping (UUID) -> Void,
        onBecomeKey: @escaping (UUID) -> Void,
        onResignKey: @escaping (UUID) -> Void
    ) {
        self.stickyNote = stickyNote
        self.store = store
        self.onClose = onClose
        self.onBecomeKey = onBecomeKey
        self.onResignKey = onResignKey
    }

    deinit {
        pendingSaveTask?.cancel()
    }

    func windowDidMove(_ notification: Notification) {
        guard !isAnimating else { return }
        saveWindowFrame(notification, immediately: false)
    }

    func windowDidResize(_ notification: Notification) {
        guard !isAnimating else { return }
        saveWindowFrame(notification, immediately: false)
    }

    func windowWillClose(_ notification: Notification) {
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        pendingFrame = nil
        if savesFrameOnClose {
            saveWindowFrame(notification, immediately: true)
        }
        onClose(stickyNote.id)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        onBecomeKey(stickyNote.id)
    }

    func windowDidResignKey(_ notification: Notification) {
        onResignKey(stickyNote.id)
    }

    private func saveWindowFrame(_ notification: Notification, immediately: Bool) {
        guard let window = notification.object as? NSWindow else { return }

        if immediately {
            commitWindowFrame(window.frame)
            return
        }

        pendingFrame = window.frame
        scheduleSave()
    }

    private func commitWindowFrame(_ frame: NSRect) {
        let windowX = Double(frame.origin.x)
        let windowY = Double(frame.origin.y)
        let windowW = Double(frame.size.width)
        let windowH = Double(frame.size.height)

        var didChange = stickyNote.windowX != windowX
            || stickyNote.windowY != windowY
            || stickyNote.windowW != windowW

        stickyNote.windowX = windowX
        stickyNote.windowY = windowY
        stickyNote.windowW = windowW

        if !stickyNote.isCollapsed {
            didChange = didChange
                || stickyNote.windowH != windowH
                || stickyNote.expandedHeight != windowH
            stickyNote.windowH = windowH
            stickyNote.expandedHeight = windowH
        }

        guard didChange else { return }

        stickyNote.touch()
        store.saveIgnoringErrors("Failed to save window frame")
    }

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            self?.flushPendingFrame()
        }
    }

    private func flushPendingFrame() {
        pendingSaveTask = nil
        guard let pendingFrame else { return }
        self.pendingFrame = nil
        commitWindowFrame(pendingFrame)
    }
}
