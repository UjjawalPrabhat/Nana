import SwiftUI

struct SupplyCard: View {
    var status: SupplyLedger.Status?
    var level: SupplyLedger.Level
    var onAddRefill: () -> Void
    var onAdjust: () -> Void

    var body: some View {
        NanaCard {
            VStack(alignment: .leading, spacing: 14) {
                badge

                if let status {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(status.count, format: .number)
                                .font(.system(size: 56, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText(value: Double(status.count)))
                            Text("remaining")
                                .font(.title3.weight(.medium))
                        }
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityElement(children: .combine)

                        Text(provenance(for: status))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No count yet")
                            .font(.title2.bold())
                            .foregroundStyle(Color.textPrimary)
                        Text("Set how many you have now, and Nana will keep track.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { buttons }
                    VStack(spacing: 10) { buttons }
                }
            }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        if status == nil {
            Button(action: onAdjust) {
                Text("Set count").frame(maxWidth: .infinity)
            }
            .nanaPrimaryButton()
        } else {
            Button(action: onAddRefill) {
                Label("Add refill", systemImage: "plus").frame(maxWidth: .infinity)
            }
            .nanaPrimaryButton()
            .disabled(SupplyLedger.maxRefill(currentCount: status?.count ?? 0) == 0)

            Button(action: onAdjust) {
                Text("Adjust count").frame(maxWidth: .infinity)
            }
            .nanaSecondaryButton()
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch level {
        case .notSet:
            StatusBadge(title: "Not set", systemImage: "questionmark", tone: .neutral)
        case .empty:
            StatusBadge(title: "Empty", systemImage: "exclamationmark", tone: .warning)
        case .low:
            StatusBadge(title: "Running low", systemImage: "arrow.down", tone: .warning)
        case .available:
            StatusBadge(title: "Supply available", systemImage: "checkmark", tone: .positive)
        }
    }

    private func provenance(for status: SupplyLedger.Status) -> String {
        let who = switch status.source {
        case .user: String(localized: "Confirmed by you")
        case .container: String(localized: "Reported by container")
        }
        return "\(who) · \(status.updatedAt.nanaRelativeDescription)"
    }
}

extension Date {
    /// "Today at 14:32", "Yesterday at 09:10", or "12 Oct at 18:05".
    var nanaRelativeDescription: String {
        let time = formatted(date: .omitted, time: .shortened)
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return String(localized: "Today at \(time)")
        }
        if calendar.isDateInYesterday(self) {
            return String(localized: "Yesterday at \(time)")
        }
        let day = formatted(.dateTime.day().month(.abbreviated))
        return String(localized: "\(day) at \(time)")
    }
}

#Preview {
    VStack {
        SupplyCard(
            status: .init(count: 6, updatedAt: .now, source: .user),
            level: .available, onAddRefill: {}, onAdjust: {}
        )
        SupplyCard(status: nil, level: .notSet, onAddRefill: {}, onAdjust: {})
    }
    .padding()
    .nanaCanvas()
}
