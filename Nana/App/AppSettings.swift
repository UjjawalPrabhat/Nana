import Foundation

/// `@AppStorage` keys and defaults, in one place so features don't drift apart.
nonisolated enum AppSettings {
    static let hasOnboarded = "hasOnboarded"
    static let lowSupplyNudgeOn = "lowSupplyNudgeOn"
    static let leftBehindNudgeOn = "leftBehindNudgeOn"
    static let leftBehindWaitMinutes = "leftBehindWaitMinutes"

    static let waitChoices = [1, 2, 5]

    /// Registered at launch so `UserDefaults` reads and `@AppStorage` agree on first run.
    static var defaults: [String: Any] {
        [
            lowSupplyNudgeOn: true,
            leftBehindNudgeOn: true,
            leftBehindWaitMinutes: 2,
        ]
    }
}
