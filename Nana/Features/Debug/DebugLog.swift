import Foundation
import OSLog
import StoreKit

nonisolated extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "Nana"
    /// Pod Bluetooth traffic and counts. In Console.app, filter on category "Pod".
    static let pod = Logger(subsystem: subsystem, category: "pod")
    static let nudges = Logger(subsystem: subsystem, category: "nudges")
}

/// The app's diagnostic log, built on Apple's unified logging. Entries go to the
/// system log through `Logger` (so they show in Xcode and Console.app), and the
/// debugger reads them back with `OSLogStore`. Nothing is kept by the app itself.
nonisolated enum DebugLog {
    struct Entry: Identifiable, Sendable {
        let id: Int
        let date: Date
        let category: String
        let message: String
        let isError: Bool
    }

    /// Whether this build has the debugger. Settled once at launch by `enableIfAvailable()`.
    static var isEnabled: Bool { enabled.withLock { $0 } }
    #if DEBUG
    private static let enabled = OSAllocatedUnfairLock(initialState: true)
    #else
    private static let enabled = OSAllocatedUnfairLock(initialState: false)
    #endif

    static func enableIfAvailable() async {
        let available = await isAvailable()
        enabled.withLock { $0 = available }
    }

    /// With the debugger, logged readably at `notice`, the lowest level `OSLogStore`
    /// reads back. Without it (App Store), logged at `debug`, which isn't kept, with
    /// the details redacted: counts and Pod IDs never sit in the device log.
    static func add(_ message: String, isError: Bool = false, logger: Logger = .pod) {
        switch (isEnabled, isError) {
        case (true, false): logger.notice("\(message, privacy: .public)")
        case (true, true): logger.error("\(message, privacy: .public)")
        case (false, false): logger.debug("\(message, privacy: .private)")
        case (false, true): logger.error("\(message, privacy: .private)")
        }
    }

    /// This launch's entries from Nana's own loggers, oldest first.
    static func entries(since start: Date? = nil) throws -> [Entry] {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = start.map { store.position(date: $0) } ?? store.position(timeIntervalSinceLatestBoot: 0)
        let matching = NSPredicate(format: "subsystem == %@", Logger.subsystem)
        return try store.getEntries(at: position, matching: matching)
            .compactMap { $0 as? OSLogEntryLog }
            .enumerated()
            .map { index, entry in
                Entry(
                    id: index,
                    date: entry.date,
                    category: entry.category,
                    message: entry.composedMessage,
                    isError: entry.level == .error || entry.level == .fault
                )
            }
    }

    /// Entries as plain text, for pasting into a bug report.
    static func text(for entries: [Entry]) -> String {
        entries.map { entry in
            let time = entry.date.formatted(.dateTime.hour().minute().second())
            return "\(time) [\(entry.category)] \(entry.isError ? "ERROR " : "")\(entry.message)"
        }
        .joined(separator: "\n")
    }

    /// The debugger is for builds from Xcode and TestFlight only, never the App Store.
    static func isAvailable() async -> Bool {
        #if DEBUG
        return true
        #else
        guard let result = try? await AppTransaction.shared else { return false }
        switch result {
        case .verified(let transaction), .unverified(let transaction, _):
            return transaction.environment != .production
        }
        #endif
    }
}
