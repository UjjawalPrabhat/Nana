import SwiftUI

/// The bundled faces, named by their PostScript names.
enum NanaTypeface: String {
    case condensedExtraBold = "BricolageGrotesqueCondensed-ExtraBold"
    case condensedBold = "BricolageGrotesqueCondensed-Bold"
    case extraBold = "BricolageGrotesque-ExtraBold"
    case bold = "BricolageGrotesque-Bold"
    case text = "AtkinsonHyperlegibleNext-Regular"
    case textBold = "AtkinsonHyperlegibleNext-Bold"
}

/// The type scale from the redesign board. Every style is tied to a text style
/// so it scales with Dynamic Type.
extension Font {
    /// A one-off size outside the scale, still scaling with Dynamic Type.
    static func nana(_ face: NanaTypeface, size: CGFloat, relativeTo style: TextStyle = .body) -> Font {
        custom(face.rawValue, size: size, relativeTo: style)
    }

    /// The big number on Home.
    static let nanaCount = nana(.condensedExtraBold, size: 200, relativeTo: .largeTitle)
    /// The count when a banner shares the screen.
    static let nanaCountSmall = nana(.condensedExtraBold, size: 150, relativeTo: .largeTitle)
    /// "left in your charm" next to the count.
    static let nanaCountLabel = nana(.condensedBold, size: 34, relativeTo: .title)
    /// Welcome headline.
    static let nanaDisplay = nana(.condensedExtraBold, size: 78, relativeTo: .largeTitle)
    /// Screen titles.
    static let nanaTitle = nana(.condensedExtraBold, size: 54, relativeTo: .largeTitle)
    /// Guide step titles.
    static let nanaHeading = nana(.condensedExtraBold, size: 28, relativeTo: .title2)
    /// The "nana" wordmark and the guide's header.
    static let nanaWordmark = nana(.condensedExtraBold, size: 30, relativeTo: .title2)
    /// Home tiles, privacy cards.
    static let nanaCardTitle = nana(.extraBold, size: 21, relativeTo: .title3)
    static let nanaButton = nana(.bold, size: 20, relativeTo: .headline)

    static let nanaBody = nana(.text, size: 17, relativeTo: .body)
    static let nanaCallout = nana(.text, size: 15, relativeTo: .subheadline)
    static let nanaFootnote = nana(.text, size: 14, relativeTo: .footnote)
    /// Rows, chips, links.
    static let nanaLabel = nana(.textBold, size: 16, relativeTo: .callout)
    static let nanaLabelSmall = nana(.textBold, size: 14, relativeTo: .footnote)
    /// Section labels. Use with `.nanaCaptionStyle()` for the tracking.
    static let nanaCaption = nana(.textBold, size: 13, relativeTo: .caption)
}

extension View {
    /// Tracked, uppercased section label: "YOUR CHARM".
    func nanaCaptionStyle() -> some View {
        self
            .font(.nanaCaption)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(.inkSoft)
    }
}
