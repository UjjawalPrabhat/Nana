import SwiftData
import SwiftUI

/// One charm, one number. Reads the app's state and hands it to `HomeContent`.
struct HomeView: View {
    @Query(SupplyEvent.latest) private var events: [SupplyEvent]
    @Environment(ContainerStore.self) private var containerStore
    @Environment(LeftBehindNudge.self) private var leftBehind
    @Environment(AppRouter.self) private var router
    @State private var pairingFailed = false

    var body: some View {
        // Left behind is time based, so check it again every half minute.
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HomeContent(
                state: state(at: context.date),
                awaySince: leftBehind.disconnectedSince,
                isDemo: containerStore.isDemoRunning,
                onPair: pair,
                onTryDemo: { Task { await containerStore.startDemo() } },
                onOpenGuide: { router.cover = .guide },
                onOpenSettings: { router.showsSettings = true }
            )
        }
        .pairingFailedAlert(isPresented: $pairingFailed)
    }

    private func pair() {
        Task {
            // A cancelled sheet returns false; only real errors are shown.
            do { _ = try await containerStore.pair() } catch { pairingFailed = true }
        }
    }

    private func state(at date: Date) -> HomeState {
        #if DEBUG
        if let sample = HomeState.launchArgumentSample { return sample }
        #endif
        return HomeState.make(
            status: events.first?.status,
            connection: containerStore.connection,
            isLeftBehind: leftBehind.isLeftBehind(at: date)
        )
    }
}

/// Home's layout for a given state, with no app dependencies of its own
/// apart from the left-behind tile.
struct HomeContent: View {
    var state: HomeState
    var awaySince: Date?
    var isDemo = false
    var onPair: () -> Void
    var onTryDemo: () -> Void
    var onOpenGuide: () -> Void
    var onOpenSettings: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // One screen, no scrolling, unless the text is too big to fit.
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { layout }
            } else {
                layout
            }
        }
        .nanaScreen()
    }

    private var layout: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if state.variant == .away {
                awayBanner.padding(.top, 12)
            }
            VStack(alignment: .leading, spacing: 16) {
                count
                chips
            }
            .accessibilityElement(children: .combine)
            .padding(.top, state.variant == .away ? 14 : 28)

            Spacer(minLength: 12)
            ViewThatFits(in: .vertical) {
                CharmView(count: state.charmCount, isDimmed: state.variant == .away)
                CharmView(count: state.charmCount, isDimmed: state.variant == .away, scale: 0.7)
            }
            .rotationEffect(.degrees(-4))
            .frame(maxWidth: .infinity)
            Spacer(minLength: 12)

            if !state.isPaired {
                // Without a charm Home has nothing to count, so lead the way to one.
                VStack(spacing: 4) {
                    Button("Pair your charm", action: onPair)
                        .nanaPrimaryButton()
                    Button("No charm yet? Try a demo", action: onTryDemo)
                        .nanaLinkButton(color: .cobalt)
                }
                .padding(.bottom, 12)
            }

            HomeTiles(onOpenGuide: onOpenGuide)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Wordmark()
            if isDemo {
                NoteChip(text: Text("Demo charm"))
                    .accessibilityLabel("Using the demo charm")
            }
            Spacer()
            NanaIconButton("Settings", systemImage: "gearshape", action: onOpenSettings)
        }
    }

    private var awayBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.title2.weight(.semibold))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Your charm stayed behind").font(.nanaLabel)
                if let awaySince {
                    Text("Out of range since \(awaySince.formatted(date: .omitted, time: .shortened))")
                        .font(.nanaFootnote)
                }
            }
            Spacer(minLength: 0)
        }
        .nanaCard(.tangerine, cornerRadius: 20, padding: 12)
        .accessibilityElement(children: .combine)
    }

    private var count: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            Text(state.countText)
                .font(state.variant == .away ? .nanaCountSmall : .nanaCount)
                .foregroundStyle(state.isStale ? Color.stale : .cobalt)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Text(state.countLabel)
                .font(.nanaCountLabel)
                .lineHeight(.multiple(factor: 0.95))
                .foregroundStyle(.cobalt)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var chips: some View {
        HStack(spacing: 10) {
            StatusChip(text: Text(state.statusText), dot: state.isStale ? .stale : .cobalt)
            if let note = state.note {
                NoteChip(text: Text(note))
            }
        }
    }
}

#if DEBUG
#Preview("Every state") {
    TabView {
        ForEach(HomeState.Variant.allCases, id: \.self) { variant in
            HomeContent(state: .sample(variant), awaySince: .now.addingTimeInterval(-480),
                        onPair: {}, onTryDemo: {}, onOpenGuide: {}, onOpenSettings: {})
        }
    }
    .tabViewStyle(.page)
    .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
}
#endif
