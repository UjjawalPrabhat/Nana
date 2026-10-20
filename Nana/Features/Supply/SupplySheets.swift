import SwiftData
import SwiftUI

/// "How many did you add?" sheet.
struct AddRefillSheet: View {
    var currentCount: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var amount: Int

    init(currentCount: Int) {
        self.currentCount = currentCount
        _amount = State(initialValue: min(3, SupplyLedger.maxRefill(currentCount: currentCount)))
    }

    private var maxRefill: Int { SupplyLedger.maxRefill(currentCount: currentCount) }

    var body: some View {
        SupplyEditor(
            title: "Add refill",
            question: "How many did you add?",
            hint: "Enter a whole number from 1 to \(maxRefill).",
            saveTitle: "Save refill",
            canSave: amount > 0
        ) {
            CountStepper(value: $amount, range: min(1, maxRefill)...maxRefill, accessibilityLabel: "Amount added")
            SummaryRows(rows: [
                ("Current count", currentCount, false),
                ("New total", currentCount + amount, true),
            ])
        } onSave: {
            modelContext.insert(SupplyEvent(kind: .refill, amount: amount))
            dismiss()
        }
    }
}

/// Lets the user correct the count to an exact number.
struct AdjustCountSheet: View {
    var currentCount: Int?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var count: Int

    init(currentCount: Int?) {
        self.currentCount = currentCount
        _count = State(initialValue: currentCount ?? 0)
    }

    var body: some View {
        SupplyEditor(
            title: currentCount == nil ? "Set count" : "Adjust count",
            question: "How many do you have right now?",
            hint: "Count what's in your container. Enter 0 to \(SupplyLedger.capacity).",
            saveTitle: "Save count",
            canSave: count != currentCount
        ) {
            CountStepper(value: $count, range: 0...SupplyLedger.capacity, accessibilityLabel: "Current count")
        } onSave: {
            modelContext.insert(SupplyEvent(kind: .adjust, amount: count))
            dismiss()
        }
    }
}

/// Shared layout for the supply sheets: question, editor, footnote, save button.
private struct SupplyEditor<Editor: View>: View {
    var title: LocalizedStringKey
    var question: LocalizedStringKey
    var hint: LocalizedStringKey
    var saveTitle: LocalizedStringKey
    var canSave: Bool
    @ViewBuilder var editor: Editor
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(question)
                        .font(.title2.bold())
                        .foregroundStyle(Color.textPrimary)
                    editor
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                    Text("Saved on this iPhone only.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onSave) {
                    Text(saveTitle).frame(maxWidth: .infinity)
                }
                .nanaPrimaryButton()
                .disabled(!canSave)
                .padding(20)
            }
            .nanaCanvas()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

private struct SummaryRows: View {
    var rows: [(LocalizedStringKey, Int, Bool)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 { Divider() }
                HStack {
                    Text(row.0)
                    Spacer()
                    Text(row.1, format: .number).monospacedDigit()
                }
                .font(row.2 ? .body.weight(.semibold) : .body)
                .foregroundStyle(row.2 ? Color.textPrimary : Color.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
            }
        }
        .background(Color.surface, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Color.hairline, lineWidth: 1) }
    }
}

#Preview("Add refill") {
    AddRefillSheet(currentCount: 6)
        .modelContainer(for: SupplyEvent.self, inMemory: true)
}
