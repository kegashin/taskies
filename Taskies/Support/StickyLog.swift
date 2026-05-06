import Foundation
import OSLog

enum StickyLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.taskies.app"

    static let store = Logger(subsystem: subsystem, category: "Store")
    static let windowing = Logger(subsystem: subsystem, category: "Windowing")
}
