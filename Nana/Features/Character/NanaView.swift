import SwiftUI

/// Nana, drawn natively from the character-sheet SVGs (120×120 design space).
struct NanaView: View {
    var stage: NanaStage
    var mood: NanaMood
    /// Small avatars skip the ground shadow and idle motion.
    var isCompact = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || isCompact)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            Canvas { gc, size in
                let scale = min(size.width, size.height) / 120
                gc.translateBy(x: (size.width - 120 * scale) / 2, y: (size.height - 120 * scale) / 2)
                gc.scaleBy(x: scale, y: scale)
                NanaDrawing(stage: stage, mood: mood, motion: motion(at: time), showsShadow: !isCompact)
                    .draw(in: &gc)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Text("Nana, \(stage.title) stage, \(mood.title)"))
    }

    private func motion(at time: TimeInterval) -> NanaDrawing.Motion {
        guard !reduceMotion, !isCompact else { return .still }
        let breathe = sin(time * 2 * .pi / 3.2)
        // A quick blink every ~4.5 seconds.
        let blinkPhase = time.truncatingRemainder(dividingBy: 4.5)
        let blink = blinkPhase < 0.14 ? 0.1 : 1
        return .init(
            squash: 1 + 0.018 * breathe,
            leafAngle: .degrees(4 * sin(time * 2 * .pi / 2.6)),
            eyeOpenness: mood == .curious || mood == .happy ? blink : 1,
            floatOffset: mood == .resting ? 0 : -1.2 * breathe
        )
    }
}

/// Stateless renderer; everything is in the SVG's 120×120 coordinate space.
struct NanaDrawing {
    struct Motion {
        var squash: CGFloat
        var leafAngle: Angle
        var eyeOpenness: CGFloat
        var floatOffset: CGFloat

        static let still = Motion(squash: 1, leafAngle: .zero, eyeOpenness: 1, floatOffset: 0)
    }

    var stage: NanaStage
    var mood: NanaMood
    var motion: Motion = .still
    var showsShadow = true

    private enum Palette {
        static let body = Color(red: 0xBF / 255, green: 0xE6 / 255, blue: 0xD6 / 255)
        static let outline = Color(red: 0x24 / 255, green: 0x69 / 255, blue: 0x5B / 255)
        static let ink = Color(red: 0x20 / 255, green: 0x2B / 255, blue: 0x29 / 255)
        static let cheek = Color(red: 0xF1 / 255, green: 0xC7 / 255, blue: 0xB5 / 255)
        static let petalEdge = Color(red: 0xDF / 255, green: 0xAE / 255, blue: 0x98 / 255)
        static let gold = Color(red: 0xF0 / 255, green: 0xCC / 255, blue: 0x84 / 255)
        static let sleepy = Color(red: 0x52 / 255, green: 0x62 / 255, blue: 0x5D / 255)
    }

    func draw(in gc: inout GraphicsContext) {
        if showsShadow {
            let shadow = stage == .seed
                ? CGRect(x: 36, y: 104, width: 48, height: 8)
                : CGRect(x: 28, y: 105, width: 64, height: 10)
            gc.fill(Path(ellipseIn: shadow), with: .color(Palette.ink.opacity(0.1)))
        }

        var body = gc
        body.translateBy(x: 0, y: motion.floatOffset)
        // Breathe by squashing around the feet so Nana stays grounded.
        body.translateBy(x: 60, y: 106)
        body.scaleBy(x: 2 - motion.squash, y: motion.squash)
        body.translateBy(x: -60, y: -106)

        switch stage {
        case .seed:
            drawSeed(in: &body)
        case .sprout, .bloom:
            drawSprout(in: &body)
        }
    }

    // MARK: Stages

