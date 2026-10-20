import SwiftData
import SwiftUI

struct TopicLibraryView: View {
    @Environment(\.contentLibrary) private var library

    @Query private var completions: [LessonCompletion]

    var body: some View {
        let done = Set(completions.map(\.lessonID))
        List(library.tracks) { track in
            let lessons = library.lessons(in: track)
            NavigationLink {
                TrackLessonsView(track: track)
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
    @Environment(\.contentLibrary) private var library

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
            LessonPlayerView(lesson: lesson)
        }
    }
}
