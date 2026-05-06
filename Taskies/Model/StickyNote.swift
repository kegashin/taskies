import Foundation
import SwiftData

@Model
final class StickyNote {
    @Attribute(.unique) var id: UUID
    var title: String
    var colorRaw: String
    var createdAt: Date
    var updatedAt: Date
    var windowX: Double
    var windowY: Double
    var windowW: Double
    var windowH: Double
    var isPinned: Bool
    var isTranslucent: Bool = false
    var isCollapsed: Bool
    var expandedHeight: Double

    @Relationship(deleteRule: .cascade, inverse: \NoteItem.note)
    var items: [NoteItem] = []

    static let collapsedHeight: Double = 12

    init(
        id: UUID = UUID(),
        title: String = "New Note",
        color: StickyColor = .yellow,
        windowX: Double = 100,
        windowY: Double = 100,
        windowW: Double = 300,
        windowH: Double = 300,
        isPinned: Bool = false,
        isTranslucent: Bool = false,
        isCollapsed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.colorRaw = color.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.windowX = windowX
        self.windowY = windowY
        self.windowW = windowW
        self.windowH = windowH
        self.isPinned = isPinned
        self.isTranslucent = isTranslucent
        self.isCollapsed = isCollapsed
        self.expandedHeight = windowH
    }

    var color: StickyColor {
        get { StickyColor(rawValue: colorRaw) ?? .yellow }
        set { colorRaw = newValue.rawValue }
    }

    var todoItems: [NoteItem] {
        items.lazy
            .filter { $0.status == .todo }
            .sorted { $0.order < $1.order }
    }

    var doneItems: [NoteItem] {
        items.lazy
            .filter { $0.status == .done }
            .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
    }

    func visibleItems() -> StickyVisibleItems {
        var todoItems: [NoteItem] = []
        var doneItems: [NoteItem] = []

        for item in items {
            switch item.status {
            case .todo:
                todoItems.append(item)
            case .done:
                doneItems.append(item)
            case .archived:
                continue
            }
        }

        todoItems.sort { $0.order < $1.order }
        doneItems.sort { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
        return StickyVisibleItems(todoItems: todoItems, doneItems: doneItems)
    }

    var archivedItems: [NoteItem] {
        items.lazy
            .filter { $0.status == .archived }
            .sorted { ($0.archivedAt ?? Date.distantPast) > ($1.archivedAt ?? Date.distantPast) }
    }

    var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        if let firstTaskText = firstTodoItem?.text.trimmingCharacters(in: .whitespacesAndNewlines),
           !firstTaskText.isEmpty {
            return firstTaskText
        }

        return "New Note"
    }

    var nextTodoOrder: Int {
        (items.lazy.filter { $0.status == .todo }.map(\.order).max() ?? -1) + 1
    }

    func touch(at date: Date = Date()) {
        updatedAt = date
    }

    private var firstTodoItem: NoteItem? {
        items
            .lazy
            .filter { $0.status == .todo }
            .min { $0.order < $1.order }
    }
}

struct StickyVisibleItems {
    let todoItems: [NoteItem]
    let doneItems: [NoteItem]
}

enum StickyColor: String, CaseIterable, Identifiable {
    case yellow
    case blue
    case green
    case pink
    case purple
    case gray

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .green: return "Green"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .gray: return "Gray"
        }
    }
}
