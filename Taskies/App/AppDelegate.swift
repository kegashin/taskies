import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuRepairScheduled = false
    private var lastMenuRepairAt = Date.distantPast
    private let menuRepairMinimumInterval: TimeInterval = 0.5

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }

        scheduleMenuRepair()

        Task { @MainActor in
            await Task.yield()
            self.installApplicationMenus()
            await Task.yield()
            StickyWindowCoordinator.shared.restoreAllWindows()
            StickyWindowCoordinator.shared.presentStartupIssueIfNeeded()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard !isRunningTests else { return }
        scheduleMenuRepair()
    }

    func applicationDidUpdate(_ notification: Notification) {
        guard !isRunningTests else { return }
        scheduleMenuRepair()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !isRunningTests else { return true }

        if !flag {
            StickyWindowCoordinator.shared.showAllStickies()
        }

        return true
    }

    private func scheduleMenuRepair() {
        guard !menuRepairScheduled else { return }
        menuRepairScheduled = true
        let elapsed = Date().timeIntervalSince(lastMenuRepairAt)
        let delay = max(0, menuRepairMinimumInterval - elapsed)

        Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            self.menuRepairScheduled = false
            self.installApplicationMenus()
        }
    }

    private func installApplicationMenus() {
        StickyFileMenuController.shared.install()
        StickyFontMenuController.shared.install()
        StickyColorMenuController.shared.install()
        lastMenuRepairAt = Date()
    }

    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["TASKIES_TESTING"] == "1"
    }
}
