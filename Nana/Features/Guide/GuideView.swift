import SwiftUI

/// The fruit stand: one step at a time, on the model you pick.
struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: GuideStep.Model = .banana
    /// The page on screen: a step, or `steps.count` for the done card.
    @State private var page: Int? = 0
    @State private var dotsWidth: CGFloat = 0

    private var steps: [GuideStep] { GuideStep.steps(for: model) }
    private var index: Int { page ?? 0 }
    private var isDone: Bool { index >= steps.count }

    /// Moves like a swipe would, so buttons, dots and fingers all agree.
    private func go(to newPage: Int) {
        withAnimation(.snappy) { page = min(max(newPage, 0), steps.count) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                ModelPicker(model: $model)
                    .padding(.top, 8)
                pager
                    .padding(.top, 14)
                dots
                    .padding(.top, 16)
                controls
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .nanaScreen()
            .toolbarVisibility(.hidden, for: .navigationBar)
            .onChange(of: model) { page = 0 }
            .animation(.snappy, value: index)
        }
    }

    private var header: some View {
        HStack {
            NanaIconButton("Close", systemImage: "xmark") { dismiss() }
            Spacer()
            Text("The fruit stand")
                .font(.nanaWordmark)
                .foregroundStyle(.cobalt)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Text(isDone ? "Done" : "\(index + 1) / \(steps.count)")
                .accessibilityLabel(isDone ? Text("Done") : Text("Step \(index + 1) of \(steps.count)"))
                .font(.nanaLabelSmall)
                .foregroundStyle(.inkSoft)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    /// Swipe left or right between steps, one card at a time.
    private var pager: some View {
        ScrollView(.horizontal) {
            // The gap keeps the neighbouring cards off screen at rest; the scroll view
            // doesn't clip, so each card's offset shadow stays visible.
            LazyHStack(spacing: 40) {
                ForEach(0...steps.count, id: \.self) { page in
                    ticket(for: page)
                        .containerRelativeFrame(.horizontal)
                        .id(page)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .id(model)  // a new model starts a fresh pager at step 1
    }

    private func ticket(for page: Int) -> some View {
        Group {
            if page < steps.count {
                StepCard(step: steps[page], model: model, number: page + 1)
            } else {
                DoneCard()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.card)
        .clipShape(.rect(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(.nightInk, lineWidth: 3) }
        .background { RoundedRectangle(cornerRadius: 28).fill(.cobalt).offset(x: 6, y: 6) }
    }

    /// Tap a dot to jump to it, or press and slide along the row to scrub through
    /// the steps.
    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { dot in
                Capsule()
                    .fill(dot <= index ? Color.cobalt : .lilac)
                    .frame(width: dot == index ? 26 : 8, height: 8)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 36)
        .contentShape(.rect)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { dotsWidth = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let dot = dot(at: drag.location.x)
                    if dot != index { go(to: dot) }
                }
        )
        .sensoryFeedback(.selection, trigger: index)
        // Back and Next already cover this for VoiceOver.
        .accessibilityHidden(true)
    }

    /// The step under a finger at `x`. The row is split into equal parts rather than
    /// using each dot's frame: the current dot is wider, so measuring the real dots
    /// would shift them under the finger and make the scrub flicker.
    private func dot(at x: CGFloat) -> Int {
        guard dotsWidth > 0 else { return index }
        let part = dotsWidth / CGFloat(steps.count)
        return min(max(Int(x / part), 0), steps.count - 1)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Back") { go(to: index - 1) }
                .nanaSecondaryButton()
                .disabled(index == 0)
            if isDone {
                Button("Home") { dismiss() }
                    .nanaSecondaryButton(fill: .banana)
            } else {
                Button(index == steps.count - 1 ? "Finish" : "Next") { go(to: index + 1) }
                    .nanaPrimaryButton()
            }
        }
    }
}

/// Banana or eggplant, as two halves of one card.
private struct ModelPicker: View {
    @Binding var model: GuideStep.Model

    var body: some View {
        HStack(spacing: 0) {
            option(.banana, title: "Uncut", subtitle: "Banana model", image: .fruitBanana, angle: -10)
            Line()
                .stroke(.nightInk, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .frame(width: 1.5)
            option(.eggplant, title: "Cut", subtitle: "Eggplant model", image: .fruitEggplant, angle: 8)
        }
        .frame(minHeight: 126)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.lilac)
        .clipShape(.rect(cornerRadius: 26))
        .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(.nightInk, lineWidth: 3) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Choose a model")
    }

    private func option(
        _ value: GuideStep.Model,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        image: ImageResource,
        angle: Double
    ) -> some View {
        let isSelected = model == value
        return Button {
            model = value
        } label: {
            HStack(spacing: 10) {
                Image(image)
                    .rotationEffect(.degrees(angle))
                    .offset(y: isSelected ? -4 : 4)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.nana(.extraBold, size: 22, relativeTo: .title3))
                    Text(subtitle).font(.nanaCaption)
                    Text(isSelected ? "Showing" : "Tap to switch")
                        .font(.nana(.textBold, size: 12, relativeTo: .caption2))
                        .foregroundStyle(.cobalt)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.nightInk)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? Color.card : .clear)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A straight rule through the middle of its frame.
private nonisolated struct Line: Shape {
    var axis: Axis = .vertical

    func path(in rect: CGRect) -> Path {
        Path { path in
            switch axis {
            case .vertical:
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            case .horizontal:
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

/// One step as a ticket: the drawing, a torn edge, then the words.
private struct StepCard: View {
    var step: GuideStep
    var model: GuideStep.Model
    var number: Int

    var body: some View {
        VStack(spacing: 0) {
            illustration
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 236)
                .background(Color.slotCream)
            perforation
            HStack(alignment: .top, spacing: 14) {
                Text(number, format: .number.precision(.integerLength(2)))
                    .font(.nana(.condensedExtraBold, size: 64, relativeTo: .largeTitle))
                    .foregroundStyle(.cobalt)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(step.title)
                        .font(.nanaHeading)
                        .lineHeight(.multiple(factor: 0.98))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(step.body)
                        .font(.nanaCallout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            Spacer(minLength: 0)
        }
        .scrollsAtAccessibilitySizes()
    }

    private var illustration: some View {
        ZStack(alignment: .topLeading) {
            Image(step.image(for: model))
            ForEach(Array(step.labels.enumerated()), id: \.offset) { _, label in
                Text(label.text)
                    .font(.nana(.textBold, size: 12.5, relativeTo: .caption))
                    .fixedSize()
                    .rotationEffect(.degrees(label.angle))
                    .position(x: label.x, y: label.y)
                    .dynamicTypeSize(.large)
            }
        }
        .frame(width: 240, height: 220)
        .accessibilityElement()
        .accessibilityLabel(Text(step.accessibilityDescription(for: model)))
        .accessibilityAddTraits(.isImage)
    }

    /// Dashed tear line with half-circle notches, like a ticket stub.
    private var perforation: some View {
        Line(axis: .horizontal)
            .stroke(.nightInk, style: StrokeStyle(lineWidth: 2.5, dash: [6, 5]))
            .frame(height: 1)
            .padding(.horizontal, 18)
            .overlay {
                HStack {
                    notch.offset(x: -15)
                    Spacer()
                    notch.offset(x: 15)
                }
            }
            .accessibilityHidden(true)
    }

    private var notch: some View {
        Circle()
            .fill(.butter)
            .overlay { Circle().strokeBorder(.nightInk, lineWidth: 3) }
            .frame(width: 26, height: 26)
    }
}

private struct DoneCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(.nightInk)
                .frame(width: 92, height: 92)
                .background(Color.banana, in: .rect(cornerRadius: 30))
                .overlay { RoundedRectangle(cornerRadius: 30).strokeBorder(.nightInk, lineWidth: 3) }
                .rotationEffect(.degrees(-6))
                .padding(.bottom, 22)
                .accessibilityHidden(true)
            Text("Ready.")
                .font(.nana(.condensedExtraBold, size: 88, relativeTo: .largeTitle))
                .lineHeight(.multiple(factor: 0.86))
                .accessibilityAddTraits(.isHeader)
            Text("The fruit stand stays open. Come back any time.")
                .padding(.top, 12)
            NavigationLink {
                HealthSafetyView().nanaBackButton()
            } label: {
                Text("If a condom breaks or slips")
                    .nanaPill(.butter)
            }
            .padding(.top, 18)
        }
        .foregroundStyle(.butter)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .scrollsAtAccessibilitySizes()
        .background(Color.cobalt)
    }
}

#if DEBUG
#Preview {
    GuideView()
}
#endif
