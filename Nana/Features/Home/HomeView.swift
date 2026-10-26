import SwiftData
import SwiftUI

/// One charm, one number. Reads the app's state and hands it to `HomeContent`.
struct HomeView: View {
    @Query(sort: \SupplyEvent.date) private var events: [SupplyEvent]
    @Environment(ContainerStore.self) private var containerStore
    @Environment(LeftBehindNudge.self) private var leftBehind
    @Environment(AppRouter.self) private var router
    @State private var isFixingCount = false

    var body: some View {
        // Left behind is time based, so check it again every half minute.
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HomeContent(
                state: state(at: context.date),
                awaySince: leftBehind.disconnectedSince,
                onFixCount: { isFixingCount = true },
                onOpenGuide: { router.cover = .guide },
                onOpenSettings: { router.showsSettings = true }
            )
        }
        .sheet(isPresented: $isFixingCount) {
            FixCountSheet(currentCount: status?.count)
        }
    }

    private var status: SupplyLedger.Status? {
        SupplyLedger.status(for: events.map(\.ledgerEntry))
    }

    private func state(at date: Date) -> HomeState {
        #if DEBUG
        if let sample = HomeState.launchArgumentSample { return sample }
        #endif
        return HomeState.make(
            status: status,
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
    var onFixCount: () -> Void
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
            Button(action: onFixCount) {
                VStack(alignment: .leading, spacing: 16) {
                    count
                    chips
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens Fix count")
            .padding(.top, state.variant == .away ? 14 : 28)

            Spacer(minLength: 12)
            Button(action: onFixCount) {
                ViewThatFits(in: .vertical) {
                    CharmView(count: state.charmCount, isDimmed: state.variant == .away)
                    CharmView(count: state.charmCount, isDimmed: state.variant == .away, scale: 0.7)
                }
                .rotationEffect(.degrees(-4))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens Fix count")
            .frame(maxWidth: .infinity)
            Spacer(minLength: 12)

            HomeTiles(onOpenGuide: onOpenGuide)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var header: some View {
        HStack {
            Wordmark()
            Spacer()
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.nightInk)
                    .frame(width: 46, height: 46)
                    .background(Color.card, in: .rect(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.nightInk, lineWidth: 2.5) }
            }
            .accessibilityLabel("Settings")
        }
    }

    private var awayBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 22, weight: .semibold))
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
        .accessibilityAddTraits(.updatesFrequently)
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
                        onFixCount: {}, onOpenGuide: {}, onOpenSettings: {})
        }
    }
    .tabViewStyle(.page)
    .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
}
#endif
