import AppKit

@MainActor
extension StickyWindowCoordinator {
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

        do {
            try store.deleteNote(id: id)
            closeSticky(id: id, savesFrameOnClose: false)
        } catch {
            StickyLog.windowing.error("Failed to delete sticky: \(error.localizedDescription, privacy: .public)")
            presentError(message: "Could not delete note.", informativeText: error.localizedDescription)
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

    func useActiveStickyAsDefault() {
        guard let panel = activePanel,
              let note = panel.stickyNote else {
            return
        }

        windowDefaults.save(from: note, windowFrame: panel.frame)
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
}
