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
            #expect((order.firstIndex(of: id) ?? .max) < 14, "\(id) should be in the first two weeks")
        }
    }

    @Test func thresholdsMatchContentGuide() {
        // Docs/CONTENT.md §6. Update both together if the Essential lesson count changes.
        #expect(library.growthThresholds == .init(sprout: 9, bloom: 27))
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

extension ContentLibrary {
    /// Every rule a lesson must meet before it ships.
    func problems() -> [String] {
        var problems: [String] = []
        let trackIDs = Set(curriculum.tracks.map(\.id))
        var seen = Set<String>()
        for lesson in curriculum.lessons {
            let name = lesson.id
            if !seen.insert(name).inserted { problems.append("\(name): duplicate id") }
            if !trackIDs.contains(lesson.track) { problems.append("\(name): unknown track \(lesson.track)") }
            if !(2...4).contains(lesson.cards.count) { problems.append("\(name): needs 2–4 cards") }
            if lesson.sourceIds.isEmpty { problems.append("\(name): no sources") }
            for id in lesson.sourceIds where sources[id] == nil {
                problems.append("\(name): missing source \(id)")
            }
            let check = lesson.quickCheck
            if !(2...4).contains(check.options.count) { problems.append("\(name): quick check needs 2–4 options") }
            if !check.options.indices.contains(check.answerIndex) { problems.append("\(name): invalid answerIndex") }
            if lesson.neutralTitle.isEmpty { problems.append("\(name): empty neutralTitle") }
            for card in lesson.cards {
                if card.headline.count > 60 { problems.append("\(name): headline over 60 chars") }
                if let body = card.body, body.count > 280 { problems.append("\(name): body over 280 chars") }
                if card.kind == .stat, card.stat == nil { problems.append("\(name): stat card without stat") }
                if card.kind == .steps, card.steps?.isEmpty ?? true { problems.append("\(name): steps card without steps") }
            }
        }
        for id in curriculum.dailyPath ?? [] where !curriculum.lessons.contains(where: { $0.id == id }) {
            problems.append("dailyPath: unknown lesson \(id)")
        }
        return problems
    }
}
