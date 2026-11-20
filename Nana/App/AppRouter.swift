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
    /// Waiting for the Settings sheet to finish closing; see `settingsDidDismiss()`.
    private var pendingCover: Cover?

    /// Shows Home, or the stayed-behind screen over it, for a tapped nudge.
    func open(_ nudge: Nudge) {
        let target: Cover? = nudge == .leftBehind ? .stayedBehind : nil
        guard showsSettings else {
            cover = target
            return
        }
        // SwiftUI can't present a cover while the Settings sheet is still up, so
        // close Settings and present once it's gone.
        pendingCover = target
        showsSettings = false
    }

    /// Called from the Settings sheet's `onDismiss`.
    func settingsDidDismiss() {
        if let pendingCover { cover = pendingCover }
        pendingCover = nil
    }

    /// Back to a bare Home, e.g. after Delete everything.
    func reset() {
        showsSettings = false
        cover = nil
        pendingCover = nil
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
