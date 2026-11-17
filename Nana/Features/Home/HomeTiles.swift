import SwiftUI

/// The two tiles under the charm: the left-behind switch and the guide.
/// Side by side, or stacked when the text is large.
struct HomeTiles: View {
    var onOpenGuide: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 12) { tiles }
        } else {
            HStack(alignment: .top, spacing: 12) { tiles }
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var tiles: some View {
        LeftBehindTile()
        GuideTile(action: onOpenGuide)
    }
}

private struct LeftBehindTile: View {
    @Environment(LeftBehindNudge.self) private var leftBehind

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Left-behind nudge")
                    .font(.nanaCardTitle)
                    .foregroundStyle(.cobalt)
                Text("When you leave it behind, outside your places")
                    .font(.nana(.text, size: 13, relativeTo: .caption))
                    .foregroundStyle(.inkSoft)
            }
            Spacer(minLength: 0)
            NudgeToggle(AppSettings.leftBehindNudgeOn, onChange: leftBehind.reschedule) {}
                .accessibilityLabel("Left-behind nudge")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(minHeight: 118)
        .nanaCard()
    }
}

private struct GuideTile: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text("How to put one on").font(.nanaCardTitle)
                Text("The fruit stand")
                    .font(.nana(.text, size: 13, relativeTo: .caption))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.nightInk)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(minHeight: 118)
            .padding(16)
            .background(alignment: .bottomTrailing) {
                Image(.homeFruitStand)
                    .offset(x: 6, y: 10)
                    .accessibilityHidden(true)
            }
            .background(Color.banana)
            .clipShape(.rect(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.nightInk, lineWidth: 3) }
        }
        .buttonStyle(.plain)
    }
}
