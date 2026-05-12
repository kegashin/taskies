import AppKit
import Observation

enum StickyArrangeMode {
    case title
    case color
    case createdAt
}

struct StickyWindowMenuItem: Identifiable {
    let id: UUID
    let title: String
    let color: StickyColor
    let isActive: Bool

    var menuTitle: String {
        "\(isActive ? "✓ " : "")\(title)"
    }

    var systemImageName: String {
        switch color {
        case .yellow: return "note.text"
        case .blue: return "rectangle.fill"
        case .green: return "rectangle.fill"
        case .pink: return "rectangle.fill"
        case .purple: return "rectangle.fill"
        case .gray: return "rectangle.fill"
        }
    }
}

@MainActor
@Observable
final class StickyWindowCoordinator {
    static let shared = StickyWindowCoordinator()

    var activeNoteId: UUID?

    var stickyWindows: [UUID: NSWindow] = [:]
    var stickyNotes: [UUID: StickyNote] = [:]
    var store: StickyStore?
    private var startupIssue: StickyStoreStartupIssue?
    let windowDefaults = StickyWindowDefaults()

    private init() {}

    func configure(store: StickyStore, startupIssue: StickyStoreStartupIssue? = nil) {
        self.store = store
        self.startupIssue = startupIssue
    }

    func window(for noteId: UUID) -> NSWindow? {
        stickyWindows[noteId]
    }

    var hasActiveSticky: Bool {
        activePanel?.stickyNote != nil
    }

    var activeStickyColor: StickyColor? {
        activePanel?.stickyNote?.color
    }

    var hasAnySticky: Bool {
        !stickyNotes.isEmpty
    }

    var windowMenuItems: [StickyWindowMenuItem] {
        stickyNotes.values
            .sorted { $0.createdAt < $1.createdAt }
            .map { note in
                StickyWindowMenuItem(
                    id: note.id,
                    title: note.displayTitle,
                    color: note.color,
                    isActive: note.id == activeNoteId
                )
            }
    }

    func createNewSticky() {
        guard let store else { return }

        do {
            let note = try store.createNote { note in
                StickyWindowGeometry.placeNew(note, existingWindowCount: stickyWindows.count)
                windowDefaults.apply(to: note)
            }
            openWindow(for: note)
        } catch {
            StickyLog.windowing.error("Failed to create sticky: \(error.localizedDescription, privacy: .public)")
        }
    }

    func restoreAllWindows() {
        guard let store else { return }

        do {
            let notes = try store.fetchNotes()
            if notes.isEmpty {
                createNewSticky()
                return
            }

            let didNormalizeLegacyState = notes.reduce(false) { didNormalize, note in
                StickyWindowLegacyNormalizer.normalize(note) || didNormalize
            }

            if didNormalizeLegacyState {
                store.saveIgnoringErrors("Failed to save normalized notes")
            }

            for note in notes {
                openWindow(for: note, normalizesLegacyState: false)
            }
        } catch {
            StickyLog.windowing.error("Failed to fetch sticky notes: \(error.localizedDescription, privacy: .public)")
        }
    }

    func openWindow(for note: StickyNote) {
        openWindow(for: note, normalizesLegacyState: true)
    }

