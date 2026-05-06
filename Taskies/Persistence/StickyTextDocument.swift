import Foundation

enum StickyTextDocument {
    static func taskTexts(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func exportedText(for note: StickyNote) -> String {
        let visibleItems = note.visibleItems()
        let todo = visibleItems.todoItems.map { "- [ ] \($0.text)" }
        let done = visibleItems.doneItems.map { "- [x] \($0.text)" }

        var sections = [note.displayTitle]

        if !todo.isEmpty {
            sections.append(todo.joined(separator: "\n"))
        }

        if !done.isEmpty {
            sections.append(done.joined(separator: "\n"))
        }

        return sections.joined(separator: "\n\n")
    }
}
