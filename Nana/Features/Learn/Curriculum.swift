import Foundation

/// Bundled lesson content. The JSON shape is documented in Docs/CONTENT.md.
nonisolated struct Curriculum: Decodable, Sendable {
    var version: Int
    var tracks: [Track]
    /// Recommended order for "today's lesson" (Docs/CONTENT.md §6.1).
    var dailyPath: [String]?
    var lessons: [Lesson]

    struct Track: Decodable, Identifiable, Hashable, Sendable {
        var id: String
        var title: String
        var summary: String
        var order: Int
    }

    struct Lesson: Decodable, Identifiable, Hashable, Sendable {
        enum Tier: String, Decodable, Sendable {
            case essential, goodToKnow, expert
        }

        enum GetHelp: String, Decodable, Sendable {
            case testing, pep, none
        }

        struct Card: Decodable, Hashable, Sendable {
            enum Kind: String, Decodable, Sendable {
                case text, stat, steps
            }

            var kind: Kind
            var eyebrow: String?
            var headline: String
            var body: String?
            var stat: String?
            var statCaption: String?
            var steps: [String]?
            var nanaTip: String?
        }

        struct QuickCheck: Decodable, Hashable, Sendable {
            var question: String
            var options: [String]
            var answerIndex: Int
            var explanation: String
        }

        struct Review: Decodable, Hashable, Sendable {
            var status: String
            var reviewer: String?
            var date: String?
        }

        var id: String
        var track: String
        var tier: Tier
        var order: Int
        var title: String
        /// Shown anywhere others might see it. Never names the topic.
        var neutralTitle: String
        var minutes: Int
        var cards: [Card]
        var quickCheck: QuickCheck
        var sourceIds: [String]
        var getHelp: GetHelp
        var review: Review
        var localNote: String?
    }
}

nonisolated struct ContentSource: Decodable, Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var publisher: String
    var year: Int?
    var url: URL
    var accessed: String
}

/// Loads and indexes the bundled curriculum.
nonisolated struct ContentLibrary: Sendable {
    let curriculum: Curriculum
    let sources: [String: ContentSource]

    var tracks: [Curriculum.Track] { curriculum.tracks.sorted { $0.order < $1.order } }

    /// Lessons in the order "today's lesson" suggests them. Uses the curriculum's
    /// recommended daily path, then any lessons it doesn't list, interleaved by track.
    var suggestedOrder: [Curriculum.Lesson] {
        let byID = Dictionary(uniqueKeysWithValues: curriculum.lessons.map { ($0.id, $0) })
        let path = (curriculum.dailyPath ?? []).compactMap { byID[$0] }
        let listed = Set(path.map(\.id))
        return path + interleaved.filter { !listed.contains($0.id) }
    }

    private var interleaved: [Curriculum.Lesson] {
        let trackOrder = Dictionary(uniqueKeysWithValues: curriculum.tracks.map { ($0.id, $0.order) })
        return curriculum.lessons.sorted {
            ($0.order, trackOrder[$0.track] ?? .max) < ($1.order, trackOrder[$1.track] ?? .max)
        }
    }

    func lessons(in track: Curriculum.Track) -> [Curriculum.Lesson] {
        curriculum.lessons.filter { $0.track == track.id }.sorted { $0.order < $1.order }
    }

    func track(for lesson: Curriculum.Lesson) -> Curriculum.Track? {
        curriculum.tracks.first { $0.id == lesson.track }
    }

    func sources(for lesson: Curriculum.Lesson) -> [ContentSource] {
        lesson.sourceIds.compactMap { sources[$0] }
    }

    /// Next lesson to suggest, or `nil` when everything is done.
    func todaysLesson(completed: Set<String>) -> Curriculum.Lesson? {
        suggestedOrder.first { !completed.contains($0.id) }
    }

    /// Bloom when every Essential lesson is done; Sprout a third of the way there.
    var growthThresholds: NanaRules.Thresholds {
        let essential = max(curriculum.lessons.filter { $0.tier == .essential }.count, 1)
        return .init(sprout: max(1, Int((Double(essential) / 3).rounded(.up))), bloom: essential)
    }

    // MARK: Loading

    static let bundled: ContentLibrary = {
        do {
            return try load(from: .main)
        } catch {
            assertionFailure("Bundled content failed to load: \(error)")
            return ContentLibrary(curriculum: .init(version: 0, tracks: [], dailyPath: nil, lessons: []), sources: [:])
        }
    }()

    static func load(from bundle: Bundle, language: String? = Locale.current.language.languageCode?.identifier) throws -> ContentLibrary {
        let decoder = JSONDecoder()
        let curriculum = try decoder.decode(Curriculum.self, from: data(named: "curriculum", language: language, in: bundle))
        let sources = try decoder.decode([ContentSource].self, from: data(named: "sources", language: language, in: bundle))
        return ContentLibrary(curriculum: curriculum, sources: Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) }))
    }

    /// Looks for `name-<lang>.json` first (e.g. a future `curriculum-id.json`), then `name.json`.
    private static func data(named name: String, language: String?, in bundle: Bundle) throws -> Data {
        let localized = language.flatMap { bundle.url(forResource: "\(name)-\($0)", withExtension: "json") }
        guard let url = localized ?? bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
        }
        return try Data(contentsOf: url)
    }

    // MARK: Validation

    /// Every rule a lesson must meet before it ships. Used by the unit tests.
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
