import Foundation
import Testing
@testable import Nana

/// Guards the bundled lesson content. A failure here means a lesson isn't ready to ship.
struct ContentTests {
    private let library: ContentLibrary

    init() throws {
        // Tests run inside the app, so the app's bundle holds the content.
        library = try ContentLibrary.load(from: .main, language: "en")
    }

    @Test func contentMeetsEveryRule() {
        #expect(library.problems() == [])
    }

    @Test func everyTrackHasLessons() {
        for track in library.tracks {
            #expect(!library.lessons(in: track).isEmpty, "\(track.id) has no lessons")
        }
    }

    @Test func dailyPathCoversEveryLessonOnce() {
        let order = library.suggestedOrder.map(\.id)
        #expect(order.count == library.curriculum.lessons.count)
        #expect(Set(order).count == order.count)
    }

    @Test func timeCriticalLessonsComeInTheFirstTwoWeeks() {
        let order = library.suggestedOrder.map(\.id)
        for id in ["protection-if-it-breaks", "hiv-pep", "body-emergency-contraception"] {
            let position = try? #require(order.firstIndex(of: id))
            #expect((position ?? .max) < 14, "\(id) should be in the first two weeks")
        }
    }

    @Test func thresholdsMatchContentGuide() {
        // Docs/CONTENT.md §6: Sprout = Essential ÷ 3, Bloom = all Essential lessons.
        let essential = library.curriculum.lessons.filter { $0.tier == .essential }.count
        #expect(library.growthThresholds.bloom == essential)
        #expect(library.growthThresholds.sprout == Int((Double(essential) / 3).rounded(.up)))
    }

    @Test func todaysLessonSkipsCompleted() {
        let first = library.suggestedOrder[0]
        #expect(library.todaysLesson(completed: []) == first)
        #expect(library.todaysLesson(completed: [first.id]) == library.suggestedOrder[1])
        #expect(library.todaysLesson(completed: Set(library.curriculum.lessons.map(\.id))) == nil)
    }

    @Test func neutralTitlesNeverRevealTopic() {
        let revealing = ["condom", "sex", "hiv", "sti", "pregnan", "contracept", "pep", "prep"]
        for lesson in library.curriculum.lessons {
            let title = lesson.neutralTitle.lowercased()
            #expect(!revealing.contains { title.contains($0) }, "\(lesson.id) neutral title reveals topic")
        }
    }
}
