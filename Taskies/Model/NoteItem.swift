import Foundation
import SwiftData

@Model
final class NoteItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var statusRaw: String
    var order: Int
    var createdAt: Date
    var completedAt: Date?
    var archivedAt: Date?
    
    var note: StickyNote?
    
    init(
        id: UUID = UUID(),
        text: String = "",
        status: ItemStatus = .todo,
        order: Int = 0
    ) {
        self.id = id
        self.text = text
        self.statusRaw = status.rawValue
        self.order = order
        self.createdAt = Date()
    }
    
    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .todo }
        set {
            updateStatus(newValue)
        }
    }

    func updateStatus(_ newStatus: ItemStatus, at date: Date = Date()) {
        let oldStatus = status
        guard oldStatus != newStatus else { return }

        statusRaw = newStatus.rawValue

        switch newStatus {
        case .todo:
            completedAt = nil
            archivedAt = nil
        case .done:
            completedAt = date
            archivedAt = nil
        case .archived:
            archivedAt = date
        }
    }
}

enum ItemStatus: String, CaseIterable {
    case todo = "todo"
    case done = "done"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .done: return "Done"
        case .archived: return "Archived"
        }
    }
}
