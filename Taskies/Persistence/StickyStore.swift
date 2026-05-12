import Foundation
import AppKit
import Darwin
import SwiftData

struct StickyStoreStartupIssue {
    let errorDescription: String
    let dataDirectory: URL?

    var alertMessage: String {
        "Taskies could not open saved notes."
    }

    var alertInformativeText: String {
        """
        Taskies opened with temporary empty notes. Your existing data was left untouched.

        Error: \(errorDescription)

        Quit Taskies, back up the data folder, then reset app data manually if you want to start fresh.
        """
    }
}

@MainActor
final class StickyStore {
    let container: ModelContainer

    var context: ModelContext {
        container.mainContext
    }

    init(container: ModelContainer) {
        self.container = container
    }

    static func production() throws -> StickyStore {
        try StickyStore(container: makeModelContainer(isStoredInMemoryOnly: false))
    }

    static func inMemory() throws -> StickyStore {
        try StickyStore(container: makeModelContainer(isStoredInMemoryOnly: true))
    }

    static func testing() -> StickyStore {
        do {
            return try inMemory()
        } catch {
            StickyLog.store.fault("Could not create test ModelContainer: \(error.localizedDescription, privacy: .public)")
            terminateAfterUnrecoverableStartupError(
                productionError: "Taskies is running tests.",
                recoveryError: error.localizedDescription
            )
        }
    }

    static func productionWithRecovery() -> (store: StickyStore, startupIssue: StickyStoreStartupIssue?) {
        do {
            return (try production(), nil)
        } catch {
            StickyLog.store.fault("Could not create production ModelContainer: \(error.localizedDescription, privacy: .public)")

            let issue = StickyStoreStartupIssue(
                errorDescription: error.localizedDescription,
                dataDirectory: persistentStoreDirectory()
            )

            do {
                return (try inMemory(), issue)
            } catch {
                StickyLog.store.fault("Could not create in-memory ModelContainer: \(error.localizedDescription, privacy: .public)")
                terminateAfterUnrecoverableStartupError(
                    productionError: issue.errorDescription,
                    recoveryError: error.localizedDescription
                )
            }
        }
    }

    func insertNote(configure: (StickyNote) -> Void = { _ in }) -> StickyNote {
        let note = StickyNote(color: .yellow)
        configure(note)
        context.insert(note)
        return note
    }

    func createNote(configure: (StickyNote) -> Void = { _ in }) throws -> StickyNote {
        let note = insertNote(configure: configure)
        try save()
        return note
    }

    func fetchNotes() throws -> [StickyNote] {
        let descriptor = FetchDescriptor<StickyNote>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func deleteNote(id: UUID) throws {
        var descriptor = FetchDescriptor<StickyNote>(
            predicate: #Predicate { note in
                note.id == id
            }
        )
        descriptor.fetchLimit = 1

        if let note = try context.fetch(descriptor).first {
            context.delete(note)
            try save()
        }
    }

    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    func transaction(_ block: () throws -> Void) throws {
        try context.transaction(block: block)
    }

    func saveIgnoringErrors(_ label: String) {
        do {
            try save()
        } catch {
            StickyLog.store.error("\(label, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func makeModelContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([
            StickyNote.self,
            NoteItem.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func persistentStoreDirectory() -> URL? {
        let schema = Schema([
            StickyNote.self,
            NoteItem.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return configuration.url.deletingLastPathComponent()
    }

    private static func terminateAfterUnrecoverableStartupError(
        productionError: String,
        recoveryError: String
    ) -> Never {
        let alert = NSAlert()
        alert.messageText = "Taskies could not start."
        alert.informativeText = """
        Taskies could not open saved notes or create a temporary recovery store.

        Saved notes error: \(productionError)

        Recovery error: \(recoveryError)
        """
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.runModal()

        exit(EXIT_FAILURE)
    }
}