    private func drawSeed(in gc: inout GraphicsContext) {
        var stem = Path()
        stem.move(to: .init(x: 60, y: 52))
        stem.addCurve(to: .init(x: 63, y: 43), control1: .init(x: 60, y: 48), control2: .init(x: 61, y: 45))
        gc.stroke(stem, with: .color(Palette.outline), style: .init(lineWidth: 3, lineCap: .round))

        var body = Path()
        body.move(to: .init(x: 60, y: 52))
        body.addCurve(to: .init(x: 88, y: 82), control1: .init(x: 78, y: 52), control2: .init(x: 88, y: 66))
        body.addCurve(to: .init(x: 60, y: 104), control1: .init(x: 88, y: 96), control2: .init(x: 77, y: 104))
        body.addCurve(to: .init(x: 32, y: 82), control1: .init(x: 43, y: 104), control2: .init(x: 32, y: 96))
        body.addCurve(to: .init(x: 60, y: 52), control1: .init(x: 32, y: 66), control2: .init(x: 42, y: 52))
        body.closeSubpath()
        fillAndOutline(body, in: &gc)

        // Seed uses the sprout face, scaled into its smaller body.
        var face = gc
        face.translateBy(x: 60, y: 80)
        face.scaleBy(x: 0.7, y: 0.7)
        face.translateBy(x: -60, y: -68)
        drawFace(in: &face)
    }

    private func drawSprout(in gc: inout GraphicsContext) {
        var stem = Path()
        stem.move(to: .init(x: 60, y: 30))
        stem.addCurve(to: .init(x: 69, y: 12), control1: .init(x: 60, y: 22), control2: .init(x: 63, y: 16))
        gc.stroke(stem, with: .color(Palette.outline), style: .init(lineWidth: 3, lineCap: .round))

        var leafContext = gc
        leafContext.translateBy(x: 69, y: 15)
        leafContext.rotate(by: motion.leafAngle)
        leafContext.translateBy(x: -69, y: -15)
        var leaf = Path()
        leaf.move(to: .init(x: 69, y: 12))
        leaf.addCurve(to: .init(x: 88, y: 13), control1: .init(x: 77, y: 7), control2: .init(x: 86, y: 9))
        leaf.addCurve(to: .init(x: 69, y: 18), control1: .init(x: 84, y: 20), control2: .init(x: 75, y: 22))
        leaf.closeSubpath()
        leafContext.fill(leaf, with: .color(Palette.outline))

        if stage == .bloom {
            var secondLeaf = Path()
            secondLeaf.move(to: .init(x: 60, y: 30))
            secondLeaf.addCurve(to: .init(x: 48, y: 19), control1: .init(x: 58, y: 24), control2: .init(x: 54, y: 20))
            secondLeaf.addCurve(to: .init(x: 60, y: 30), control1: .init(x: 48, y: 25), control2: .init(x: 53, y: 29))
            secondLeaf.closeSubpath()
            gc.fill(secondLeaf, with: .color(Palette.outline))
        }

        var body = Path()
        body.move(to: .init(x: 60, y: 30))
        body.addCurve(to: .init(x: 100, y: 76), control1: .init(x: 86, y: 30), control2: .init(x: 100, y: 52))
        body.addCurve(to: .init(x: 60, y: 106), control1: .init(x: 100, y: 96), control2: .init(x: 84, y: 106))
        body.addCurve(to: .init(x: 20, y: 76), control1: .init(x: 36, y: 106), control2: .init(x: 20, y: 96))
        body.addCurve(to: .init(x: 60, y: 30), control1: .init(x: 20, y: 52), control2: .init(x: 34, y: 30))
        body.closeSubpath()
        fillAndOutline(body, in: &gc)

        if stage == .bloom {
            drawFrangipani(at: .init(x: 68, y: 12), in: &leafContext)
        }

        drawFace(in: &gc)
    }

    // MARK: Face (sprout coordinates)

