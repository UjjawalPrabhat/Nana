import SwiftData
import SwiftUI

/// Opens from the left-behind nudge: what happened and two ways to answer it.
struct StayedBehindView: View {
    @Query(SupplyEvent.latest) private var events: [SupplyEvent]
    @Environment(LeftBehindNudge.self) private var leftBehind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // "Last connected 5 minutes ago" and the snooze note change with time alone.
        TimelineView(.periodic(from: .now, by: 30)) { _ in content }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                NanaIconButton("Close", systemImage: "xmark") { dismiss() }
            }

            Text("Your Pod stayed behind")
                .nanaScreenTitle()
                .padding(.top, 6)
            if let since = leftBehind.disconnectedSince {
                Text("Last connected \(since, format: .relative(presentation: .named)).")
                    .padding(.top, 18)
            }

            VStack(spacing: 18) {
                PodView(count: count, isDimmed: true, scale: 0.8)
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
            }

            VStack(spacing: 12) {
                Button("Remind me in \(Int(LeftBehindRules.snoozeLength / 60)) min") { leftBehind.snooze() }
                    .nanaPrimaryButton()
                Button("I left it on purpose") {
                    leftBehind.leftOnPurpose()
                    dismiss()
                }
                .nanaSecondaryButton()
                Text("Nudges stop once your Pod reconnects.")
                    .font(.nanaFootnote)
                    .foregroundStyle(.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .scrollsAtAccessibilitySizes()
        .nanaScreen()
        .animation(.default, value: leftBehind.snoozedUntil)
        // Back in range: nothing is left behind any more.
        .onChange(of: leftBehind.disconnectedSince) { _, since in
            if since == nil { dismiss() }
        }
    }

    private var count: Int? {
        events.first?.status.count
    }
}

#if DEBUG
#Preview {
    StayedBehindView()
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
}
#endif
