import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.nanaTitle)
                    .lineHeight(.multiple(factor: 0.9))
                    .foregroundStyle(.cobalt)
                    .accessibilityAddTraits(.isHeader)
                CharmSection()
                NudgesSection()
                PrivacySection()
                AboutSection()
                #if DEBUG
                DemoSection()
                #endif
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .nanaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
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

// MARK: Your charm

private struct CharmSection: View {
    @Environment(ContainerStore.self) private var containerStore
    @Query(sort: \SupplyEvent.date) private var events: [SupplyEvent]
    @State private var confirmsForget = false

    var body: some View {
        SettingsSection(title: "Your charm") {
            HStack(spacing: 14) {
                CharmBadge(count: SupplyLedger.status(for: events.map(\.ledgerEntry))?.count)
                RowLabel(title: Text("Nana charm"), detail: Text(statusText))
            }
            .nanaCard(.lilac)
            .accessibilityElement(children: .combine)

            RowGroup {
                if containerStore.isPaired {
                    Button("Reconnect") { containerStore.reconnect() }
                        .font(.nanaLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Forget this charm", role: .destructive) { confirmsForget = true }
                        .font(.nanaLabel)
                        .foregroundStyle(.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button("Pair your charm") {
                        Task { _ = try? await containerStore.pair() }
                    }
                    .font(.nanaLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .foregroundStyle(.nightInk)
        }
        .confirmationDialog("Forget this charm?", isPresented: $confirmsForget, titleVisibility: .visible) {
            Button("Forget charm", role: .destructive) {
                Task { try? await containerStore.forget() }
            }
        } message: {
            Text("Nana stops reading the count until you pair it again.")
        }
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
    @Query(sort: \Place.createdAt) private var places: [Place]
    @Environment(LeftBehindNudge.self) private var leftBehind
    @Environment(PlaceMonitor.self) private var placeMonitor
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsSection(title: "Nudges") {
            RowGroup {
                NudgeToggle(AppSettings.leftBehindNudgeOn, onChange: leftBehind.reschedule) {
                    RowLabel("Left behind", detail: Text("When your charm stays behind outside your places"))
                }

                ForEach(places) { place in
                    NavigationLink {
                        PlaceFormView(place: place)
                    } label: {
                        HStack(spacing: 12) {
                            IconTile(systemImage: place.kind.systemImage, fill: place.kind == .home ? .banana : .lilac)
                            RowLabel(title: Text(place.kind.name),
                                     detail: Text("About \(Int(place.radius)) m, saved on this phone"))
                            Chevron()
                        }
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    PlaceFormView()
                } label: {
                    HStack(spacing: 12) {
                        IconTile(systemImage: "plus", fill: .card, isDashed: true)
                        Text("Add a place").font(.nanaLabel).foregroundStyle(.cobalt)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                Button(action: openLocationSettings) {
                    HStack(spacing: 12) {
                        Text("Location access").font(.nanaLabel)
                        Spacer()
                        Text(locationText)
                            .font(.nanaLabelSmall)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 28)
                            .background(Color.lilac, in: .capsule)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens iOS Settings")

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
            .nanaCard(padding: 16)

            Text("Nana stays quiet at your saved places and nudges everywhere else. Without location access, Nana nudges whenever your charm stays out of range for the wait time. Nudges pause if you force quit Nana or turn off Bluetooth.")
                .font(.nanaFootnote)
                .foregroundStyle(.inkSoft)
                .padding(.horizontal, 4)
        }
        .onChange(of: waitMinutes) { leftBehind.reschedule() }
    }

    private var locationText: LocalizedStringResource {
        switch placeMonitor.authorization {
        case .authorizedAlways: "Always"
        case .authorizedWhenInUse: "While using"
        case .notDetermined: "Not set"
        default: "Off"
        }
    }

    private func openLocationSettings() {
        if placeMonitor.authorization == .notDetermined {
            placeMonitor.requestAlwaysAccess()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: Privacy

private struct PrivacySection: View {
    var body: some View {
        SettingsSection(title: "Privacy") {
            VStack(alignment: .leading, spacing: 12) {
                Text("What your lock screen shows")
                    .font(.nanaLabelSmall)
                    .foregroundStyle(.butter)
                HStack(spacing: 12) {
                    AppMark()
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Reminder").font(.nanaLabelSmall)
                        Text("Your reminder is ready.").font(.nanaFootnote)
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
                NavigationLink { PrivacyPolicyView() } label: { linkRow("Privacy policy") }
                    .buttonStyle(.plain)
                NavigationLink { HealthSafetyView() } label: { linkRow("Health and safety") }
                    .buttonStyle(.plain)
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

    private func linkRow(_ title: LocalizedStringKey) -> some View {
        HStack {
            Text(title).font(.nanaLabel)
            Spacer()
            Chevron()
        }
    }
}

#if DEBUG
// MARK: Demo

/// Drives the demo charm in the Simulator.
private struct DemoSection: View {
    @Environment(ContainerStore.self) private var containerStore

    var body: some View {
        SettingsSection(title: "Demo charm") {
            RowGroup {
                Toggle(isOn: Binding(get: { containerStore.usesDemo }, set: { containerStore.setUsesDemo($0) })) {
                    RowLabel("Use demo charm")
                }
                .toggleStyle(NanaToggleStyle())
                if let demo = containerStore.demo {
                    Button("Take one out") { demo.simulateChange(by: -1) }.font(.nanaLabel)
                    Button("Refill") { demo.simulateChange(by: SupplyLedger.capacity) }.font(.nanaLabel)
                    Button("Walk away from it") { demo.simulateInRange(false) }.font(.nanaLabel)
                    Button("Come back to it") { demo.simulateInRange(true) }.font(.nanaLabel)
                }
            }
            .foregroundStyle(.cobalt)
        }
    }
}
#endif

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}

#if DEBUG
#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: [SupplyEvent.self, Place.self], inMemory: true)
        .environment(ContainerStore.preview())
        .environment(PlaceMonitor())
        .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
}
#endif
