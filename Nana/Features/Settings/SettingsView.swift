import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.lowSupplyReminderOn) private var reminderOn = false
    @AppStorage(AppSettings.lowSupplyThreshold) private var lowThreshold = AppSettings.defaultLowSupplyThreshold
    @Environment(ContainerStore.self) private var containerStore
    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Low-supply reminder", isOn: Binding(
                        get: { reminderOn },
                        set: { newValue in setReminder(newValue) }
                    ))
                    Stepper(value: $lowThreshold, in: 0...SupplyLedger.capacity - 1) {
                        LabeledContent("Running low at", value: lowThreshold, format: .number)
                    }
                    LabeledContent("Notification preview") {
                        Text("Nana: Your reminder is ready.")
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    if notificationsDenied {
                        Text("Notifications are turned off for Nana in iOS Settings.")
                    } else {
                        Text("Sent when your container's count reaches this number. The text never says what it's about.")
                    }
                }

                Section("Device and data") {
                    NavigationLink {
                        DeviceDetailView()
                    } label: {
                        LabeledContent("Device management", value: containerStore.isPaired
                            ? String(localized: "Connected")
                            : String(localized: "None"))
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                }
            }
            .scrollContentBackground(.hidden)
            .nanaCanvas()
            .navigationTitle("Settings")
        }
    }

    private func setReminder(_ isOn: Bool) {
        guard isOn else {
            reminderOn = false
            return
        }
        Task {
            let granted = await LowSupplyReminder.requestAuthorization()
            notificationsDenied = !granted
            reminderOn = granted
        }
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environment(ContainerStore.preview())
}
