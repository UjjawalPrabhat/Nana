import SwiftData
import SwiftUI

/// Full-screen lesson: cards → quick check → completion.
struct LessonPlayerView: View {
    var lesson: Curriculum.Lesson
    @Environment(\.contentLibrary) private var library

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(NanaCompanion.self) private var companion
    @Query private var completions: [LessonCompletion]

    @State private var page = 0
    @State private var selectedOption: Int?
    @State private var result: CompletionResult?

    struct CompletionResult {
        var snapshot: NanaSnapshot
        var grew: Bool
    }

    private var pageCount: Int { lesson.cards.count + 1 }
    private var isQuickCheck: Bool { page == lesson.cards.count }

    var body: some View {
        NavigationStack {
            Group {
                if let result {
                    LessonCompleteView(lesson: lesson, result: result) { dismiss() }
                } else {
                    VStack(spacing: 0) {
                        ProgressSegments(count: pageCount, current: page)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        ScrollView {
                            Group {
                                if isQuickCheck {
                                    QuickCheckView(check: lesson.quickCheck, selection: $selectedOption)
                                } else {
                                    LessonCardView(card: lesson.cards[page], track: library.track(for: lesson))
                                }
                            }
                            .padding(20)
                            .id(page)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                    removal: .opacity))
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        footer
                    }
                }
            }
            .nanaCanvas()
            .toolbar {
                if result == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", systemImage: "xmark") { dismiss() }
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            SourceLine(sources: library.sources(for: lesson), review: lesson.review)
            Button {
                advance()
            } label: {
                Text(isQuickCheck ? "Finish lesson" : "Next").frame(maxWidth: .infinity)
            }
            .nanaPrimaryButton()
            .disabled(isQuickCheck && selectedOption == nil)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func advance() {
        if isQuickCheck {
            finish()
        } else {
            withAnimation(.snappy) { page += 1 }
        }
    }

    private func finish() {
        let before = companion.snapshot(library: library, completions: completions)
        var all = completions
        if !completions.contains(where: { $0.lessonID == lesson.id }) {
            let completion = LessonCompletion(lessonID: lesson.id)
            modelContext.insert(completion)
            all.append(completion)
        }
        var after = companion.snapshot(library: library, completions: all)
        let grew = after.stage > before.stage
        after.mood = grew ? .proud : .happy
        withAnimation(.smooth) { result = CompletionResult(snapshot: after, grew: grew) }
    }
}

// MARK: - Pieces

private struct ProgressSegments: View {
    var count: Int
    var current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.brandGreen : Color.hairline)
                    .frame(height: 5)
            }
        }
        .animation(.snappy, value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

struct LessonCardView: View {
    var card: Curriculum.Lesson.Card
    var track: Curriculum.Track?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            hero

            VStack(alignment: .leading, spacing: 8) {
                if let eyebrow = card.eyebrow {
                    Text(eyebrow)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandGreen)
                }
                Text(card.headline)
                    .font(.title.bold())
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let body = card.body {
                    Text(body)
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let steps = card.steps {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(index + 1, format: .number)
                                    .font(.footnote.weight(.semibold))
                                    .frame(width: 24, height: 24)
                                    .background(Color.peachSoft, in: .circle)
                                Text(step)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 4)
                }
            }

            if let tip = card.nanaTip {
                NanaTip(text: tip)
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        if card.kind == .stat, let stat = card.stat {
            VStack(spacing: 6) {
                Text(stat)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if let caption = card.statCaption {
                    Text(caption)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(Color.textPrimary)
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(Color.peachSoft, in: .rect(cornerRadius: 24))
            .accessibilityElement(children: .combine)
        } else if card.kind == .text {
            Image(systemName: track?.symbol ?? "leaf")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.brandGreen)
                .frame(maxWidth: .infinity, minHeight: 150)
                .background(Color.surfaceMuted, in: .rect(cornerRadius: 24))
                .accessibilityHidden(true)
        }
    }
}

struct NanaTip: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NanaView(stage: .sprout, mood: .happy, isCompact: true)
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)
            Text("Nana tip: \(text)")
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Color.hairline) }
    }
}

struct QuickCheckView: View {
    var check: Curriculum.Lesson.QuickCheck
    @Binding var selection: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick check")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandGreen)
            Text(check.question)
                .font(.title2.bold())
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(check.options.enumerated()), id: \.offset) { index, option in
                Button {
                    withAnimation(.snappy) { selection = index }
                } label: {
                    optionRow(index: index, text: option)
                }
                .buttonStyle(.plain)
                .disabled(selection != nil)
            }

            if let selection {
                HStack(alignment: .top, spacing: 12) {
                    NanaView(stage: .sprout, mood: .happy, isCompact: true)
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selection == check.answerIndex ? "That's right." : "Good to know.")
                            .font(.headline)
                        Text(check.explanation)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(Color.textPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceMuted, in: .rect(cornerRadius: 16))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .accessibilityElement(children: .combine)
            }

            Text("Every answer gets the same calm explanation. No scores are kept.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private func optionRow(index: Int, text: String) -> some View {
        let isAnswer = index == check.answerIndex
        let revealed = selection != nil
        let isSelected = selection == index
        return HStack(spacing: 12) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(isSelected ? Color.brandGreen : Color.textSecondary)
            Text(text)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if revealed, isAnswer {
                Label("Correct", systemImage: "checkmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brandGreen)
            }
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(revealed && isAnswer ? Color.brandGreen : Color.hairline, lineWidth: revealed && isAnswer ? 2 : 1)
        }
        .contentShape(.rect)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SourceLine: View {
    var sources: [ContentSource]
    var review: Curriculum.Lesson.Review

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(sources) { source in
                Link(destination: source.url) {
                    Text("Source: \(source.publisher), \(source.title)\(source.year.map { " (\($0))" } ?? "")")
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            Text(review.reviewer.map { "Reviewed by \($0)" } ?? String(localized: "Content review: pending."))
        }
        .font(.caption)
        .foregroundStyle(Color.textSecondary)
        .tint(Color.textSecondary)
    }
}

struct LessonCompleteView: View {
    var lesson: Curriculum.Lesson
    var result: LessonPlayerView.CompletionResult
    var onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                NanaView(stage: result.snapshot.stage, mood: result.snapshot.mood)
                    .frame(width: 190, height: 190)
                    .padding(20)
                    .background(Color.peach.opacity(0.6), in: .circle)
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    Text(result.grew ? "Nana reached \(result.snapshot.stage.title)!" : "Lesson saved")
                        .font(.title.bold())
                    Text(result.grew
                         ? "Every lesson you finish helps Nana grow."
                         : "Nana is growing. Come back any day you like.")
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Color.textPrimary)

                GrowthProgressCard(snapshot: result.snapshot)

                if lesson.getHelp != .none {
                    GetHelpCard(kind: lesson.getHelp)
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onDone) {
                Text("Done").frame(maxWidth: .infinity)
            }
            .nanaPrimaryButton()
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .sensoryFeedback(.success, trigger: result.grew)
    }
}

extension Curriculum.Track {
    var symbol: String {
        switch id {
        case "protection": "shield"
        case "stis": "cross.case"
        case "hiv": "heart.text.clipboard"
        case "testing": "testtube.2"
        case "consent": "bubble.left.and.bubble.right"
        case "body": "figure"
        case "myths": "questionmark.bubble"
        default: "leaf"
        }
    }
}
