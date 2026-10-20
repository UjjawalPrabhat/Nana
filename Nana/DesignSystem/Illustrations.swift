import SwiftUI

/// The rounded "n" app mark from the welcome screen.
struct AppMark: View {
    var body: some View {
        Text(verbatim: "n")
            .font(.system(size: 34, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.onBrand)
            .frame(width: 56, height: 56)
            .background(Color.brandGreen, in: .rect(cornerRadius: 14))
            .accessibilityLabel("Nana")
    }
}

/// Simple vector stand-in for the container render on the welcome screen.
struct ContainerIllustration: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.surfaceMuted)
                Circle()
                    .fill(Color.peach)
                    .frame(width: size.height * 1.1)
                    .offset(x: size.width * 0.3, y: -size.height * 0.15)
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red: 0.84, green: 0.89, blue: 0.86))
                    .frame(width: size.width * 0.45, height: size.height * 0.42)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.brandGreen.opacity(0.25))
                            .frame(height: 1.5)
                            .padding(.top, size.height * 0.12)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 8)
            }
            .clipShape(.rect(cornerRadius: 24))
        }
        .accessibilityHidden(true)
    }
}
