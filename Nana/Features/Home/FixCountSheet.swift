import SwiftData
import SwiftUI

/// Sets the count by hand when the charm's reading looks wrong. The charm
/// takes over again with its next reading.
struct FixCountSheet: View {
    var currentCount: Int?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var count: Int

    init(currentCount: Int?) {
        self.currentCount = currentCount
        _count = State(initialValue: currentCount ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Fix the count")
                .font(.nanaHeading)
                .lineHeight(.multiple(factor: 0.98))
                .foregroundStyle(.cobalt)
                .accessibilityAddTraits(.isHeader)
            Text("How many are in your charm right now? Your charm updates this again next time it connects.")
                .font(.nanaCallout)

            CharmView(count: count, scale: 0.6)
                .frame(maxWidth: .infinity)

            ChoiceRow(title: "Count", options: Array(0...SupplyLedger.capacity), selection: $count) {
                Text($0, format: .number)
            }

            Button("Save") {
                modelContext.insert(SupplyEvent(kind: .adjust, amount: count))
                try? modelContext.save()
                dismiss()
            }
            .nanaPrimaryButton()
            .disabled(count == currentCount)
        }
        .padding(24)
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.butter)
        .foregroundStyle(.nightInk)
    }
}

#Preview {
    Text("Home")
        .sheet(isPresented: .constant(true)) { FixCountSheet(currentCount: 2) }
        .modelContainer(for: SupplyEvent.self, inMemory: true)
}
