import SwiftUI

/// Large −/+ number picker from the "Add refill" design. Behaves like a native
/// adjustable control for VoiceOver (swipe up/down to change the value).
struct CountStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var accessibilityLabel: LocalizedStringKey

    var body: some View {
        HStack {
            stepButton(systemImage: "minus", delta: -1)
                .disabled(value <= range.lowerBound)

            Text(value, format: .number)
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
                .frame(maxWidth: .infinity)

            stepButton(systemImage: "plus", delta: 1)
                .disabled(value >= range.upperBound)
        }
        .padding(10)
        .background(Color.surface, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).strokeBorder(Color.hairline, lineWidth: 1)
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(Text(value, format: .number))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: change(by: 1)
            case .decrement: change(by: -1)
            @unknown default: break
            }
        }
    }

    private func stepButton(systemImage: String, delta: Int) -> some View {
        Button {
            change(by: delta)
        } label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.roundedRectangle(radius: 12))
    }

    private func change(by delta: Int) {
        let next = min(max(value + delta, range.lowerBound), range.upperBound)
        guard next != value else { return }
        withAnimation(.snappy) { value = next }
    }
}

#Preview {
    @Previewable @State var value = 6
    CountStepper(value: $value, range: 0...12, accessibilityLabel: "Amount")
        .padding()
        .nanaCanvas()
}
