import XCTest
@testable import Taskies

@MainActor
final class TaskiesModelTests: XCTestCase {
    func testTaskTextParsingTrimsBlankLines() {
        let text = """

          buy milk

        send note
        """

        XCTAssertEqual(
            StickyTextDocument.taskTexts(from: text),
            ["buy milk", "send note"]
        )
    }

    func testNoteItemStatusTransitionsTrackDates() {
        let item = NoteItem(text: "ship release")
        let completedAt = Date(timeIntervalSince1970: 10)
        let archivedAt = Date(timeIntervalSince1970: 20)

        item.updateStatus(.done, at: completedAt)

        XCTAssertEqual(item.status, .done)
        XCTAssertEqual(item.completedAt, completedAt)
        XCTAssertNil(item.archivedAt)

        item.updateStatus(.archived, at: archivedAt)

        XCTAssertEqual(item.status, .archived)
        XCTAssertEqual(item.completedAt, completedAt)
        XCTAssertEqual(item.archivedAt, archivedAt)

        item.updateStatus(.todo)

        XCTAssertEqual(item.status, .todo)
        XCTAssertNil(item.completedAt)
        XCTAssertNil(item.archivedAt)
    }

    func testVisibleItemsSortAndHideArchivedItems() {
        let note = StickyNote(title: "release")
        let laterDone = makeItem("later done", order: 0, status: .done, completedAt: 30)
        let archived = makeItem("archived", order: 1, status: .archived, archivedAt: 40)
        let secondTodo = makeItem("second todo", order: 2)
        let firstTodo = makeItem("first todo", order: 1)
        let earlierDone = makeItem("earlier done", order: 3, status: .done, completedAt: 10)

        [laterDone, archived, secondTodo, firstTodo, earlierDone].forEach { attach($0, to: note) }

        let visibleItems = note.visibleItems()

        XCTAssertEqual(visibleItems.todoItems.map(\.text), ["first todo", "second todo"])
        XCTAssertEqual(visibleItems.doneItems.map(\.text), ["later done", "earlier done"])
        XCTAssertEqual(note.archivedItems.map(\.text), ["archived"])
    }

    func testExportTextIncludesTodoAndDoneItems() {
        let note = StickyNote(title: "Release")
        attach(makeItem("fix crash", order: 0), to: note)
        attach(makeItem("add tests", order: 1), to: note)
        attach(makeItem("old task", order: 2, status: .done, completedAt: 10), to: note)

        XCTAssertEqual(
            StickyTextDocument.exportedText(for: note),
            """
            Release

            - [ ] fix crash
            - [ ] add tests

            - [x] old task
            """
        )
    }

    func testArchiveDoneHidesCompletedItems() throws {
        let store = try StickyStore.inMemory()
        let note = store.insertNote { note in
            note.title = "Archive"
        }
        let done = makeItem("done", order: 0, status: .done, completedAt: 10)
        attach(done, to: note)
        store.context.insert(done)

        let viewModel = StickyNoteViewModel(
            stickyNote: note,
            store: store,
            windowCoordinator: StickyWindowCoordinator.shared
        )

        XCTAssertEqual(viewModel.doneItems.map(\.text), ["done"])

        viewModel.confirmArchiveDone()

        XCTAssertTrue(viewModel.doneItems.isEmpty)
        XCTAssertTrue(note.visibleItems().doneItems.isEmpty)
        XCTAssertEqual(note.archivedItems.map(\.text), ["done"])
    }

    private func makeItem(
        _ text: String,
        order: Int,
        status: ItemStatus = .todo,
        completedAt: TimeInterval? = nil,
        archivedAt: TimeInterval? = nil
    ) -> NoteItem {
        let item = NoteItem(text: text, order: order)

        if let completedAt {
            item.updateStatus(.done, at: Date(timeIntervalSince1970: completedAt))
        }

        if let archivedAt {
            item.updateStatus(.archived, at: Date(timeIntervalSince1970: archivedAt))
        }

        if status == .archived, archivedAt == nil {
            item.updateStatus(.archived, at: Date(timeIntervalSince1970: 1))
        }

        return item
    }

    private func attach(_ item: NoteItem, to note: StickyNote) {
        item.note = note
        note.items.append(item)
    }
}
