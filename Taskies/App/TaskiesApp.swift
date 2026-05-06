import SwiftUI

@main
@MainActor
struct TaskiesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let store: StickyStore

    init() {
        let store = StickyStore.production()
        self.store = store
        StickyWindowCoordinator.shared.configure(store: store)
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .modelContainer(store.container)
        .commands {
            TaskiesCommands()
        }
    }
}
