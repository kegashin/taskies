import SwiftUI

struct TaskiesCommands: Commands {
    private var coordinator: StickyWindowCoordinator {
        StickyWindowCoordinator.shared
    }

    var body: some Commands {
        CommandGroup(replacing: .windowSize) {
            Button("Collapse") {
                coordinator.toggleCollapseForActiveSticky()
            }
            .keyboardShortcut("m", modifiers: [.command])
            .disabled(!coordinator.hasActiveSticky)

            Button("Minimize") {
                coordinator.minimizeActiveSticky()
            }
            .disabled(!coordinator.hasActiveSticky)

            Button("Zoom") {
                coordinator.zoomActiveSticky()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .disabled(!coordinator.hasActiveSticky)

            Button("Fill") {
                coordinator.fillActiveSticky()
            }
            .keyboardShortcut("f", modifiers: [.control, .command])
            .disabled(!coordinator.hasActiveSticky)

            Button("Center") {
                coordinator.centerActiveSticky()
            }
            .keyboardShortcut("c", modifiers: [.control, .command])
            .disabled(!coordinator.hasActiveSticky)

            Divider()

            Menu("Move & Resize") {
                Button("Center") {
                    coordinator.centerActiveSticky()
                }
                .keyboardShortcut("c", modifiers: [.control, .command])
                .disabled(!coordinator.hasActiveSticky)

                Button("Fill") {
                    coordinator.fillActiveSticky()
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
                .disabled(!coordinator.hasActiveSticky)
            }

            Button("Full Screen Tile") {}
                .disabled(true)

            Divider()

            Button("Remove Window from Set") {}
                .disabled(true)
        }

        CommandGroup(replacing: .windowArrangement) {
            Button("Float on Top") {
                coordinator.togglePinnedForActiveSticky()
            }
            .keyboardShortcut("f", modifiers: [.command, .option])
            .disabled(!coordinator.hasActiveSticky)

            Button("Translucent") {
                coordinator.toggleTranslucentForActiveSticky()
            }
            .keyboardShortcut("t", modifiers: [.command, .option])
            .disabled(!coordinator.hasActiveSticky)

            Button("Use as Default") {
                coordinator.useActiveStickyAsDefault()
            }
            .disabled(!coordinator.hasActiveSticky)

            Divider()

            Button("Undo Arrange") {}
                .keyboardShortcut("z", modifiers: [.command, .option])
                .disabled(true)

            Button("Redo Arrange") {}
                .keyboardShortcut("z", modifiers: [.command, .shift, .option])
                .disabled(true)

            Menu("Arrange By") {
                Button("Name") {
                    coordinator.arrangeStickies(by: .title)
                }

                Button("Color") {
                    coordinator.arrangeStickies(by: .color)
                }

                Button("Date Created") {
                    coordinator.arrangeStickies(by: .createdAt)
                }
            }

            Button("Bring All to Front") {
                coordinator.showAllStickies()
            }
        }

        CommandGroup(replacing: .windowList) {
            ForEach(coordinator.windowMenuItems) { item in
                Button {
                    coordinator.showSticky(id: item.id)
                } label: {
                    Label(item.menuTitle, systemImage: item.systemImageName)
                }
            }
        }

    }
}
