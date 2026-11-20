import Foundation
import OSLog
import UserNotifications

/// Every notification Nana can send. Each kind has a fixed identifier, so a new
/// schedule replaces the old one instead of stacking.
nonisolated enum Nudge: String, Sendable {
    case leftBehind = "nana.leftBehind"
    case lowSupply = "nana.lowSupply"

    /// What the notification says. Useful, but a lock screen can be seen by
    /// others, so it never says what the charm holds.
    func text(discreet: Bool) -> (title: String, body: String) {
        if discreet {
            return (String(localized: "Nana"), String(localized: "You have a reminder."))
        }
        return switch self {
        case .leftBehind: (
            String(localized: "Your charm stayed behind"),
            String(localized: "It's out of range. Head back for it, or open Nana to snooze.")
        )
        case .lowSupply: (
            String(localized: "Your charm is running low"),
            String(localized: "Restock before you head out.")
        )
        }
    }
}

/// Somewhere nudges can be scheduled. The real one is `NotificationScheduler`;
/// tests and previews use their own.
protocol NudgeScheduling: AnyObject {
    func schedule(_ nudge: Nudge, at date: Date)
    func cancel(_ nudge: Nudge)
}

/// Local notifications. Their text says what happened without naming what's in
/// the charm, and can be made fully generic in Settings.
final class NotificationScheduler: NSObject, NudgeScheduling {
    /// Called when someone taps a nudge.
    var onOpen: ((Nudge) -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func isAuthorized() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .authorized
    }

    func schedule(_ nudge: Nudge, at date: Date) {
        let text = nudge.text(discreet: UserDefaults.standard.bool(forKey: AppSettings.discreetNudges))
        let content = UNMutableNotificationContent()
        content.title = text.title
        content.body = text.body
        content.sound = .default
        let delay = date.timeIntervalSinceNow
        // A nil trigger delivers right away; interval triggers must be positive.
        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        center.add(UNNotificationRequest(identifier: nudge.rawValue, content: content, trigger: trigger)) { error in
            if let error { Logger.nudges.error("Could not schedule \(nudge.rawValue, privacy: .public): \(error)") }
        }
    }

    func cancel(_ nudge: Nudge) {
        center.removePendingNotificationRequests(withIdentifiers: [nudge.rawValue])
        center.removeDeliveredNotifications(withIdentifiers: [nudge.rawValue])
    }
}

// iOS may call these off the main thread, so they're nonisolated and hop to the
// main actor themselves instead of relying on a runtime isolation check.
extension NotificationScheduler: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let nudge = Nudge(rawValue: response.notification.request.identifier) else { return }
        await MainActor.run { onOpen?(nudge) }
    }
}

private extension Logger {
    nonisolated static let nudges = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Nana", category: "nudges")
}

#if DEBUG
/// Drops every nudge. For previews.
final class SilentNudgeScheduler: NudgeScheduling {
    func schedule(_ nudge: Nudge, at date: Date) {}
    func cancel(_ nudge: Nudge) {}
}
#endif
