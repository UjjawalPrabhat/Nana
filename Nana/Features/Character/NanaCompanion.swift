import Foundation

/// Session-level state for Nana: when the user was last here, and whether Nana has
/// already woken up to greet them this session.
@Observable
final class NanaCompanion {
    /// When the app was last sent to the background before this launch.
    let previousVisitAt: Date?
    /// Set once the resting greeting has been shown, so Nana stays awake afterwards.
    var hasGreeted = false

    @ObservationIgnored private let defaults: UserDefaults
    private static let lastActiveKey = "nana.lastActiveAt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        previousVisitAt = defaults.object(forKey: Self.lastActiveKey) as? Date
    }

    func recordActive(at date: Date = .now) {
        defaults.set(date, forKey: Self.lastActiveKey)
    }

    func snapshot(library: ContentLibrary, completions: [LessonCompletion], now: Date = .now) -> NanaSnapshot {
        let thresholds = library.growthThresholds
        let stage = NanaRules.stage(lessonsCompleted: completions.count, thresholds: thresholds)
        var mood = NanaRules.mood(
            now: now,
            lastLessonCompletedAt: completions.map(\.completedAt).max(),
            previousVisitAt: previousVisitAt,
            justGrew: false
        )
        if mood == .resting, hasGreeted { mood = .curious }
        return NanaSnapshot(stage: stage, mood: mood, completedCount: completions.count, thresholds: thresholds)
    }
}

nonisolated struct NanaSnapshot: Equatable, Sendable {
    var stage: NanaStage
    var mood: NanaMood
    var completedCount: Int
    var thresholds: NanaRules.Thresholds

    var nextStage: NanaStage? { NanaStage(rawValue: stage.rawValue + 1) }

    /// Lessons needed to reach the next stage, from the start of the current one.
    var progressToNextStage: (done: Int, total: Int)? {
        switch stage {
        case .seed: (completedCount, thresholds.sprout)
        case .sprout: (completedCount, thresholds.bloom)
        case .bloom: nil
        }
    }
}
