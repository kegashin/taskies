import AppKit
import UniformTypeIdentifiers

@MainActor
extension StickyWindowCoordinator {
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
}
