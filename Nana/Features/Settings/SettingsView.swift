import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .nanaScreenTitle()
                CharmSection()
                DemoSection()
                NudgesSection()
                PrivacySection()
                AboutSection()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .nanaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .nanaCloseButton { dismiss() }
    }
}

/// Section label plus its content.
private struct SettingsSection<Content: View>: View {
    var title: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .nanaCaptionStyle()
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

private struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.inkSoft)
            .accessibilityHidden(true)
    }
}

// MARK: Your Pod

private struct CharmSection: View {
    @Environment(ContainerStore.self) private var containerStore
    @Query(SupplyEvent.latest) private var events: [SupplyEvent]
    @State private var confirmsForget = false
    @State private var forgetFailed = false
    @State private var pairingFailed = false

    var body: some View {
        SettingsSection(title: "Your Pod") {
            HStack(spacing: 14) {
                PodBadge(count: events.first?.status.count)
                RowLabel(title: containerStore.isDemoRunning ? Text("Demo Pod") : Text("Nana Pod"),
                         detail: Text(statusText))
            }
            .nanaCard(.lilac)
            .accessibilityElement(children: .combine)

            // While the demo runs, its own section below has the controls.
            if !containerStore.isDemoRunning {
                charmActions
            }
        }
        .confirmationDialog("Forget this Pod?", isPresented: $confirmsForget, titleVisibility: .visible) {
            Button("Forget Pod", role: .destructive) {
                Task {
                    do { try await containerStore.forget() } catch { forgetFailed = true }
                }
            }
        } message: {
            Text("Nana stops reading the count until you pair it again.")
        }
        .alert("Something went wrong", isPresented: $forgetFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Pod couldn't be forgotten. Try again, or remove it in iOS Settings › Accessories.")
        }
        .pairingFailedAlert(isPresented: $pairingFailed)
    }

