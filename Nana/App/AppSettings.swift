import Foundation

/// `@AppStorage` keys and defaults, in one place so features don't drift apart.
nonisolated enum AppSettings {
    static let hasOnboarded = "hasOnboarded"
    static let lowSupplyReminderOn = "lowSupplyReminderOn"
    static let lowSupplyThreshold = "lowSupplyThreshold"
    static let appLockOn = "appLockOn"
    static let showNanaOnHome = "showNanaOnHome"

    static let defaultLowSupplyThreshold = 2
}
