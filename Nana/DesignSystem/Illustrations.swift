import SwiftUI

/// The enamel charm with one slot per condom. Drawn at the board's 320×220
/// and scaled, so every screen shows the same object.
struct CharmView: View {
    /// `nil` when the count isn't known; the slots are striped.
    var count: Int?
    var capacity = SupplyLedger.capacity
    /// Out of range: drawn at half strength.
    var isDimmed = false
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .strokeBorder(.cobalt, lineWidth: 7)
                .frame(width: 44, height: 44)
                .offset(x: 18)
            RoundedRectangle(cornerRadius: 7)
                .fill(.butter)
                .overlay { RoundedRectangle(cornerRadius: 7).strokeBorder(.nightInk, lineWidth: 4) }
                .frame(width: 14, height: 18)
                .offset(x: 33, y: 34)
            charmBody(width: 296, height: 170)
                .offset(x: 10, y: 40)
        }
        .frame(width: 320, height: 220, alignment: .topLeading)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: 320 * scale, height: 220 * scale, alignment: .topLeading)
        .opacity(isDimmed ? 0.5 : 1)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private func charmBody(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 64)
            .fill(.lilac)
            .overlay { RoundedRectangle(cornerRadius: 64).strokeBorder(.nightInk, lineWidth: 3) }
            .background {
                RoundedRectangle(cornerRadius: 64).fill(.cobalt).offset(x: 7, y: 7)
            }
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(.white.opacity(0.75))
                    .frame(width: 64, height: 12)
                    .rotationEffect(.degrees(-10))
                    .offset(x: 34, y: 16)
            }
            .overlay {
                HStack(spacing: 14) {
                    ForEach(0..<capacity, id: \.self) { index in
                        CharmSlot(state: slotState(at: index))
                    }
                }
            }
            .frame(width: width, height: height)
    }

    private func slotState(at index: Int) -> CharmSlot.State {
        guard let count else { return .unknown }
        return index < count ? .filled : .empty
    }

    private var accessibilityText: Text {
        guard let count else { return Text("Nana charm, count not updated") }
        return Text("Nana charm holding \(count) of \(capacity)")
    }
}

private struct CharmSlot: View {
    enum State {
        case filled, empty, unknown
    }

    var state: State

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.slotCream)
            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.nightInk, lineWidth: 3) }
            .frame(width: 72, height: 72)
            .overlay { content }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .filled:
            RoundedRectangle(cornerRadius: 10)
                .fill(.banana)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.nightInk, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                        .padding(6)
                }
                .overlay { Circle().strokeBorder(.nightInk, lineWidth: 3).frame(width: 22, height: 22) }
                .frame(width: 50, height: 50)
        case .empty:
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.cobalt, style: StrokeStyle(lineWidth: 2.5, dash: [5, 4]))
                .frame(width: 46, height: 46)
        case .unknown:
            Stripes()
                .fill(.staleStripe)
                .background(.lilac)
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 50, height: 50)
        }
    }
}

/// 45° stripes, 4pt on and 4pt off, for a slot whose state isn't known.
private nonisolated struct Stripes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 8 * 2.squareRoot()
        var x = -rect.height
        while x < rect.width {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            path.addLine(to: CGPoint(x: x + rect.height + step / 2, y: rect.minY))
            path.addLine(to: CGPoint(x: x + step / 2, y: rect.maxY))
            path.closeSubpath()
            x += step
        }
        return path
    }
}

/// The charm in miniature, for list rows.
struct CharmBadge: View {
    var count: Int?
    var capacity = SupplyLedger.capacity

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<capacity, id: \.self) { index in
                let filled = count.map { index < $0 } ?? false
                RoundedRectangle(cornerRadius: 3)
                    .fill(filled ? Color.banana : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(filled ? Color.nightInk : .cobalt,
                                          style: StrokeStyle(lineWidth: 1.5, dash: filled ? [] : [2, 2]))
                    }
                    .frame(width: 9, height: 9)
            }
        }
        .frame(width: 58, height: 40)
        .background(Color.card, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.nightInk, lineWidth: 2.5) }
        .accessibilityHidden(true)
    }
}

/// The "n" tile from the app icon and the lock-screen preview.
struct AppMark: View {
    var size: CGFloat = 36

    var body: some View {
        Text(verbatim: "n")
            .font(.custom("BricolageGrotesque-ExtraBold", size: size / 2, relativeTo: .body))
            .foregroundStyle(.cobalt)
            .frame(width: size, height: size)
            .background(Color.butter, in: .rect(cornerRadius: size * 0.28))
            .overlay { RoundedRectangle(cornerRadius: size * 0.28).strokeBorder(.nightInk, lineWidth: 2) }
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        CharmView(count: 2).rotationEffect(.degrees(-4))
        CharmView(count: nil, scale: 0.6)
        CharmView(count: 1, isDimmed: true, scale: 0.6)
        CharmBadge(count: 2)
    }
    .padding()
    .nanaScreen()
}
