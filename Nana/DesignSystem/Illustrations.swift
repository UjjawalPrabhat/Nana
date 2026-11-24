import SwiftUI

/// The Nana Pod, front on: a Cobalt case with the cream "n" cropped by its bottom
/// edge, on a keyring. With a known count the lid is open and that many wrappers
/// stand inside; otherwise it's shut. Drawn at 220×270 and scaled, so every screen
/// shows the same object.
struct PodView: View {
    /// `nil` when the count isn't known: the lid stays shut.
    var count: Int?
    /// Out of range: shut and drawn at half strength.
    var isDimmed = false
    var scale: CGFloat = 1

    private var isOpen: Bool { count != nil && !isDimmed }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hard shadow of the whole case, like every card in the app.
            PodShape(isOpen: isOpen).fill(.nightInk).offset(x: 7, y: 7)
            if isOpen { openLid }
            if isOpen { wrappers }
            podBody
            if !isOpen { PodLid(light: .slotCream) }
            keyring
        }
        .frame(width: 220, height: 270, alignment: .topLeading)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: 220 * scale, height: 270 * scale, alignment: .topLeading)
        .opacity(isDimmed ? 0.5 : 1)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var podBody: some View {
        UnevenRoundedRectangle(bottomLeadingRadius: Pod.radius, bottomTrailingRadius: Pod.radius)
            .fill(.cobalt)
            .overlay(alignment: .bottom) {
                // The "n" is as wide as the icon's on a 1024 canvas, sitting on the bottom edge.
                NanaGlyph().fill(.butter).frame(width: Pod.width, height: Pod.width)
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Pod.radius, bottomTrailingRadius: Pod.radius))
            .overlay {
                UnevenRoundedRectangle(bottomLeadingRadius: Pod.radius, bottomTrailingRadius: Pod.radius)
                    .strokeBorder(.nightInk, lineWidth: 3)
            }
            .frame(width: Pod.width, height: Pod.bodyHeight)
            .offset(x: Pod.x, y: Pod.lidBottom)
    }

    /// Tipped back on its hinge, showing its underside.
    private var openLid: some View {
        UnevenRoundedRectangle(topLeadingRadius: Pod.radius, topTrailingRadius: Pod.radius)
            .fill(Color.cobalt.mix(with: .nightInk, by: 0.35))
            .overlay {
                UnevenRoundedRectangle(topLeadingRadius: Pod.radius, topTrailingRadius: Pod.radius)
                    .strokeBorder(.nightInk, lineWidth: 3)
            }
            .frame(width: Pod.width, height: 34)
            .rotationEffect(.degrees(-14), anchor: .bottomTrailing)
            .offset(x: Pod.x, y: Pod.lidBottom - 64)
    }

    /// One wrapper per condom, standing in the slots front to back.
    private var wrappers: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<min(count ?? 0, SupplyLedger.capacity), id: \.self) { slot in
                PodWrapper()
                    .offset(x: Pod.x + 14 + CGFloat(2 - slot) * 10, y: Pod.lidBottom - 44 - CGFloat(2 - slot) * 10)
            }
        }
    }

    private var keyring: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .strokeBorder(.nightInk, lineWidth: 6)
                .frame(width: 42, height: 42)
            RoundedRectangle(cornerRadius: 5)
                .fill(.butter)
                .overlay { RoundedRectangle(cornerRadius: 5).strokeBorder(.nightInk, lineWidth: 3) }
                .frame(width: 12, height: 18)
                .offset(x: 26, y: 34)
        }
        .offset(x: 6, y: isOpen ? Pod.lidBottom - 42 : 6)
    }

    private var accessibilityText: Text {
        guard let count else { return Text("Nana Pod, count not updated") }
        return Text("Nana Pod holding \(count) of \(SupplyLedger.capacity)")
    }
}

/// The Pod's shared measurements on PodView's 220×270 canvas.
private nonisolated enum Pod {
    static let x: CGFloat = 30
    static let width: CGFloat = 160
    static let radius: CGFloat = 26
    static let lidTop: CGFloat = 46
    static let lidBottom: CGFloat = 92
    static let bodyHeight: CGFloat = 170
}

/// The shut lid, with the status light on its front.
private struct PodLid: View {
    var light: Color

    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: Pod.radius, topTrailingRadius: Pod.radius)
            .fill(.cobalt)
            .overlay {
                UnevenRoundedRectangle(topLeadingRadius: Pod.radius, topTrailingRadius: Pod.radius)
                    .strokeBorder(.nightInk, lineWidth: 3)
            }
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(.white.opacity(0.55))
                    .frame(width: 46, height: 8)
                    .offset(x: 30, y: 12)
            }
            .overlay {
                Circle()
                    .fill(light)
                    .overlay { Circle().strokeBorder(.nightInk, lineWidth: 2) }
                    .frame(width: 12, height: 12)
                    .offset(y: 6)
            }
            .frame(width: Pod.width, height: Pod.lidBottom - Pod.lidTop)
            .offset(x: Pod.x, y: Pod.lidTop)
    }
}

/// A condom wrapper standing in its slot.
private struct PodWrapper: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.banana)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(.nightInk, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .padding(6)
            }
            .overlay(alignment: .top) {
                Circle().strokeBorder(.nightInk, lineWidth: 3).frame(width: 22, height: 22).offset(y: 12)
            }
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(.nightInk, lineWidth: 3) }
            .frame(width: 92, height: 70)
    }
}