    private var charmActions: some View {
        RowGroup {
            if containerStore.isPaired {
                Button("Forget this Pod", role: .destructive) { confirmsForget = true }
                    .font(.nanaLabel)
                    .foregroundStyle(.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button("Pair your Pod") {
                    Task {
                        // A cancelled sheet returns false; only real errors are shown.
                        do { _ = try await containerStore.pair() } catch { pairingFailed = true }
                    }
                }
                .font(.nanaLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("No Pod yet? Try a demo") {
                    Task { await containerStore.startDemo() }
                }
                .font(.nanaLabel)
                .foregroundStyle(.cobalt)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.nightInk)
    }

    private var statusText: LocalizedStringResource {
        switch containerStore.connection {
        case .notPaired: "Not paired"
        case .connecting: "Connecting"
        case .disconnected: "Out of range"
        case .unavailable: "Bluetooth is off"
        case .connected:
            if let battery = containerStore.battery { "Connected, battery \(battery)%" } else { "Connected" }
        }
    }
}

// MARK: Nudges

private struct NudgesSection: View {
    @AppStorage(AppSettings.leftBehindWaitMinutes) private var waitMinutes = 2
    @Environment(LeftBehindNudge.self) private var leftBehind
    @State private var notificationsAllowed = true
    @AppStorage(AppSettings.leftBehindNudgeOn) private var leftBehindOn = false
    @AppStorage(AppSettings.lowSupplyNudgeOn) private var lowSupplyOn = false

    var body: some View {
        SettingsSection(title: "Nudges") {
            // Only worth flagging when a nudge is on but can't be delivered.
            if !notificationsAllowed, leftBehindOn || lowSupplyOn, !AppSettings.isTakingScreenshots {
                Button {
                    Task { await allowNotifications() }
                } label: {
                    RowLabel("Notifications are off", detail: Text("Nudges can't reach you. Tap to allow them."))
                }
                .buttonStyle(.plain)
                .nanaCard(.tangerine)
            }

            RowGroup {
                NudgeToggle(AppSettings.leftBehindNudgeOn, onChange: leftBehind.reschedule) {
                    RowLabel("Left behind", detail: Text("When your Pod stays out of range"))
                }

                NudgeToggle(AppSettings.lowSupplyNudgeOn) {
                    RowLabel("Running low", detail: Text("When one is left"))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                RowLabel("Wait before nudging", detail: Text("Short signal drops won’t set off a nudge"))
                ChoiceRow(title: "Wait before nudging", options: AppSettings.waitChoices, selection: $waitMinutes) {
                    Text("\($0) min")
                }
            }
            .nanaCard()

            Text("Nana nudges you whenever your Pod stays out of range for the wait time. Nudges pause while Bluetooth is off. If you force quit Nana, it can't tell when your Pod comes back, so a nudge may arrive late or by mistake.")
                .font(.nanaFootnote)
                .foregroundStyle(.inkSoft)
                .padding(.horizontal, 4)
        }
        .onChange(of: waitMinutes) { leftBehind.reschedule() }
        .onNotificationAuthorization { notificationsAllowed = $0 }
    }

    private func allowNotifications() async {
        notificationsAllowed = await NotificationScheduler.requestOrOpenSettings()
    }
}

// MARK: Privacy

private struct PrivacySection: View {
    @AppStorage(AppSettings.discreetNudges) private var isDiscreet = false
    @Environment(LeftBehindNudge.self) private var leftBehind

    var body: some View {
        let preview = Nudge.leftBehind.text(discreet: isDiscreet)
        SettingsSection(title: "Privacy") {
            VStack(alignment: .leading, spacing: 12) {
                Text("What your lock screen shows")
                    .font(.nanaLabelSmall)
                    .foregroundStyle(.butter)
                HStack(spacing: 12) {
                    AppMark()
                    VStack(alignment: .leading, spacing: 0) {
                        Text(preview.title).font(.nanaLabelSmall)
                        Text(preview.body).font(.nanaFootnote)
                    }
                    Spacer()
                    Text("now").font(.nanaCaption).foregroundStyle(.inkSoft)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.card, in: .rect(cornerRadius: 18))
                .accessibilityElement(children: .combine)
            }
            .nanaCard(.cobalt)
            .animation(.default, value: isDiscreet)

            RowGroup {
                Toggle(isOn: $isDiscreet) {
                    RowLabel("Discreet notifications",
                             detail: Text("Only show “\(Nudge.leftBehind.text(discreet: true).body)”"))
                }
                .toggleStyle(NanaToggleStyle())
            }
            // A nudge already waiting was written with the old text.
            .onChange(of: isDiscreet) { leftBehind.refreshPendingText() }

            AppIconPicker()

            Text("To lock Nana with Face ID, touch and hold its icon on the Home Screen, then choose Require Face ID.")
                .font(.nanaFootnote)
                .foregroundStyle(.inkSoft)
                .padding(.horizontal, 4)
        }
    }
}

// MARK: About

private struct AboutSection: View {
    var body: some View {
        SettingsSection(title: "About") {
            RowGroup {
                NavigationLink { PrivacyPolicyView().nanaBackButton() } label: { linkRow("Privacy policy") }
                    .buttonStyle(.plain)
                NavigationLink { HealthSafetyView().nanaBackButton() } label: { linkRow("Health and safety") }
                    .buttonStyle(.plain)
                Link(destination: PartnerInfo.contactURL) { linkRow("Contact us", isExternal: true) }
                    .buttonStyle(.plain)
                    .accessibilityHint("Writes an email to \(PartnerInfo.contactEmail)")
                Link(destination: PartnerInfo.website) { linkRow("keepnana.com", isExternal: true) }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the website")
            }
            Group {
                Text("Nana helps you keep condoms close. Nana is not medical advice.")
                Text("Version \(Bundle.main.appVersion)").font(.nanaCaption)
            }
            .font(.nanaFootnote)
            .foregroundStyle(.inkSoft)
            .padding(.horizontal, 4)
        }
    }

    private func linkRow(_ title: LocalizedStringKey, isExternal: Bool = false) -> some View {
        HStack {
            Text(title).font(.nanaLabel)
            Spacer()
            if isExternal {
                Image(systemName: "arrow.up.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.inkSoft)
                    .accessibilityHidden(true)
            } else {
                Chevron()
            }
        }
        .contentShape(.rect)
    }
}

// MARK: Demo

/// Shown while the demo Pod is in use: play out what a real Pod would do.
private struct DemoSection: View {
    @Environment(ContainerStore.self) private var containerStore

    var body: some View {
        if let demo = containerStore.demo, containerStore.isDemoRunning {
            SettingsSection(title: "Demo Pod") {
                RowGroup {
                    Button("Take one out") { demo.simulateChange(by: -1) }
                    Button("Refill") { demo.simulateChange(by: SupplyLedger.capacity) }
                    Button("Walk away from it") { demo.simulateInRange(false) }
                    Button("Come back to it") { demo.simulateInRange(true) }
                    Button("Stop the demo", role: .destructive) {
                        Task { await containerStore.stopDemo() }
                    }
                    .foregroundStyle(.destructive)
                }
                .font(.nanaLabel)
                .foregroundStyle(.cobalt)
                Text("The demo Pod acts like a real one, without Bluetooth. Walking away starts the left-behind wait you chose.")
                    .font(.nanaFootnote)
                    .foregroundStyle(.inkSoft)
                    .padding(.horizontal, 4)
            }
        }
    }
}

private extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}

#if DEBUG
#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(ContainerStore.preview())
        .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
        .environment(AppRouter())
}
#endif