    private func openWindow(for note: StickyNote, normalizesLegacyState: Bool) {
        guard let store else { return }

        if normalizesLegacyState && StickyWindowLegacyNormalizer.normalize(note) {
            store.saveIgnoringErrors("Failed to save normalized note")
        }

        if let existingWindow = stickyWindows[note.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        stickyNotes[note.id] = note

        let panel = StickyWindowFactory.makeWindow(
            note: note,
            store: store,
            coordinator: self
        ) { [weak self] id in
            self?.stickyWindows.removeValue(forKey: id)
            self?.stickyNotes.removeValue(forKey: id)
        }

        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        stickyWindows[note.id] = panel
    }

    func showAllStickies() {
        for window in stickyWindows.values {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideAllStickies() {
        for window in stickyWindows.values {
            window.orderOut(nil)
        }
        activeNoteId = nil
    }

    func hideActiveSticky() {
        guard let panel = activePanel else { return }
        let noteId = panel.stickyNote?.id
        panel.orderOut(nil)
        if activeNoteId == noteId {
            activeNoteId = nil
        }
    }

    func hideSticky(id: UUID) {
        stickyWindows[id]?.orderOut(nil)
        if activeNoteId == id {
            activeNoteId = nil
        }
    }

    func showSticky(id: UUID) {
        stickyWindows[id]?.makeKeyAndOrderFront(nil)
    }

    func presentStartupIssueIfNeeded() {
        guard let startupIssue else { return }
        self.startupIssue = nil

        let alert = NSAlert()
        alert.messageText = startupIssue.alertMessage
        alert.informativeText = startupIssue.alertInformativeText
        alert.alertStyle = .warning

        alert.addButton(withTitle: "Continue")
        let openFolderResponse: NSApplication.ModalResponse?
        if startupIssue.dataDirectory != nil {
            alert.addButton(withTitle: "Open Data Folder")
            openFolderResponse = .alertSecondButtonReturn
        } else {
            openFolderResponse = nil
        }
        alert.addButton(withTitle: "Quit")
        let quitResponse: NSApplication.ModalResponse = openFolderResponse == nil
            ? .alertSecondButtonReturn
            : .alertThirdButtonReturn

        let response = alert.runModal()

        if response == openFolderResponse,
           let directory = startupIssue.dataDirectory {
            NSWorkspace.shared.open(directory)
        } else if response == quitResponse {
            NSApp.terminate(nil)
        }
    }

    func activateSticky(id: UUID) {
        activeNoteId = id
    }

    func deactivateSticky(id: UUID) {
        guard activeNoteId == id else { return }
        if stickyWindows[id]?.isVisible == true { return }
        activeNoteId = nil
    }

    func minimizeActiveSticky() {
        activePanel?.miniaturize(nil)
    }

    func zoomActiveSticky() {
        activePanel?.zoom(nil)
    }

    func fillActiveSticky() {
        guard let window = activePanel else { return }

        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        guard let visibleFrame else { return }

        window.setFrame(visibleFrame, display: true, animate: true)
    }

    func centerActiveSticky() {
        guard let window = activePanel else { return }
        window.center()
    }

    func toggleCollapse(for noteId: UUID) {
        guard let note = stickyNotes[noteId] else { return }

        if note.isCollapsed {
            expandWindow(for: noteId)
        } else {
            collapseWindow(for: noteId)
        }
    }

    func zoomWindow(for noteId: UUID) {
        stickyWindows[noteId]?.zoom(nil)
    }

    var activePanel: StickyPanel? {
        if let keyPanel = NSApp.keyWindow as? StickyPanel {
            return keyPanel
        }

        guard let activeNoteId,
              let panel = stickyWindows[activeNoteId] as? StickyPanel,
              panel.isVisible else {
            return nil
        }

        return panel
    }

    func presentError(message: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.runModal()
    }

    func closeSticky(id: UUID, savesFrameOnClose: Bool = true) {
        if let window = stickyWindows[id] {
            if let panel = window as? StickyPanel {
                panel.windowDelegate?.savesFrameOnClose = savesFrameOnClose
            }
            window.close()
            stickyWindows.removeValue(forKey: id)
            stickyNotes.removeValue(forKey: id)
            if activeNoteId == id {
                activeNoteId = nil
            }
        }
    }

    private func collapseWindow(for noteId: UUID) {
        guard let window = stickyWindows[noteId],
              let note = stickyNotes[noteId],
              let delegate = (window as? StickyPanel)?.windowDelegate else {
            return
        }

        delegate.isAnimating = true

        let currentFrame = window.frame
        let topY = currentFrame.origin.y + currentFrame.height
        let newHeight = StickyNote.collapsedHeight
        let newY = topY - newHeight

        note.expandedHeight = currentFrame.height
        note.isCollapsed = true
        note.windowY = newY

        window.setFrame(
            NSRect(
                x: currentFrame.origin.x,
                y: newY,
                width: currentFrame.width,
                height: newHeight
            ),
            display: true
        )
        StickyWindowGeometry.applyResizeLimits(to: window, isCollapsed: true)

        delegate.isAnimating = false
        store?.saveIgnoringErrors("Failed to save collapsed state")
    }

    private func expandWindow(for noteId: UUID) {
        guard let window = stickyWindows[noteId],
              let note = stickyNotes[noteId],
              let delegate = (window as? StickyPanel)?.windowDelegate else {
            return
        }

        delegate.isAnimating = true

        let currentFrame = window.frame
        let topY = currentFrame.origin.y + currentFrame.height
        let newHeight = max(note.expandedHeight, Double(StickyMetrics.minWindowSize.height))
        let newY = topY - newHeight

        note.isCollapsed = false
        note.windowY = newY
        note.windowH = newHeight
        note.expandedHeight = newHeight

        StickyWindowGeometry.applyResizeLimits(to: window, isCollapsed: false)
        window.setFrame(
            NSRect(
                x: currentFrame.origin.x,
                y: newY,
                width: currentFrame.width,
                height: newHeight
            ),
            display: true
        )

        delegate.isAnimating = false
        store?.saveIgnoringErrors("Failed to save expanded state")
    }
}
