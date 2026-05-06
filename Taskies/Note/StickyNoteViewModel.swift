import Observation
import SwiftUI

@MainActor
@Observable
final class StickyNoteViewModel {
    let store: StickyStore
    let windowCoordinator: StickyWindowCoordinator
    var stickyNote: StickyNote

    var isDoneSectionExpanded = false
    var newTaskText = ""
    var showDeleteConfirmation = false
    var showArchiveDoneConfirmation = false

    private(set) var todoItems: [NoteItem] = []
    private(set) var doneItems: [NoteItem] = []

    @ObservationIgnored private var pendingSaveTask: Task<Void, Never>?

    init(stickyNote: StickyNote, store: StickyStore, windowCoordinator: StickyWindowCoordinator) {
        self.stickyNote = stickyNote
        self.store = store
        self.windowCoordinator = windowCoordinator
        refreshItemCaches()
    }

    var isCollapsed: Bool {
        stickyNote.isCollapsed
    }

    var displayTitle: String {
        stickyNote.displayTitle
    }

    func toggleCollapse() {
        windowCoordinator.toggleCollapse(for: stickyNote.id)
    }

    func zoom() {
        windowCoordinator.zoomWindow(for: stickyNote.id)
    }

    func rename() {
        windowCoordinator.promptRenameSticky(id: stickyNote.id)
    }

    func requestDelete() {
        showDeleteConfirmation = true
    }

    func confirmDelete() {
        windowCoordinator.deleteSticky(id: stickyNote.id)
    }

    func addTask(text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let item = NoteItem(text: trimmedText, order: nextTodoOrder)
        item.note = stickyNote
        stickyNote.items.append(item)
        todoItems.append(item)
        stickyNote.touch()

        newTaskText = ""
        saveNow("Failed to save new task")
    }

    func updateTaskText(_ item: NoteItem, newText: String) {
        guard item.text != newText else { return }
        item.text = newText
        scheduleSave(touchNoteBeforeSaving: true)
    }

    func toggleDone(_ item: NoteItem) {
        if item.status == .todo {
            item.updateStatus(.done)
            todoItems.removeAll { $0.id == item.id }
            insertDoneItem(item)
        } else if item.status == .done {
            let nextOrder = nextTodoOrder
            item.updateStatus(.todo)
            item.order = nextOrder
            doneItems.removeAll { $0.id == item.id }
            todoItems.append(item)
        }

        stickyNote.touch()
        saveNow("Failed to save task status")
    }

    func deleteTask(_ item: NoteItem) {
        if let index = stickyNote.items.firstIndex(where: { $0.id == item.id }) {
            stickyNote.items.remove(at: index)
        }
        todoItems.removeAll { $0.id == item.id }
        doneItems.removeAll { $0.id == item.id }

        store.context.delete(item)
        stickyNote.touch()
        saveNow("Failed to delete task")
    }

    func clearDone() {
        showArchiveDoneConfirmation = true
    }

    func confirmArchiveDone() {
        for item in stickyNote.items where item.status == .done {
            item.updateStatus(.archived)
        }

        doneItems.removeAll(keepingCapacity: true)
        isDoneSectionExpanded = false
        showArchiveDoneConfirmation = false
        stickyNote.touch()
        saveNow("Failed to archive done tasks")
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        todoItems.move(fromOffsets: source, toOffset: destination)

        for (index, item) in todoItems.enumerated() {
            item.order = index
        }

        stickyNote.touch()
        saveNow("Failed to reorder tasks")
    }

    func updateTitle(_ newTitle: String) {
        guard stickyNote.title != newTitle else { return }
        stickyNote.title = newTitle
        scheduleSave(touchNoteBeforeSaving: true)
    }

    func updateColor(_ newColor: StickyColor) {
        guard stickyNote.color != newColor else { return }
        stickyNote.color = newColor
        stickyNote.touch()
        saveNow("Failed to save sticky color")
    }

    deinit {
        pendingSaveTask?.cancel()
    }

    private var nextTodoOrder: Int {
        (todoItems.last?.order ?? -1) + 1
    }

    private func refreshItemCaches() {
        let visibleItems = stickyNote.visibleItems()
        todoItems = visibleItems.todoItems
        doneItems = visibleItems.doneItems
    }

    private func insertDoneItem(_ item: NoteItem) {
        doneItems.append(item)
        doneItems.sort { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
    }

    private func scheduleSave(touchNoteBeforeSaving: Bool = false) {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            self?.performScheduledSave(touchNoteBeforeSaving: touchNoteBeforeSaving)
        }
    }

    private func saveNow(_ label: String) {
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        store.saveIgnoringErrors(label)
    }

    private func performScheduledSave(touchNoteBeforeSaving: Bool) {
        pendingSaveTask = nil
        if touchNoteBeforeSaving {
            stickyNote.touch()
        }
        store.saveIgnoringErrors("Failed to save sticky note")
    }
}
