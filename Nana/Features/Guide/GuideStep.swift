import SwiftUI

/// "The fruit stand": how to put a condom on, shown on an uncut (banana) or
/// cut (eggplant) model. Copy and order come from the redesign board.
nonisolated struct GuideStep: Identifiable, Equatable, Sendable {
    enum Model: String, CaseIterable, Sendable {
        case banana, eggplant
    }

    enum Illustration: String, Sendable {
        case check, tear, side, peel, pinch, roll, after, lube
    }

    var id: Illustration { illustration }
    var illustration: Illustration
    var title: LocalizedStringResource
    var body: LocalizedStringResource
    /// Only for an uncut penis.
    var isBananaOnly = false

    static let all: [GuideStep] = [
        GuideStep(
            illustration: .check,
            title: "Check the date and the seal",
            body: "Look for the expiry date. Squeeze the wrapper and feel for the air pocket. The air pocket means the seal is intact."
        ),
        GuideStep(
            illustration: .tear,
            title: "Tear from the notch",
            body: "Open the wrapper from the notched edge with your fingers. No teeth, no scissors."
        ),
        GuideStep(
            illustration: .side,
            title: "Find the right side",
            body: "The rim rolls outward, like a hat brim. Put it on inside out? Start again with a new one."
        ),
        GuideStep(
            illustration: .peel,
            title: "Pull back the foreskin",
            body: "Ease the skin back a little, like the banana peel. Then place the condom on the tip.",
            isBananaOnly: true
        ),
        GuideStep(
            illustration: .pinch,
            title: "Pinch the tip",
            body: "Squeeze the air out of the tip with two fingers. The tip holds the semen."
        ),
        GuideStep(
            illustration: .roll,
            title: "Roll to the base",
            body: "Keep pinching and roll the rim all the way down."
        ),
        GuideStep(
            illustration: .after,
            title: "Hold, slide, tie, bin",
            body: "Hold the rim at the base while pulling out. Slide it off, tie a knot, and bin it. Never flush."
        ),
        GuideStep(
            illustration: .lube,
            title: "One per round, right lube",
            body: "Use a new condom every time. With latex, use water or silicone lube. Oil weakens latex."
        ),
    ]

    static func steps(for model: Model) -> [GuideStep] {
        all.filter { model == .banana || !$0.isBananaOnly }
    }
}

extension GuideStep {
    func image(for model: GuideStep.Model) -> ImageResource {
        switch (illustration, model) {
        case (.check, _): .guideCheck
        case (.tear, _): .guideTear
        case (.side, _): .guideSide
        case (.peel, _): .guidePeel
        case (.pinch, .banana): .guideBananaPinch
        case (.pinch, .eggplant): .guideEggPinch
        case (.roll, .banana): .guideBananaRoll
        case (.roll, .eggplant): .guideEggRoll
        case (.after, _): .guideAfter
        case (.lube, _): .guideLube
        }
    }

    /// Words drawn on the illustration, as (text, x, y, rotation) in its
    /// 240×220 space. Kept out of the SVGs so they can be translated.
    var labels: [(text: LocalizedStringResource, x: CGFloat, y: CGFloat, angle: Double)] {
        switch illustration {
        case .check: [("EXP 08/2028", 125, 152, -6)]
        case .side: [("RIM ROLLS OUT", 120, 199, 0)]
        case .lube: [("WATER", 48, 167, 0), ("SILICONE", 120, 167, 0), ("NOT OIL", 192, 167, 0)]
        default: []
        }
    }

    func accessibilityDescription(for model: GuideStep.Model) -> LocalizedStringResource {
        switch (illustration, model) {
        case (.check, _): "A condom wrapper with the expiry date, a finger pressing the air pocket"
        case (.tear, _): "Wrapper torn open from the notched corner"
        case (.side, _): "Condom seen from the side, rim rolled outward like a hat brim"
        case (.peel, _): "Banana with the skin peeled back a little at the tip"
        case (.pinch, .banana): "Banana with the condom tip pinched"
        case (.pinch, .eggplant): "Eggplant with the condom tip pinched"
        case (.roll, .banana): "Banana with the condom rolled to the base"
        case (.roll, .eggplant): "Eggplant with the condom rolled to the base"
        case (.after, _): "A tied condom going into a bin"
        case (.lube, _): "Water and silicone lube are fine, oil is crossed out"
        }
    }
}
