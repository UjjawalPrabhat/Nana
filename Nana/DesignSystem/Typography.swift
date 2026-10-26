import SwiftUI

/// The type scale from the redesign board. Every style is tied to a text style
/// so it scales with Dynamic Type.
extension Font {
    private static let condensedExtraBold = "BricolageGrotesqueCondensed-ExtraBold"
    private static let condensedBold = "BricolageGrotesqueCondensed-Bold"
    private static let extraBold = "BricolageGrotesque-ExtraBold"
    private static let bold = "BricolageGrotesque-Bold"
    private static let text = "AtkinsonHyperlegibleNext-Regular"
    private static let textBold = "AtkinsonHyperlegibleNext-Bold"

    /// The big number on Home.
    static let nanaCount = custom(condensedExtraBold, size: 200, relativeTo: .largeTitle)
    /// The count when a banner shares the screen.
    static let nanaCountSmall = custom(condensedExtraBold, size: 150, relativeTo: .largeTitle)
    /// "left in your charm" next to the count.
    static let nanaCountLabel = custom(condensedBold, size: 34, relativeTo: .title)
    /// Welcome headline.
    static let nanaDisplay = custom(condensedExtraBold, size: 78, relativeTo: .largeTitle)
    /// Screen titles.
    static let nanaTitle = custom(condensedExtraBold, size: 54, relativeTo: .largeTitle)
    /// Guide step titles.
    static let nanaHeading = custom(condensedExtraBold, size: 28, relativeTo: .title2)
    /// The "nana" wordmark and the guide's header.
    static let nanaWordmark = custom(condensedExtraBold, size: 30, relativeTo: .title2)
    /// Home tiles, privacy cards.
    static let nanaCardTitle = custom(extraBold, size: 21, relativeTo: .title3)
    static let nanaButton = custom(bold, size: 20, relativeTo: .headline)

    static let nanaBody = custom(text, size: 17, relativeTo: .body)
    static let nanaCallout = custom(text, size: 15, relativeTo: .subheadline)
    static let nanaFootnote = custom(text, size: 14, relativeTo: .footnote)
    /// Rows, chips, links.
    static let nanaLabel = custom(textBold, size: 16, relativeTo: .callout)
    static let nanaLabelSmall = custom(textBold, size: 14, relativeTo: .footnote)
    /// Section labels. Use with `.nanaCaptionStyle()` for the tracking.
    static let nanaCaption = custom(textBold, size: 13, relativeTo: .caption)
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
