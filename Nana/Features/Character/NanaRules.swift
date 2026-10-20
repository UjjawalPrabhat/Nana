import Foundation

nonisolated enum NanaStage: Int, CaseIterable, Comparable, Sendable {
    case seed, sprout, bloom

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .seed: String(localized: "Seed")
        case .sprout: String(localized: "Sprout")
        case .bloom: String(localized: "Bloom")
        }
    }
}

nonisolated enum NanaMood: CaseIterable, Sendable {
    /// A new lesson is ready today.
    case curious
    /// Today's lesson is done.
    case happy
    /// The user has been away; Nana wakes up glad to see them.
    case resting
    /// Nana just reached a new growth stage.
    case proud

    var title: String {
        switch self {
        case .curious: String(localized: "curious")
        case .happy: String(localized: "happy")
        case .resting: String(localized: "resting")
        case .proud: String(localized: "proud")
        }
    }
}

/// Pure growth and mood rules.
///
/// Nana grows from lessons finished, at any pace. It never reacts to supply,
/// never gets sick or sad, and there are no streaks to lose.
nonisolated enum NanaRules {
    struct Thresholds: Equatable, Sendable {
        /// Lessons needed to reach Sprout.
        var sprout: Int
        /// Lessons needed to reach Bloom.
        var bloom: Int
    }

    /// Days away before Nana is shown resting on return.
    static let restingAfterDays = 3

    static func stage(lessonsCompleted: Int, thresholds: Thresholds) -> NanaStage {
        if lessonsCompleted >= thresholds.bloom { return .bloom }
        if lessonsCompleted >= thresholds.sprout { return .sprout }
        return .seed
    }

    static func mood(
        now: Date,
        lastLessonCompletedAt: Date?,
        previousVisitAt: Date?,
        justGrew: Bool,
        calendar: Calendar = .current
    ) -> NanaMood {
        if justGrew { return .proud }
        if let lastLessonCompletedAt, calendar.isDate(lastLessonCompletedAt, inSameDayAs: now) {
            return .happy
        }
        if let previousVisitAt,
           let days = calendar.dateComponents([.day], from: previousVisitAt, to: now).day,
           days >= restingAfterDays {
            return .resting
        }
        return .curious
    }
}