    private func drawFace(in gc: inout GraphicsContext) {
        let ink = GraphicsContext.Shading.color(Palette.ink)
        let line = StrokeStyle(lineWidth: 3.5, lineCap: .round)

        gc.fill(Path(ellipseIn: .init(x: 32, y: 76, width: 12, height: 8)), with: .color(Palette.cheek))
        gc.fill(Path(ellipseIn: .init(x: 76, y: 76, width: 12, height: 8)), with: .color(Palette.cheek))

        switch mood {
        case .curious:
            drawOpenEyes(radius: 6, highlights: true, in: &gc)
            gc.fill(Path(ellipseIn: .init(x: 56, y: 80, width: 8, height: 8)), with: ink)

        case .happy:
            drawOpenEyes(radius: 5, highlights: false, in: &gc)
            gc.stroke(smile, with: ink, style: line)

        case .resting:
            var eyes = Path()
            eyes.move(to: .init(x: 41, y: 68))
            eyes.addQuadCurve(to: .init(x: 53, y: 68), control: .init(x: 47, y: 73))
            eyes.move(to: .init(x: 67, y: 68))
            eyes.addQuadCurve(to: .init(x: 79, y: 68), control: .init(x: 73, y: 73))
            gc.stroke(eyes, with: ink, style: line)

            var mouth = Path()
            mouth.move(to: .init(x: 56, y: 84))
            mouth.addLine(to: .init(x: 64, y: 84))
            gc.stroke(mouth, with: ink, style: line)

            var zzz = Path()
            zzz.addLines([.init(x: 88, y: 34), .init(x: 96, y: 34), .init(x: 88, y: 43), .init(x: 96, y: 43)])
            zzz.addLines([.init(x: 100, y: 22), .init(x: 105, y: 22), .init(x: 100, y: 28), .init(x: 105, y: 28)])
            gc.stroke(zzz, with: .color(Palette.sleepy),
                      style: .init(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

        case .proud:
            var eyes = Path()
            eyes.move(to: .init(x: 41, y: 70))
            eyes.addQuadCurve(to: .init(x: 53, y: 70), control: .init(x: 47, y: 62))
            eyes.move(to: .init(x: 67, y: 70))
            eyes.addQuadCurve(to: .init(x: 79, y: 70), control: .init(x: 73, y: 62))
            gc.stroke(eyes, with: ink, style: line)

            var mouth = Path()
            mouth.move(to: .init(x: 50, y: 82))
            mouth.addQuadCurve(to: .init(x: 70, y: 82), control: .init(x: 60, y: 94))
            mouth.closeSubpath()
            gc.fill(mouth, with: ink)

            var star = Path()
            star.addLines([
                .init(x: 22, y: 40), .init(x: 25, y: 46), .init(x: 31, y: 47), .init(x: 26, y: 51),
                .init(x: 27, y: 57), .init(x: 22, y: 54), .init(x: 17, y: 57), .init(x: 18, y: 51),
                .init(x: 13, y: 47), .init(x: 19, y: 46),
            ])
            star.closeSubpath()
            gc.fill(star, with: .color(Palette.gold))
        }
    }

    private var smile: Path {
        var path = Path()
        path.move(to: .init(x: 53, y: 82))
        path.addQuadCurve(to: .init(x: 67, y: 82), control: .init(x: 60, y: 89))
        return path
    }

    private func drawOpenEyes(radius: CGFloat, highlights: Bool, in gc: inout GraphicsContext) {
        let height = radius * 2 * motion.eyeOpenness
        for x in [47.0, 73.0] {
            let rect = CGRect(x: x - radius, y: 68 - height / 2, width: radius * 2, height: height)
            gc.fill(Path(ellipseIn: rect), with: .color(Palette.ink))
            if highlights, motion.eyeOpenness > 0.5 {
                gc.fill(Path(ellipseIn: .init(x: x, y: 64, width: 4, height: 4)), with: .color(.white))
            }
        }
    }

    private func drawFrangipani(at center: CGPoint, in gc: inout GraphicsContext) {
        let petals: [CGPoint] = [.init(x: 0, y: -6), .init(x: 6, y: -1), .init(x: 3, y: 6), .init(x: -4, y: 5), .init(x: -6, y: -2)]
        for petal in petals {
            let rect = CGRect(x: center.x + petal.x - 5, y: center.y + petal.y - 5, width: 10, height: 10)
            gc.fill(Path(ellipseIn: rect), with: .color(.white))
            gc.stroke(Path(ellipseIn: rect), with: .color(Palette.petalEdge), lineWidth: 1)
        }
        gc.fill(Path(ellipseIn: .init(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(Palette.gold))
    }

    private func fillAndOutline(_ path: Path, in gc: inout GraphicsContext) {
        gc.fill(path, with: .color(Palette.body))
        gc.stroke(path, with: .color(Palette.outline), lineWidth: 3)
    }
}

#Preview("Stages and moods") {
    ScrollView {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            ForEach(NanaStage.allCases, id: \.self) { stage in
                GridRow {
                    ForEach(NanaMood.allCases, id: \.self) { mood in
                        NanaView(stage: stage, mood: mood)
                            .padding(6)
                            .background(Color.surfaceMuted, in: .rect(cornerRadius: 16))
                    }
                }
            }
        }
        .padding()
    }
    .nanaCanvas()
}
