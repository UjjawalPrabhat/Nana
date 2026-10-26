import SwiftUI

/// "Two quick yeses". Bluetooth is already granted by pairing, so its card
/// only confirms; notifications are asked for here, and only on a tap.
struct PermissionsView: View {
    var onFinish: () -> Void

    @Environment(ContainerStore.self) private var containerStore
    @Environment(\.openURL) private var openURL
    @State private var notifications: NotificationState = .unknown

    enum NotificationState {
        case unknown, allowed, denied
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Two quick\nyeses")
                .font(.nanaTitle)
                .lineHeight(.multiple(factor: 0.9))
                .foregroundStyle(.cobalt)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 18)
            Text("You stay in control. Change either one later in Settings.")
                .padding(.bottom, 22)

            ScrollView {
                VStack(spacing: 16) {
                    bluetoothCard
                    notificationsCard
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            Button("Open Nana", action: onFinish)
                .nanaPrimaryButton()
                .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .nanaScreen()
        .task {
            if await NotificationScheduler.isAuthorized() { notifications = .allowed }
        }
    }

    private var bluetoothCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Bluetooth", systemImage: "dot.radiowaves.left.and.right", tile: .banana, color: .butter)
            Text("Reads the count and knows when your charm is out of range.")
            Text(containerStore.isPaired ? "Allowed" : "Pair your charm later in Settings")
                .nanaPill(.butter)
        }
        .foregroundStyle(.butter)
        .nanaCard(.cobalt, cornerRadius: 26, padding: 20)
        .accessibilityElement(children: .combine)
    }

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Notifications", systemImage: "bell", tile: .lilac, color: .cobalt)
            Text("For left-behind and low-supply nudges. Off until you switch them on. Your lock screen only ever says **“Your reminder is ready.”**")
            switch notifications {
            case .unknown:
                Button("Allow notifications") {
                    Task {
                        notifications = await NotificationScheduler.requestAuthorization() ? .allowed : .denied
                    }
                }
                .buttonStyle(NanaPillButtonStyle())
            case .allowed:
                Label("Allowed", systemImage: "checkmark")
                    .nanaPill(.cobalt, foreground: .butter)
            case .denied:
                Button("Turn on in iOS Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                }
                .buttonStyle(NanaPillButtonStyle())
            }
        }
        .nanaCard(cornerRadius: 26, padding: 20)
    }

    private func cardTitle(_ title: LocalizedStringKey, systemImage: String, tile: Color, color: Color) -> some View {
        HStack(spacing: 12) {
            IconTile(systemImage: systemImage, fill: tile)
            Text(title)
                .font(.nana(.extraBold, size: 26, relativeTo: .title2))
                .foregroundStyle(color)
                .accessibilityAddTraits(.isHeader)
        }
    }
}
