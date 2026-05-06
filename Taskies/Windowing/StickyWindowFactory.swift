import AppKit
import SwiftUI

@MainActor
enum StickyWindowFactory {
    static func makeWindow(
        note: StickyNote,
        store: StickyStore,
        coordinator: StickyWindowCoordinator,
        onClose: @escaping (UUID) -> Void
    ) -> StickyPanel {
        let viewModel = StickyNoteViewModel(
            stickyNote: note,
            store: store,
            windowCoordinator: coordinator
        )

        let hostingView = StickyHostingView(
            rootView: StickyNoteView(viewModel: viewModel)
                .modelContainer(store.container)
        )

        let panel = StickyPanel(
            contentRect: NSRect(
                x: note.windowX,
                y: note.windowY,
                width: note.windowW,
                height: note.isCollapsed ? StickyNote.collapsedHeight : note.windowH
            ),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.stickyNote = note
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovable = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.acceptsMouseMovedEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .participatesInCycle]

        StickyWindowGeometry.applyState(to: panel, from: note)
        StickyWindowGeometry.applyResizeLimits(to: panel, isCollapsed: note.isCollapsed)

        let delegate = StickyWindowDelegate(
            stickyNote: note,
            store: store,
            onClose: onClose,
            onBecomeKey: { id in
                coordinator.activateSticky(id: id)
            },
            onResignKey: { id in
                coordinator.deactivateSticky(id: id)
            }
        )
        panel.delegate = delegate
        panel.windowDelegate = delegate

        return panel
    }
}

final class StickyHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
