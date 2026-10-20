import LocalAuthentication
import SwiftUI

/// Covers the app in the app switcher and, if App Lock is on, asks for
/// Face ID / passcode whenever Nana comes back to the foreground.
struct PrivacyGate<Content: View>: View {
    @ViewBuilder var content: Content

    @AppStorage(AppSettings.appLockOn) private var appLockOn = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLocked: Bool
    @State private var isAuthenticating = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        _isLocked = State(initialValue: UserDefaults.standard.bool(forKey: AppSettings.appLockOn))
    }

    var body: some View {
        content
            .overlay {
                if isLocked || scenePhase != .active {
                    PrivacyCover(showsUnlock: isLocked && scenePhase == .active, unlock: unlock)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isLocked)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background, appLockOn { isLocked = true }
                if phase == .active, isLocked { unlock() }
            }
            .task { if isLocked { unlock() } }
    }

    private func unlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            if await AppLock.authenticate() { isLocked = false }
        }
    }
}

private struct PrivacyCover: View {
    var showsUnlock: Bool
    var unlock: () -> Void

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            VStack(spacing: 20) {
                AppMark()
                if showsUnlock {
                    Button("Unlock", systemImage: "faceid", action: unlock)
                        .nanaPrimaryButton()
                }
            }
        }
    }
}

nonisolated enum AppLock {
    /// Whether this iPhone has Face ID, Touch ID or a passcode set up.
    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func authenticate() async -> Bool {
        let context = LAContext()
        return (try? await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: String(localized: "Unlock Nana")
        )) ?? false
    }
}
