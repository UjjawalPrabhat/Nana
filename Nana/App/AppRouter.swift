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
    var showsDebugger = false
    /// Waiting for a sheet to finish closing; see `sheetDidDismiss()`.
    private var pendingCover: Cover?

    /// Shows Home, or the stayed-behind screen over it, for a tapped nudge.
    func open(_ nudge: Nudge) {
        let target: Cover? = nudge == .leftBehind ? .stayedBehind : nil
        guard showsSettings || showsDebugger else {
            cover = target
            return
        }
        // SwiftUI can't present a cover while a sheet is still up, so close the
        // sheet and present once it's gone.
        pendingCover = target
        showsSettings = false
        showsDebugger = false
    }

    /// Called from the Settings and debugger sheets' `onDismiss`.
    func sheetDidDismiss() {
        if let pendingCover { cover = pendingCover }
        pendingCover = nil
    }

    /// Back to a bare Home, e.g. after Delete everything.
    func reset() {
        showsSettings = false
        showsDebugger = false
        cover = nil
        pendingCover = nil
    }

    // Debug builds accept `-NanaOpen guide|stayedBehind|settings|debugger` for screenshots and UI tests.
    private static var debugOpen: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "NanaOpen")
        #else
        nil
        #endif
    }

    private static var initialCover: Cover? { debugOpen.flatMap(Cover.init) }
    private static var initialShowsSettings: Bool { debugOpen == "settings" }
    static var opensDebugger: Bool { debugOpen == "debugger" }
}
