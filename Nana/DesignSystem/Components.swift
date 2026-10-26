import SwiftUI

// MARK: Buttons

/// Full-width Cobalt button with the hard Night Ink drop: the main action on a screen.
struct NanaPrimaryButtonStyle: ButtonStyle {
    var fill: Color = .cobalt
    var foreground: Color = .butter

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.nanaButton)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(fill, in: .rect(cornerRadius: 20))
            .offset(y: pressed ? 4 : 0)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.nightInk)
                    .offset(y: 5)
            }
            .padding(.bottom, 5)
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(.rect)
    }
}

/// Full-width outlined button: the second choice next to a primary one.
struct NanaSecondaryButtonStyle: ButtonStyle {
    var stroke: Color = .cobalt
    var fill: Color = .clear

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nanaButton)
            .foregroundStyle(stroke)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(fill, in: .rect(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(stroke, lineWidth: 3) }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(.rect)
    }
}

/// Small outlined pill, e.g. "Allow notifications" or "Done".
struct NanaPillButtonStyle: ButtonStyle {
    var isOn = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nanaLabel)
            .foregroundStyle(isOn ? Color.butter : .nightInk)
            .padding(.horizontal, 18)
            .frame(minHeight: 46)
            .background(isOn ? Color.cobalt : .card, in: .rect(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.nightInk, lineWidth: 2.5) }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(.rect)
    }
}

/// Bold text button with a 44pt target, e.g. "Skip for now".
struct NanaLinkButtonStyle: ButtonStyle {
    var color: Color = .nightInk

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nanaLabel)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(.rect)
    }
}

extension View {
    func nanaPrimaryButton() -> some View {
        buttonStyle(NanaPrimaryButtonStyle())
    }

    func nanaSecondaryButton() -> some View {
        buttonStyle(NanaSecondaryButtonStyle())
    }

    func nanaLinkButton(color: Color = .nightInk) -> some View {
        buttonStyle(NanaLinkButtonStyle(color: color))
    }
}

// MARK: Surfaces

extension View {
    /// The board's outlined card: 3pt Night Ink border on a flat fill.
    func nanaCard(_ fill: Color = .card, cornerRadius: CGFloat = 24, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.nightInk, lineWidth: 3)
            }
    }

    /// Butter ground for a whole screen.
    func nanaScreen() -> some View {
        self
            .foregroundStyle(.nightInk)
            .font(.nanaBody)
            .background(Color.butter.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

/// A card of rows split by Lilac rules, like the board's Settings groups.
struct RowGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    if row.id != rows.first?.id {
                        Rectangle()
                            .fill(.lilac)
                            .frame(height: 2)
                            .padding(.leading, 18)
                            .accessibilityHidden(true)
                    }
                    row
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                }
            }
        }
        .background(Color.card, in: .rect(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.nightInk, lineWidth: 3) }
    }
}

/// Row text with an optional second line.
struct RowLabel: View {
    var title: Text
    var detail: Text?

    init(_ title: LocalizedStringKey, detail: Text? = nil) {
        self.init(title: Text(title), detail: detail)
    }

    init(title: Text, detail: Text? = nil) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            title.font(.nanaLabel)
            if let detail {
                detail.font(.nanaFootnote).foregroundStyle(.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Small parts

/// Lilac pill with a status dot: "Connected, just now".
struct StatusChip: View {
    var text: Text
    var dot: Color = .cobalt

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(dot).frame(width: 9, height: 9).accessibilityHidden(true)
            text.font(.nanaLabelSmall)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 34)
        .background(Color.lilac, in: .capsule)
        .overlay { Capsule().strokeBorder(.nightInk, lineWidth: 2.5) }
    }
}

/// Tangerine sticker for the one thing that needs attention: "Running low".
struct NoteChip: View {
    var text: Text

    var body: some View {
        text
            .font(.nanaLabelSmall)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .background(Color.tangerine, in: .capsule)
            .overlay { Capsule().strokeBorder(.nightInk, lineWidth: 2.5) }
            .rotationEffect(.degrees(-3))
    }
}

/// Rounded square holding an SF Symbol, as used beside rows and card titles.
struct IconTile: View {
    var systemImage: String
    var fill: Color = .banana
    var size: CGFloat = 40
    var isDashed = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(isDashed ? Color.cobalt : .nightInk)
            .frame(width: size, height: size)
            .background(fill, in: .rect(cornerRadius: size / 3))
            .overlay {
                RoundedRectangle(cornerRadius: size / 3)
                    .strokeBorder(isDashed ? Color.cobalt : .nightInk,
                                  style: StrokeStyle(lineWidth: 2.5, dash: isDashed ? [5, 4] : []))
            }
            .accessibilityHidden(true)
    }
}

/// "nana" in the display face.
struct Wordmark: View {
    var body: some View {
        Text(verbatim: "nana")
            .font(.nanaWordmark)
            .foregroundStyle(.cobalt)
            .accessibilityLabel("Nana")
            .accessibilityAddTraits(.isHeader)
    }
}

/// "2 of 4" in onboarding.
struct StepCounter: View {
    var step: Int
    var total: Int

    var body: some View {
        Text("\(step) of \(total)")
            .font(.nanaLabelSmall)
            .foregroundStyle(.inkSoft)
    }
}

// MARK: Controls

/// The board's outlined switch. Keeps `Toggle`'s accessibility and behaviour.
/// For a switch with no visible label, pass an empty label and set `accessibilityLabel`.
struct NanaToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                Capsule()
                    .fill(configuration.isOn ? Color.cobalt : .lilac)
                    .overlay { Capsule().strokeBorder(.nightInk, lineWidth: 2.5) }
                    .frame(width: 60, height: 36)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .overlay { Circle().strokeBorder(.nightInk, lineWidth: 2) }
                            .frame(width: 27, height: 27)
                            .padding(4.5)
                    }
                    .animation(.snappy(duration: 0.2), value: configuration.isOn)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

/// Equal pills where exactly one is picked, e.g. "1 min · 2 min · 5 min".
/// One row by default; pass `columns` to wrap longer labels into a grid.
struct ChoiceRow<Value: Hashable>: View {
    var title: LocalizedStringKey
    var options: [Value]
    @Binding var selection: Value
    var columns: Int?
    var label: (Value) -> Text

    init(
        title: LocalizedStringKey,
        options: [Value],
        selection: Binding<Value>,
        columns: Int? = nil,
        label: @escaping (Value) -> Text
    ) {
        self.title = title
        self.options = options
        _selection = selection
        self.columns = columns
        self.label = label
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns ?? options.count),
                  spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    label(option)
                        .font(.nanaLabelSmall)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(isSelected ? Color.butter : .nightInk)
                        .background(isSelected ? Color.cobalt : .card, in: .rect(cornerRadius: 14))
                        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.nightInk, lineWidth: 2.5) }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("Section").nanaCaptionStyle()
            Button("Get started") {}.nanaPrimaryButton()
            Button("Looking nearby") {}.nanaSecondaryButton()
            Button("Skip for now") {}.nanaLinkButton()
            HStack {
                StatusChip(text: Text("Connected, just now"))
                NoteChip(text: Text("Running low"))
            }
            RowGroup {
                Toggle(isOn: .constant(true)) { RowLabel("Left behind", detail: Text("Outside your places")) }
                    .toggleStyle(NanaToggleStyle())
                Text("Reconnect").font(.nanaLabel)
            }
            ChoiceRow(title: "Wait", options: [1, 2, 5], selection: .constant(2)) { Text("\($0) min") }
        }
        .padding(24)
    }
    .nanaScreen()
}
