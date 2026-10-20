import Foundation
import UserNotifications

/// Off by default. When on, sends one neutral notification as the container's
/// count drops to the "running low" threshold. The text never mentions what is
/// being tracked, because notifications can be seen by others.
nonisolated enum LowSupplyReminder {
    static let identifier = "nana.lowSupply"

    static func shouldNotify(previous: Int?, current: Int, threshold: Int) -> Bool {
        guard current <= threshold else { return false }
        guard let previous else { return true }
        return previous > threshold
    }

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func supplyChanged(from previous: Int?, to current: Int, defaults: UserDefaults) {
        guard defaults.bool(forKey: AppSettings.lowSupplyReminderOn) else { return }
        let threshold = defaults.object(forKey: AppSettings.lowSupplyThreshold) as? Int
            ?? AppSettings.defaultLowSupplyThreshold
        guard shouldNotify(previous: previous, current: current, threshold: threshold) else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Nana")
        content.body = String(localized: "Your reminder is ready.")
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