/// The case's outline (lid and body together), for its shadow.
private nonisolated struct PodShape: Shape {
    var isOpen: Bool

    func path(in rect: CGRect) -> Path {
        let top = isOpen ? Pod.lidBottom : Pod.lidTop
        return Path(roundedRect: CGRect(x: Pod.x, y: top, width: Pod.width, height: Pod.lidBottom + Pod.bodyHeight - top),
                    cornerRadius: Pod.radius)
    }
}

/// The closed Pod on the pairing screen, with its pair button on the right side
/// and the status light showing how pairing is going.
struct ClosedPodView: View {
    var light: Color
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            PodShape(isOpen: false).fill(.nightInk).offset(x: 7, y: 7)
            // Pair button, on the right side.
            UnevenRoundedRectangle(bottomTrailingRadius: 6, topTrailingRadius: 6)
                .fill(.tangerine)
                .overlay {
                    UnevenRoundedRectangle(bottomTrailingRadius: 6, topTrailingRadius: 6)
                        .strokeBorder(.nightInk, lineWidth: 3)
                }
                .frame(width: 14, height: 40)
                .offset(x: Pod.x + Pod.width - 3, y: Pod.lidBottom + 28)
            UnevenRoundedRectangle(bottomLeadingRadius: Pod.radius, bottomTrailingRadius: Pod.radius)
                .fill(.cobalt)
                .overlay(alignment: .bottom) {
                    NanaGlyph().fill(.butter).frame(width: Pod.width, height: Pod.width)
                }
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Pod.radius, bottomTrailingRadius: Pod.radius))
                .overlay {
                    UnevenRoundedRectangle(bottomLeadingRadius: Pod.radius, bottomTrailingRadius: Pod.radius)
                        .strokeBorder(.nightInk, lineWidth: 3)
                }
                .frame(width: Pod.width, height: Pod.bodyHeight)
                .offset(x: Pod.x, y: Pod.lidBottom)
            PodLid(light: light)
        }
        .frame(width: 220, height: 270, alignment: .topLeading)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: 220 * scale, height: 270 * scale, alignment: .topLeading)
    }
}

/// The Pod in miniature with a dot per condom, for list rows.
struct PodBadge: View {
    var count: Int?

    var body: some View {
        HStack(spacing: 6) {
            UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: 4)
                .fill(.cobalt)
                .overlay(alignment: .bottom) { NanaGlyph().fill(.butter).frame(width: 20, height: 20) }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: 4))
                .frame(width: 20, height: 27)
            VStack(spacing: 3) {
                ForEach(0..<SupplyLedger.capacity, id: \.self) { index in
                    let filled = count.map { index < $0 } ?? false
                    Circle()
                        .fill(filled ? Color.banana : .clear)
                        .overlay {
                            Circle().strokeBorder(filled ? Color.nightInk : .cobalt,
                                                  style: StrokeStyle(lineWidth: 1.5, dash: filled ? [] : [2, 2]))
                        }
                        .frame(width: 7, height: 7)
                }
            }
        }
        .frame(width: 58, height: 40)
        .background(Color.card, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.nightInk, lineWidth: 2.5) }
        .accessibilityHidden(true)
    }
}

/// The "n" tile from the app icon, for the lock-screen preview.
struct AppMark: View {
    var body: some View {
        NanaGlyph()
            .fill(.butter)
            .frame(width: 36, height: 36)
            .background(Color.cobalt)
            .clipShape(.rect(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.nightInk, lineWidth: 2) }
            .accessibilityHidden(true)
    }
}

/// Nana's "n", cropped by the bottom edge, in a square the size of the app icon.
/// The same outline is printed on the Pod (`brand.py` in the Nana Pod repo) and
/// drawn by `Tools/AppIcon/render.swift`, all in 1024-pixel icon coordinates.
nonisolated struct NanaGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let unit = rect.width / 1024
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * unit, y: rect.minY + y * unit)
        }
        // The top of the arch and of the counter: a squarish (superelliptic) curve.
        func arch(cx: CGFloat, cy: CGFloat, a: CGFloat, b: CGFloat) -> [CGPoint] {
            (0...60).map { step in
                let t = CGFloat.pi * CGFloat(step) / 60
                let c = cos(t), s = sin(t)
                let x = cx + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / 2.4)
                return point(x, cy - b * pow(abs(s), 2 / 2.4))
            }
        }
        func polygon(_ points: [CGPoint]) -> CGPath {
            let path = CGMutablePath()
            path.addLines(between: points)
            path.closeSubpath()
            return path
        }
        let stem = polygon([point(243, 1024), point(243, 189), point(424, 189), point(424, 1024)])
        let bridge = polygon([point(420, 1024), point(420, 467), point(475, 467), point(475, 1024)])
        let outer = polygon([point(782, 1024)] + arch(cx: 612, cy: 470, a: 170, b: 301) + [point(442, 1024)])
        let counter = polygon([point(563, 1100)] + arch(cx: 512, cy: 560, a: 51, b: 166) + [point(461, 1100)])
        return Path(stem.union(bridge).union(outer).subtracting(counter))
    }
}

#if DEBUG
#Preview {
    ScrollView {
        HStack(alignment: .top) {
            PodView(count: 2).rotationEffect(.degrees(-4))
            PodView(count: 0, scale: 0.6)
        }
        HStack(alignment: .top) {
            PodView(count: nil, scale: 0.6)
            PodView(count: 3, isDimmed: true, scale: 0.6)
            ClosedPodView(light: .banana, scale: 0.6)
        }
        HStack {
            PodBadge(count: 2)
            AppMark()
        }
    }
    .padding()
    .nanaScreen()
}
#endif
