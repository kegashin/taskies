import SwiftUI

@main
@MainActor
struct TaskiesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let store: StickyStore

    init() {
        let recoveredStore: (store: StickyStore, startupIssue: StickyStoreStartupIssue?)
        if Self.isRunningTests {
            recoveredStore = (store: StickyStore.testing(), startupIssue: nil)
        } else {
            recoveredStore = StickyStore.productionWithRecovery()
        }
        let store = recoveredStore.store
        self.store = store
        StickyWindowCoordinator.shared.configure(
            store: store,
            startupIssue: recoveredStore.startupIssue
        )
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

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["TASKIES_TESTING"] == "1"
    }
}
