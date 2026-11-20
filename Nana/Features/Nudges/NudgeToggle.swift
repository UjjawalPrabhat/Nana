import SwiftUI

/// A nudge's on/off switch. Turning one on asks for notification access, in context.
struct NudgeToggle<Label: View>: View {
    @AppStorage private var isOn: Bool
    private var onChange: () -> Void
    private var label: Label

    init(_ key: String, onChange: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        _isOn = AppStorage(wrappedValue: AppSettings.defaults[key] as? Bool ?? false, key)
        self.onChange = onChange
        self.label = label()
    }

    var body: some View {
        Toggle(isOn: $isOn) { label }
            .toggleStyle(NanaToggleStyle())
            .onChange(of: isOn) { _, isOn in
                onChange()
                if isOn { Task { _ = await NotificationScheduler.requestAuthorization() } }
            }
    }
}

extension URL {
    /// Nana's notification page in iOS Settings, the only way back after a "Don't allow".
    static var notificationSettings: URL {
        URL(string: UIApplication.openNotificationSettingsURLString)!
    }
}

extension View {
    /// Reads notification permission each time the app becomes active, so a change
    /// made in iOS Settings shows up on return.
    func onNotificationAuthorization(_ action: @escaping (Bool) -> Void) -> some View {
        modifier(NotificationAuthorizationCheck(action: action))
    }
}

private struct NotificationAuthorizationCheck: ViewModifier {
    var action: (Bool) -> Void
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.task(id: scenePhase) {
            if scenePhase == .active { action(await NotificationScheduler.isAuthorized()) }
        }
    }
}
