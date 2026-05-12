import AppKit

@MainActor
extension StickyWindowCoordinator {
    func arrangeStickies(by mode: StickyArrangeMode) {
        let notes = sortedNotes(for: mode)
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 900, height: 700)

        for (index, note) in notes.enumerated() {
            guard let window = stickyWindows[note.id] else { continue }

            let offset = CGFloat((index % 10) * 24)
            let width = window.frame.width
            let height = window.frame.height
            let origin = NSPoint(
                x: visibleFrame.minX + 56 + offset,
                y: visibleFrame.maxY - height - 56 - offset
            )

            window.setFrame(
                NSRect(origin: origin, size: NSSize(width: width, height: height)),
                display: true,
                animate: true
            )
            window.orderFront(nil)
        }
    }

    private func sortedNotes(for mode: StickyArrangeMode) -> [StickyNote] {
        switch mode {
        case .title:
            return stickyNotes.values.sorted {
                $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }
        case .color:
            return stickyNotes.values.sorted {
                if $0.color.rawValue == $1.color.rawValue {
                    return $0.createdAt < $1.createdAt
                }
                return $0.color.rawValue < $1.color.rawValue
            }
        case .createdAt:
            return stickyNotes.values.sorted { $0.createdAt < $1.createdAt }
        }
    }
}
