import SwiftUI
import UIKit

/// The square outlined icon button used for all navigation: Close, Back and
/// Settings. Used instead of the system's glass toolbar buttons so every screen
/// moves around the same way.
struct NanaIconButton: View {
    var title: LocalizedStringKey
    var systemImage: String
    var action: () -> Void

    init(_ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.nightInk)
                .frame(width: 44, height: 44)
                .background(Color.card, in: .rect(cornerRadius: 15))
                .overlay { RoundedRectangle(cornerRadius: 15).strokeBorder(.nightInk, lineWidth: 2.5) }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

extension View {
    /// Replaces the system back button on a pushed screen with the design system's.
    func nanaBackButton() -> some View {
        modifier(NanaBackButton())
    }

    /// A Close button at the top right of a sheet's navigation bar.
    func nanaCloseButton(action: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NanaIconButton("Close", systemImage: "xmark", action: action)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
}

private struct NanaBackButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NanaIconButton("Back", systemImage: "chevron.left") { dismiss() }
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .background { EdgeSwipeBack().frame(width: 0, height: 0) }
    }
}

/// Hiding the system back button also turns off the edge swipe that goes back.
/// This turns it back on for the screen it's placed in, without touching any
/// other navigation controller.
private struct EdgeSwipeBack: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        // Set on every appearance: the screen pushed on top takes the delegate over,
        // and the gesture holds it weakly, so it's released when that screen pops.
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}
