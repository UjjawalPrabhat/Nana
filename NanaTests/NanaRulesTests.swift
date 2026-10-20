import Foundation
import Testing
@testable import Nana

struct NanaRulesTests {
    private let thresholds = NanaRules.Thresholds(sprout: 4, bloom: 10)
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test(arguments: [(0, NanaStage.seed), (3, .seed), (4, .sprout), (9, .sprout), (10, .bloom), (40, .bloom)])
    func stageFollowsLessonsCompleted(lessons: Int, expected: NanaStage) {
        #expect(NanaRules.stage(lessonsCompleted: lessons, thresholds: thresholds) == expected)
    }

    @Test func proudWinsWhenNanaJustGrew() {
        let mood = NanaRules.mood(now: now, lastLessonCompletedAt: now, previousVisitAt: nil, justGrew: true, calendar: calendar)
        #expect(mood == .proud)
    }

    @Test func happyAfterTodaysLesson() {
        let mood = NanaRules.mood(now: now, lastLessonCompletedAt: now.addingTimeInterval(-600), previousVisitAt: nil, justGrew: false, calendar: calendar)
        #expect(mood == .happy)
    }

    @Test func restingAfterTimeAway() {
        let away = now.addingTimeInterval(-4 * 86_400)
        let mood = NanaRules.mood(now: now, lastLessonCompletedAt: away, previousVisitAt: away, justGrew: false, calendar: calendar)
        #expect(mood == .resting)
    }

    @Test func curiousByDefault() {
        let yesterday = now.addingTimeInterval(-86_400)
        let mood = NanaRules.mood(now: now, lastLessonCompletedAt: yesterday, previousVisitAt: yesterday, justGrew: false, calendar: calendar)
        #expect(mood == .curious)
    }
}
