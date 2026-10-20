import SwiftUI

/// "Today's lesson" card, used on Learn and Home.
struct TodayLessonCard: View {
    var lesson: Curriculum.Lesson?
    @Environment(\.contentLibrary) private var library
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

struct GrowthProgressCard: View {
    var snapshot: NanaSnapshot

    var body: some View {
        NanaCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Nana · \(snapshot.stage.title)")
                        .font(.headline)
                    Spacer()
                    if let progress = snapshot.progressToNextStage, let next = snapshot.nextStage {
                        Text("\(progress.done) of \(progress.total) to \(next.title)")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        Text("Fully grown")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                if let progress = snapshot.progressToNextStage {
                    ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1)))
                        .tint(.brandGreen)
                }
            }
            .foregroundStyle(Color.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}
