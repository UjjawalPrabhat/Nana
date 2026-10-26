import SwiftData
import SwiftUI

/// Opens from the left-behind nudge: what happened and two ways to answer it.
struct StayedBehindView: View {
    @Query(sort: \SupplyEvent.date) private var events: [SupplyEvent]
    @Environment(LeftBehindNudge.self) private var leftBehind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button("Close", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.nightInk)
                    .frame(width: 46, height: 46)
                    .background(Color.card, in: .rect(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.nightInk, lineWidth: 2.5) }
            }

            Text("Your charm stayed behind")
                .font(.nanaTitle)
                .lineHeight(.multiple(factor: 0.9))
                .foregroundStyle(.cobalt)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 6)
            if let since = leftBehind.disconnectedSince {
                Text("Last connected \(since, format: .relative(presentation: .named)).")
                    .padding(.top, 18)
            }

            VStack(spacing: 18) {
                CharmView(count: count, isDimmed: true, scale: 0.85)
                    .rotationEffect(.degrees(-4))
                if let since = leftBehind.disconnectedSince {
                    StatusChip(
                        text: Text("Out of range since \(since.formatted(date: .omitted, time: .shortened))"),
                        dot: .stale
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let snoozedUntil = leftBehind.snoozedUntil, snoozedUntil > .now {
                Text("Got it. Nana nudges you again at \(snoozedUntil.formatted(date: .omitted, time: .shortened)).")
                    .font(.nanaLabel)
                    .nanaCard(.banana, cornerRadius: 20, padding: 14)
                    .padding(.bottom, 12)
                    .accessibilityAddTraits(.isStaticText)
            }

            VStack(spacing: 12) {
                Button("Remind me in 15 min") { leftBehind.snooze() }
                    .nanaPrimaryButton()
                Button("I left it on purpose") {
                    leftBehind.leftOnPurpose()
                    dismiss()
                }
                .buttonStyle(NanaSecondaryButtonStyle(stroke: .nightInk, fill: .card))
                Text("Nudges stop once your charm reconnects.")
                    .font(.nanaFootnote)
                    .foregroundStyle(.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .nanaScreen()
        .animation(.default, value: leftBehind.snoozedUntil)
    }

    private var count: Int? {
        SupplyLedger.status(for: events.map(\.ledgerEntry))?.count
    }
}

#if DEBUG
#Preview {
    StayedBehindView()
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
}
#endif
