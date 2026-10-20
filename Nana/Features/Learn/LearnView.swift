import SwiftData
import SwiftUI

/// Learn tab: Nana's corner, today's lesson, and topics.
struct LearnView: View {
    var library: ContentLibrary = .bundled

    @Environment(NanaCompanion.self) private var companion
    @Query private var completions: [LessonCompletion]
    @State private var activeLesson: Curriculum.Lesson?

    private var completedIDs: Set<String> { Set(completions.map(\.lessonID)) }

    var body: some View {
        let snapshot = companion.snapshot(library: library, completions: completions)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    NanaCorner(snapshot: snapshot, message: message(for: snapshot.mood))
                        .onTapGesture { wake() }
                    GrowthProgressCard(snapshot: snapshot)
                    TodayLessonCard(lesson: library.todaysLesson(completed: completedIDs), library: library) {
                        activeLesson = $0
                    }

                    HStack {
                        Text("Topics").font(.title3.bold())
                        Spacer()
                        NavigationLink("All topics") { TopicLibraryView(library: library) }
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 4)

                    FlowLayout(spacing: 8) {
                        ForEach(library.tracks) { track in
                            NavigationLink {
                                TrackLessonsView(track: track, library: library)
                            } label: {
                                Text(track.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.surface, in: .capsule)
                                    .overlay { Capsule().strokeBorder(Color.hairline) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .nanaCanvas()
            .navigationTitle("Learn")
        }
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonPlayerView(lesson: lesson, library: library)
        }
        .task {
            // Nana wakes up shortly after greeting a returning user.
            guard snapshot.mood == .resting else { return }
            try? await Task.sleep(for: .seconds(3))
            wake()
        }
    }

    private func wake() {
        withAnimation(.smooth) { companion.hasGreeted = true }
    }

    private func message(for mood: NanaMood) -> LocalizedStringKey {
        switch mood {
        case .curious: "Ready for today? It takes about a minute."
        case .happy: "That was a good one. Come back any day, or keep going."
        case .resting: "Oh, hi! I was resting. Good to see you."
        case .proud: "Look, I grew!"
        }
    }
}

private struct NanaCorner: View {
    var snapshot: NanaSnapshot
    var message: LocalizedStringKey

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Color.surfaceMuted
                Circle()
                    .fill(Color.peach.opacity(0.7))
                    .frame(width: 230)
                    .offset(y: 20)
                NanaView(stage: snapshot.stage, mood: snapshot.mood)
                    .frame(width: 170, height: 170)
                    .offset(y: 30)
            }
            .frame(height: 290)
            .clipShape(.rect(cornerRadius: 26))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .padding(12)
                .frame(maxWidth: 210, alignment: .leading)
                .background(Color.surface, in: .rect(cornerRadius: 14))
                .padding(14)
                .id(snapshot.mood)
                .transition(.opacity)
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Today's lesson" card, used on Learn and Home.
struct TodayLessonCard: View {
    var lesson: Curriculum.Lesson?
    var library: ContentLibrary
    var onStart: (Curriculum.Lesson) -> Void

    var body: some View {
        NanaCard {
            if let lesson {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's lesson · \(library.track(for: lesson)?.title ?? "") · \(lesson.minutes) min")
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                        Text(lesson.title)
                            .font(.title3.bold())
                            .foregroundStyle(Color.textPrimary)
                    }
                    Button {
                        onStart(lesson)
                    } label: {
                        Text("Start lesson").frame(maxWidth: .infinity)
                    }
                    .nanaPrimaryButton()
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You've finished every lesson")
                        .font(.title3.bold())
                        .foregroundStyle(Color.textPrimary)
                    Text("New lessons are on the way. You can revisit any topic below.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

struct TopicLibraryView: View {
    var library: ContentLibrary

    @Query private var completions: [LessonCompletion]

    var body: some View {
        let done = Set(completions.map(\.lessonID))
        List(library.tracks) { track in
            let lessons = library.lessons(in: track)
            NavigationLink {
                TrackLessonsView(track: track, library: library)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: track.symbol)
                        .foregroundStyle(Color.brandGreen)
                        .frame(width: 40, height: 40)
                        .background(Color.surfaceMuted, in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title).font(.headline)
                        Text("\(lessons.filter { done.contains($0.id) }.count) of \(lessons.count) done")
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .listRowBackground(Color.surface)
        }
        .scrollContentBackground(.hidden)
        .nanaCanvas()
        .navigationTitle("All topics")
    }
}

struct TrackLessonsView: View {
    var track: Curriculum.Track
    var library: ContentLibrary

    @Query private var completions: [LessonCompletion]
    @State private var activeLesson: Curriculum.Lesson?

    var body: some View {
        let done = Set(completions.map(\.lessonID))
        List {
            Section {
                ForEach(library.lessons(in: track)) { lesson in
                    Button {
                        activeLesson = lesson
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.title)
                                    .foregroundStyle(Color.textPrimary)
                                Text("\(lesson.minutes) min")
                                    .font(.footnote)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            if done.contains(lesson.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.brandGreen)
                                    .accessibilityLabel("Done")
                            }
                        }
                    }
                    .listRowBackground(Color.surface)
                }
            } footer: {
                Text(track.summary)
            }
        }
        .scrollContentBackground(.hidden)
        .nanaCanvas()
        .navigationTitle(track.title)
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonPlayerView(lesson: lesson, library: library)
        }
    }
}

/// Wraps chips onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews: subviews, width: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !current.indices.isEmpty, current.width + spacing + size.width > width {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }
            current.width += (current.indices.isEmpty ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
