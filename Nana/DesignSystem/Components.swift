import SwiftUI

/// White rounded card with a hairline border, as used across the high-fi boards.
struct NanaCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface, in: .rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(Color.hairline, lineWidth: 1)
            }
    }
}

/// Small capsule label, e.g. "Supply available".
struct StatusBadge: View {
    enum Tone {
        case positive, warning, neutral
    }

    var title: LocalizedStringKey
    var systemImage: String?
    var tone: Tone = .neutral

    var body: some View {
        Label {
            Text(title)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background, in: .capsule)
    }

    private var foreground: Color {
        switch tone {
        case .positive: .brandGreen
        case .warning: .textPrimary
        case .neutral: .textSecondary
        }
    }

    private var background: Color {
        switch tone {
        case .positive: .surfaceMuted
        case .warning: .peach
        case .neutral: .surfaceMuted
        }
    }
}

extension View {
    /// Primary call to action: full width, brand tinted, native glass styling.
    func nanaPrimaryButton() -> some View {
        self
            .fontWeight(.semibold)
            .buttonStyle(.glassProminent)
            .tint(.brandGreen)
            .controlSize(.large)
    }

    /// Secondary action next to a primary one.
    func nanaSecondaryButton() -> some View {
        self
            .buttonStyle(.glass)
            .tint(.brandGreen)
            .controlSize(.large)
    }

    /// Page background used behind scroll views.
    func nanaCanvas() -> some View {
        self.background(Color.canvas.ignoresSafeArea())
    }
}
