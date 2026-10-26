import Foundation

/// Sends one nudge as the charm's count drops to "running low", not on every
/// reading after that.
nonisolated enum LowSupplyReminder {
    static func shouldNotify(previous: Int?, current: Int, threshold: Int = SupplyLedger.lowThreshold) -> Bool {
        guard current <= threshold else { return false }
        guard let previous else { return true }
        return previous > threshold
    }
}
