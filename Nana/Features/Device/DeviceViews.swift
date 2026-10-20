import SwiftUI

/// "Connect your container" (design screen 2). Used in onboarding and from Home.
struct PairContainerView: View {
    /// Called with `true` when a container was paired, `false` for "Set up later".
    var onDone: (Bool) -> Void

    @Environment(ContainerStore.self) private var store
    @State private var isPairing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect your container")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.textPrimary)
                    Text("Your container updates your count automatically when you close the lid.")
                        .foregroundStyle(Color.textSecondary)
                }

                ContainerIllustration()
                    .frame(height: 170)

                VStack(alignment: .leading, spacing: 12) {
                    step(1, "Press the recessed button on the base.")
                    step(2, "Keep your iPhone nearby.")
                    step(3, "Tap Connect and choose your container.")
                }

                if store.usesDemo {
                    StatusBadge(title: "Demo container", systemImage: "wand.and.stars", tone: .warning)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    connect()
                } label: {
                    Group {
                        if isPairing {
                            ProgressView()
                        } else {
                            Text("Connect container")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .nanaPrimaryButton()
                .disabled(isPairing)

                Button("Set up later") { onDone(false) }
                    .font(.body.weight(.semibold))
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .nanaCanvas()
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(number, format: .number)
                .font(.footnote.weight(.semibold))
                .frame(width: 22, height: 22)
                .background(Color.peachSoft, in: .circle)
            Text(text)
        }
        .foregroundStyle(Color.textPrimary)
        .accessibilityElement(children: .combine)
    }

    private func connect() {
        isPairing = true
        errorMessage = nil
        Task {
            defer { isPairing = false }
            do {
                if try await store.pair() { onDone(true) }
            } catch {
                errorMessage = String(localized: "Couldn't connect. Make sure the container is nearby and try again.")
            }
        }
    }
}

/// Container status row on Home.
struct ContainerRow: View {
    var onConnect: () -> Void

    @Environment(ContainerStore.self) private var store

    var body: some View {
        if store.isPaired {
            NavigationLink {
                DeviceDetailView()
            } label: {
                row(title: "Nana container", subtitle: store.statusLine, systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onConnect) {
                row(title: "Connect your container",
                    subtitle: String(localized: "Keep your count up to date automatically."),
                    systemImage: "plus.circle")
            }
            .buttonStyle(.plain)
        }
    }

    private func row(title: LocalizedStringKey, subtitle: String, systemImage: String) -> some View {
        NanaCard(padding: 16) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.surfaceMuted, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct DeviceDetailView: View {
    @Environment(ContainerStore.self) private var store
    @State private var isPairing = false
    @State private var confirmForget = false

    var body: some View {
        Form {
            if store.isPaired {
                Section {
                    LabeledContent("Status", value: store.statusLine)
                    if let battery = store.battery {
                        LabeledContent("Battery") {
                            Text(Double(battery) / 100, format: .percent)
                        }
                    }
                    if let reading = store.lastReading,
                       let count = reading.estimatedCount(capacity: store.capacity) {
                        LabeledContent(reading.isEstimate ? "Last reading (estimate)" : "Last reading") {
                            Text(count, format: .number)
                        }
                    }
                    LabeledContent("Holds", value: store.capacity, format: .number)
                    if let firmware = store.firmware {
                        LabeledContent("Firmware", value: firmware)
                    }
                }

                Section {
                    Button("Identify container", systemImage: "light.beacon.max") {
                        store.identify()
                    }
                    .disabled(store.connection != .connected)
                } footer: {
                    Text("Your container blinks so you can tell it's yours.")
                }

                if let demo = store.demo {
                    Section("Demo controls") {
                        Button("Take one out", systemImage: "minus.circle") { demo.simulateChange(by: -1) }
                        Button("Refill to full", systemImage: "plus.circle") { demo.simulateChange(by: store.capacity) }
                    }
                }

                Section {
                    Button("Forget this container", role: .destructive) { confirmForget = true }
                }
            } else {
                Section {
                    Button("Connect a container", systemImage: "plus.circle") { isPairing = true }
                } footer: {
                    Text("Without a container, you can still update your count yourself on Home.")
                }
            }

            #if DEBUG
            Section {
                Toggle("Use demo container", isOn: Binding(
                    get: { store.usesDemo },
                    set: { store.setUsesDemo($0) }
                ))
            } header: {
                Text("Developer")
            } footer: {
                Text("A pretend container that follows the same Bluetooth contract. Debug builds only.")
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        .nanaCanvas()
        .navigationTitle("Device management")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Forget this container?", isPresented: $confirmForget, titleVisibility: .visible) {
            Button("Forget container", role: .destructive) {
                Task { try? await store.forget() }
            }
        } message: {
            Text("Your count stays on this iPhone. You can connect again any time.")
        }
        .sheet(isPresented: $isPairing) {
            PairContainerView { _ in isPairing = false }
        }
    }
}

extension ContainerStore {
    /// "Connected · Last update 14:32", "Not in range · Last seen …", etc.
    var statusLine: String {
        let seen = lastSeen?.nanaRelativeDescription
        switch connection {
        case .notPaired:
            return String(localized: "Not connected")
        case .connecting:
            return String(localized: "Connecting…")
        case .connected:
            guard let seen else { return String(localized: "Connected") }
            return String(localized: "Connected · Last update \(seen)")
        case .disconnected:
            guard let seen else { return String(localized: "Not in range") }
            return String(localized: "Not in range · Last seen \(seen)")
        }
    }
}

#Preview("Pair") {
    PairContainerView { _ in }
        .environment(ContainerStore.preview(paired: false))
}

#Preview("Device") {
    NavigationStack { DeviceDetailView() }
        .environment(ContainerStore.preview())
}
