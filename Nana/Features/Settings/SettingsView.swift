import SwiftUI

// Reminders, device and privacy controls arrive in milestones 5–6.
struct SettingsView: View {
    @AppStorage(AppSettings.lowSupplyThreshold) private var lowThreshold = AppSettings.defaultLowSupplyThreshold

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $lowThreshold, in: 0...SupplyLedger.capacity - 1) {
                        LabeledContent("Running low at", value: lowThreshold, format: .number)
                    }
                } header: {
                    Text("Supply")
                } footer: {
                    Text("Home shows \"Running low\" when your count reaches this number.")
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
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}
