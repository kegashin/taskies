import AppKit
import Observation
import UniformTypeIdentifiers

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

    private var stickyWindows: [UUID: NSWindow] = [:]
    private var stickyNotes: [UUID: StickyNote] = [:]
    private var store: StickyStore?
    private let windowDefaults = StickyWindowDefaults()

    private init() {}

    func configure(store: StickyStore) {
        self.store = store
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
    }

    func hideActiveSticky() {
        activePanel?.orderOut(nil)
    }

    func hideSticky(id: UUID) {
        stickyWindows[id]?.orderOut(nil)
    }

    func showSticky(id: UUID) {
        stickyWindows[id]?.makeKeyAndOrderFront(nil)
    }

    func importTextFile() {
        guard let store else { return }

        let panel = NSOpenPanel()
        panel.title = "Import Text"
        panel.allowedContentTypes = [.plainText, .text]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK,
              let url = panel.url else {
            return
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let taskTexts = StickyTextDocument.taskTexts(from: text)
            var importedNote: StickyNote?

            try store.transaction {
                let note = store.insertNote { note in
                    StickyWindowGeometry.placeNew(note, existingWindowCount: stickyWindows.count)
                    windowDefaults.apply(to: note)
                    note.title = url.deletingPathExtension().lastPathComponent
                }

                for (index, line) in taskTexts.enumerated() {
                    let item = NoteItem(text: line, order: index)
                    item.note = note
                    note.items.append(item)
                    store.context.insert(item)
                }

                note.touch()
                importedNote = note
            }

            if let importedNote {
                openWindow(for: importedNote)
            }
        } catch {
            presentError(message: "Could not import text.", informativeText: error.localizedDescription)
        }
    }

    func exportActiveStickyText() {
        guard let note = activePanel?.stickyNote else { return }

        let panel = NSSavePanel()
        panel.title = "Export Text"
        panel.nameFieldStringValue = "\(note.displayTitle).txt"
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK,
              let url = panel.url else {
            return
        }

        do {
            try StickyTextDocument.exportedText(for: note)
                .write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentError(message: "Could not export text.", informativeText: error.localizedDescription)
        }
    }

    func exportAllStickiesToNotes() {
        let notes = stickyNotes.values.sorted { $0.createdAt < $1.createdAt }
        guard !notes.isEmpty else { return }

        let panel = NSSavePanel()
        panel.title = "Export All to Notes"
        panel.nameFieldStringValue = "Taskies Notes.txt"
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK,
              let url = panel.url else {
            return
        }

        let text = notes
            .map { StickyTextDocument.exportedText(for: $0) }
            .joined(separator: "\n\n---\n\n")

        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentError(message: "Could not export notes.", informativeText: error.localizedDescription)
        }
    }

    func printActiveSticky() {
        guard let contentView = activePanel?.contentView else { return }

        let operation = NSPrintOperation(view: contentView)
        operation.run()
    }

    func activateSticky(id: UUID) {
        activeNoteId = id
    }

    func deactivateSticky(id: UUID) {
        guard activeNoteId == id else { return }
        activeNoteId = nil
    }

    func requestDeleteActiveSticky() {
        guard let panel = activePanel,
              let note = panel.stickyNote else {
            return
        }

        requestDelete(note: note)
    }

    func promptRenameActiveSticky() {
        guard let note = activePanel?.stickyNote else { return }
        promptRenameSticky(id: note.id)
    }

    func promptRenameSticky(id: UUID) {
        guard let note = stickyNotes[id] else { return }

        stickyWindows[id]?.makeKeyAndOrderFront(nil)

        let alert = NSAlert()
        alert.messageText = "Rename Note"
        alert.informativeText = "Set the title shown when this note is collapsed."
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = note.title == "New Note" ? "" : note.title
        field.placeholderString = "New Note"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let title = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        note.title = title.isEmpty ? "New Note" : title
        note.touch()
        store?.saveIgnoringErrors("Failed to rename sticky note")
    }

    func requestDelete(note: StickyNote) {
        let alert = NSAlert()
        alert.messageText = "Delete Note?"
        alert.informativeText = "Delete \"\(note.title.isEmpty ? "New Note" : note.title)\" and all tasks?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            deleteSticky(id: note.id)
        }
    }

    func deleteSticky(id: UUID) {
        guard let store else { return }

        closeSticky(id: id)

        do {
            try store.deleteNote(id: id)
        } catch {
            StickyLog.windowing.error("Failed to delete sticky: \(error.localizedDescription, privacy: .public)")
        }
    }

    func setColorForActiveSticky(_ color: StickyColor) {
        guard let note = activePanel?.stickyNote else { return }

        note.color = color
        note.touch()
        store?.saveIgnoringErrors("Failed to save sticky color")
    }

    func toggleCollapseForActiveSticky() {
        guard let note = activePanel?.stickyNote else { return }
        toggleCollapse(for: note.id)
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

    func useActiveStickyAsDefault() {
        guard let panel = activePanel,
              let note = panel.stickyNote else {
            return
        }

        windowDefaults.save(from: note, windowFrame: panel.frame)
    }

    func arrangeStickies(by mode: StickyArrangeMode) {
        let notes = sortedNotes(for: mode)
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 900, height: 700)

        for (index, note) in notes.enumerated() {
            guard let window = stickyWindows[note.id] else { continue }

            let offset = CGFloat((index % 10) * 24)
            let width = window.frame.width
            let height = window.frame.height
            let origin = NSPoint(
                x: visibleFrame.minX + 56 + offset,
                y: visibleFrame.maxY - height - 56 - offset
            )

            window.setFrame(
                NSRect(origin: origin, size: NSSize(width: width, height: height)),
                display: true,
                animate: true
            )
            window.orderFront(nil)
        }
    }

    func togglePinnedForActiveSticky() {
        guard let panel = activePanel,
              let note = panel.stickyNote else {
            return
        }

        note.isPinned.toggle()
        note.touch()
        StickyWindowGeometry.applyState(to: panel, from: note)
        store?.saveIgnoringErrors("Failed to save pinned state")
    }

    func toggleTranslucentForActiveSticky() {
        guard let panel = activePanel,
              let note = panel.stickyNote else {
            return
        }

        note.isTranslucent.toggle()
        note.touch()
        StickyWindowGeometry.applyState(to: panel, from: note)
        store?.saveIgnoringErrors("Failed to save translucent state")
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

    private var activePanel: StickyPanel? {
        NSApp.keyWindow as? StickyPanel
    }

    private func presentError(message: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func sortedNotes(for mode: StickyArrangeMode) -> [StickyNote] {
        switch mode {
        case .title:
            return stickyNotes.values.sorted {
                $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }
        case .color:
            return stickyNotes.values.sorted {
                if $0.color.rawValue == $1.color.rawValue {
                    return $0.createdAt < $1.createdAt
                }
                return $0.color.rawValue < $1.color.rawValue
            }
        case .createdAt:
            return stickyNotes.values.sorted { $0.createdAt < $1.createdAt }
        }
    }

    private func closeSticky(id: UUID) {
        if let window = stickyWindows[id] {
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
