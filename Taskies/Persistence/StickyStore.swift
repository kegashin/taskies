import SwiftData
import Foundation

@MainActor
final class StickyStore {
    let container: ModelContainer

    var context: ModelContext {
        container.mainContext
    }

    init(container: ModelContainer) {
        self.container = container
    }

    static func production() -> StickyStore {
        StickyStore(container: makeModelContainer())
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

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            StickyNote.self,
            NoteItem.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
