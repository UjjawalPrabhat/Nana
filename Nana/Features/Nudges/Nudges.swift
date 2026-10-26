import Foundation
import UserNotifications

/// Every notification Nana can send. Each kind has a fixed identifier, so a new
/// schedule replaces the old one instead of stacking.
nonisolated enum Nudge: String, CaseIterable, Sendable {
    case leftBehind = "nana.leftBehind"
    case lowSupply = "nana.lowSupply"
}

/// Somewhere nudges can be scheduled. The real one is `NotificationScheduler`;
/// tests and previews use their own.
protocol NudgeScheduling: AnyObject {
    func schedule(_ nudge: Nudge, at date: Date)
    func cancel(_ nudge: Nudge)
}

/// Local notifications with one neutral text for every kind, because a lock
/// screen can be seen by others.
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
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Reminder")
        content.body = String(localized: "Your reminder is ready.")
        content.sound = .default
        let delay = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        center.add(UNNotificationRequest(identifier: nudge.rawValue, content: content, trigger: trigger))
    }

    func cancel(_ nudge: Nudge) {
        center.removePendingNotificationRequests(withIdentifiers: [nudge.rawValue])
        center.removeDeliveredNotifications(withIdentifiers: [nudge.rawValue])
    }
}

extension NotificationScheduler: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let nudge = Nudge(rawValue: response.notification.request.identifier) { onOpen?(nudge) }
        completionHandler()
    }
}

#if DEBUG
/// Drops every nudge. For previews.
final class SilentNudgeScheduler: NudgeScheduling {
    func schedule(_ nudge: Nudge, at date: Date) {}
    func cancel(_ nudge: Nudge) {}
}
#endif
