import Foundation

enum StickyWindowLegacyNormalizer {
    private enum LegacyBounds {
        static let blankNoteWidth = 380.0
        static let blankNoteHeight = 340.0
        static let oversizedWidth = 380.0
        static let oversizedHeight = 360.0
    }

    static func normalize(_ note: StickyNote) -> Bool {
        var changed = normalizeBlankNote(note)

        if note.isTranslucent {
            note.isTranslucent = false
            changed = true
        }

        if note.windowW > LegacyBounds.oversizedWidth || note.windowH > LegacyBounds.oversizedHeight {
            resetVisualDefaults(for: note)
            changed = true
        }

        return changed
    }

    private static func normalizeBlankNote(_ note: StickyNote) -> Bool {
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let isBlankNote = note.items.isEmpty && (title.isEmpty || title == "New Sticky" || title == "New Note")
        let hasOldVisualState = note.color != .yellow
            || note.windowW > LegacyBounds.blankNoteWidth
            || note.windowH > LegacyBounds.blankNoteHeight

        guard isBlankNote && hasOldVisualState else { return false }

        note.title = "New Note"
        note.color = .yellow
        resetVisualDefaults(for: note)
        return true
    }

    private static func resetVisualDefaults(for note: StickyNote) {
        note.windowW = StickyMetrics.defaultWindowSize.width
        note.windowH = StickyMetrics.defaultWindowSize.height
        note.expandedHeight = StickyMetrics.defaultWindowSize.height
        note.isCollapsed = false
    }
}
