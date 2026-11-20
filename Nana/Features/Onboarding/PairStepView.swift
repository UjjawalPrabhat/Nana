import SwiftUI

/// "Squeeze to pair". The Pair button opens Apple's accessory sheet, which
/// also grants Bluetooth for just this charm.
struct PairStepView: View {
    var onContinue: () -> Void

    @Environment(ContainerStore.self) private var containerStore
    @State private var phase: Phase = .ready
    /// The status icon's tile grows with the text beside it.
    @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = 44

    enum Phase {
        case ready, searching, paired, failed

        var title: LocalizedStringResource {
            switch self {
            case .ready: "Nana charm"
            case .searching: "Looking for your charm"
            case .paired: "Paired"
            case .failed: "No charm found"
            }
        }

        var detail: LocalizedStringResource {
            switch self {
            case .ready: "When the light blinks, tap Pair."
            case .searching: "Keep it close to your phone."
            case .paired: "Your charm is ready."
            case .failed: "Hold the side button for 3 seconds, then try again."
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Squeeze\nto pair")
                .nanaScreenTitle()
                .padding(.bottom, 18)
            Text("Hold the button on the side of your charm for 3 seconds, until the light blinks.")

            ClosedCharm(phase: phase)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statusCard

            VStack(spacing: 6) {
                switch phase {
                case .ready: Button("Pair", action: pair).nanaPrimaryButton()
                case .searching: Button("Looking nearby") {}.nanaSecondaryButton(stroke: .cobalt, fill: .clear).disabled(true)
                case .paired: Button("Continue", action: onContinue).nanaPrimaryButton()
                case .failed: Button("Try again", action: pair).nanaPrimaryButton()
                }
                if phase != .paired {
                    Button("The light isn’t blinking") { phase = .failed }
                        .nanaLinkButton(color: .cobalt)
                        .underline()
                    Button("No charm yet? Try a demo", action: tryDemo)
                        .nanaLinkButton(color: .cobalt)
                    Button("Skip for now", action: onContinue)
                        .nanaLinkButton()
                }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .scrollsAtAccessibilitySizes()
        .nanaScreen()
        .animation(.default, value: phase)
        .onAppear { if containerStore.isPaired { phase = .paired } }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.body.bold())
                .foregroundStyle(phase == .paired ? Color.butter : .nightInk)
                .symbolEffect(.rotate, isActive: phase == .searching)
                .frame(width: tileSize, height: tileSize)
                .background(chipFill, in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.nightInk, lineWidth: 2.5) }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.title).font(.nana(.textBold, size: 17))
                Text(phase.detail).font(.nanaCallout).foregroundStyle(.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 46)
        .nanaCard(cornerRadius: 22, padding: 14)
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch phase {
        case .ready: "dot.radiowaves.left.and.right"
        case .searching: "arrow.trianglehead.2.clockwise"
        case .paired: "checkmark"
        case .failed: "exclamationmark"
        }
    }

    private var chipFill: Color {
        switch phase {
        case .ready, .searching: .banana
        case .paired: .cobalt
        case .failed: .tangerine
        }
    }

    private func tryDemo() {
        Task {
            await containerStore.startDemo()
            phase = .paired
        }
    }

    private func pair() {
        phase = .searching
        Task {
            let paired = (try? await containerStore.pair()) ?? false
            phase = paired ? .paired : .failed
        }
    }
}

extension View {
    /// Shown when pairing from Home or Settings fails. A cancelled sheet isn't a failure.
    func pairingFailedAlert(isPresented: Binding<Bool>) -> some View {
        alert("Your charm couldn't be paired", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Hold its button for 3 seconds, keep it next to your phone and try again.")
        }
    }
}

/// The charm from the side, with its pairing button and light.
private struct ClosedCharm: View {
    var phase: PairStepView.Phase

    var body: some View {
        ZStack {
            if phase == .ready || phase == .searching {
                Circle()
                    .strokeBorder(.cobalt, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    .frame(width: 300, height: 300)
                    .opacity(0.35)
                Circle()
                    .strokeBorder(.cobalt, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    .frame(width: 220, height: 220)
                    .opacity(0.6)
            }
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 56)
                    .fill(.lilac)
                    .overlay { RoundedRectangle(cornerRadius: 56).strokeBorder(.nightInk, lineWidth: 3) }
                    .background { RoundedRectangle(cornerRadius: 56).fill(.cobalt).offset(x: 7, y: 7) }
                    .frame(width: 206, height: 140)
                Capsule()
                    .fill(.white.opacity(0.75))
                    .frame(width: 54, height: 11)
                    .rotationEffect(.degrees(-10))
                    .offset(x: 30, y: 16)
                Capsule()
                    .fill(ledColor)
                    .overlay { Capsule().strokeBorder(.nightInk, lineWidth: 2) }
                    .frame(width: 22, height: 8)
                    .offset(x: 92, y: 104)
                UnevenRoundedRectangle(bottomTrailingRadius: 8, topTrailingRadius: 8)
                    .fill(.tangerine)
                    .overlay {
                        UnevenRoundedRectangle(bottomTrailingRadius: 8, topTrailingRadius: 8)
                            .strokeBorder(.nightInk, lineWidth: 3)
                    }
                    .frame(width: 16, height: 40)
                    .offset(x: 202, y: 48)
            }
            .frame(width: 220, height: 150, alignment: .topLeading)
        }
        .accessibilityElement()
        .accessibilityLabel("Closed Nana charm with the pairing button on its right side")
    }

    private var ledColor: Color {
        switch phase {
        case .paired: .banana
        case .failed: .staleStripe
        case .ready, .searching: .white
        }
    }
}
