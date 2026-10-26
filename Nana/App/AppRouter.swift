import Foundation

/// The screens that open over Home, including from a tapped nudge.
@Observable
final class AppRouter {
    enum Cover: String, Identifiable {
        case guide, stayedBehind

        var id: String { rawValue }
    }

    var cover: Cover? = AppRouter.initialCover
    var showsSettings = AppRouter.initialShowsSettings

    func open(_ nudge: Nudge) {
        switch nudge {
        case .leftBehind: cover = .stayedBehind
        case .lowSupply: cover = nil
        }
    }

    // Debug builds accept `-NanaOpen guide|stayedBehind|settings` for screenshots and UI tests.
    private static var debugOpen: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "NanaOpen")
        #else
        nil
        #endif
    }

    private static var initialCover: Cover? { debugOpen.flatMap(Cover.init) }
    private static var initialShowsSettings: Bool { debugOpen == "settings" }
}
