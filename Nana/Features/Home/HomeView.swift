import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \SupplyEvent.date) private var events: [SupplyEvent]
    @AppStorage(AppSettings.lowSupplyThreshold) private var lowThreshold = AppSettings.defaultLowSupplyThreshold
    @AppStorage(AppSettings.lowSupplyReminderOn) private var reminderOn = false

    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case addRefill(current: Int)
        case adjust(current: Int?)
        case pair

        var id: String {
            switch self {
            case .addRefill: "addRefill"
            case .adjust: "adjust"
            case .pair: "pair"
            }
        }
    }

    private var status: SupplyLedger.Status? {
        SupplyLedger.status(for: events.map(\.ledgerEntry))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    SupplyCard(
                        status: status,
                        level: SupplyLedger.level(of: status, lowThreshold: lowThreshold),
                        onAddRefill: { sheet = .addRefill(current: status?.count ?? 0) },
                        onAdjust: { sheet = .adjust(current: status?.count) }
                    )

                    ContainerRow { sheet = .pair }

                    reminderRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .nanaCanvas()
            .navigationTitle("Your supply")
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .addRefill(let current): AddRefillSheet(currentCount: current)
            case .adjust(let current): AdjustCountSheet(currentCount: current)
            case .pair: PairContainerView { _ in self.sheet = nil }
            }
        }
    }

    private var reminderRow: some View {
        HStack(spacing: 12) {
            Image(systemName: reminderOn ? "bell" : "bell.slash")
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(reminderOn ? "Reminders are on" : "Reminders are off")
                    .font(.subheadline.weight(.semibold))
                Text("Change this in Settings.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .foregroundStyle(Color.textPrimary)
        .padding(16)
        .background(Color.surfaceMuted, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(ContainerStore.preview())
}
