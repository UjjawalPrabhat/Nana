import Foundation

/// `@AppStorage` keys and defaults, in one place so features don't drift apart.
nonisolated enum AppSettings {
    static let hasOnboarded = "hasOnboarded"
    static let lowSupplyNudgeOn = "lowSupplyNudgeOn"
    static let leftBehindNudgeOn = "leftBehindNudgeOn"
    static let leftBehindWaitMinutes = "leftBehindWaitMinutes"
    /// Notifications show only "You have a reminder."
    static let discreetNudges = "discreetNudges"

    static let waitChoices = [1, 2, 5]

    /// Debug builds accept `-NanaScreenshots YES`: the demo charm stands in for a
    /// real one in App Store screenshots, so its "Demo" labels are hidden.
    static var isTakingScreenshots: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "NanaScreenshots")
        #else
        false
        #endif
    }

    /// Registered at launch so `UserDefaults` reads and `@AppStorage` agree on first run.
    static var defaults: [String: Any] {
        [
            // Off until the user says yes to notifications (onboarding, or a toggle).
            lowSupplyNudgeOn: false,
            leftBehindNudgeOn: false,
            leftBehindWaitMinutes: 2,
            discreetNudges: false,
        ]
    }
}
