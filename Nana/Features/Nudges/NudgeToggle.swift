import SwiftUI

/// A nudge's on/off switch. Turning one on asks for notification access, in context.
struct NudgeToggle<Label: View>: View {
    @AppStorage private var isOn: Bool
    private var onChange: () -> Void
    private var label: Label

    init(_ key: String, onChange: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        _isOn = AppStorage(wrappedValue: true, key)
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
