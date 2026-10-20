import SwiftData
import SwiftUI

/// Learn tab: Nana's corner, today's lesson, and topics.
struct LearnView: View {
    @Environment(\.contentLibrary) private var library

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
                    TodayLessonCard(lesson: library.todaysLesson(completed: completedIDs)) {
                        activeLesson = $0
                    }

                    HStack {
                        Text("Topics").font(.title3.bold())
                        Spacer()
                        NavigationLink("All topics") { TopicLibraryView() }
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 4)

                    FlowLayout(spacing: 8) {
                        ForEach(library.tracks) { track in
                            NavigationLink {
                                TrackLessonsView(track: track)
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
            LessonPlayerView(lesson: lesson)
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

