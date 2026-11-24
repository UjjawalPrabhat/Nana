import SwiftUI

/// "Two quick yeses". Bluetooth is already granted by pairing, so its card
/// only confirms; notifications are asked for here, and only on a tap.
struct PermissionsView: View {
    var onFinish: () -> Void

    @Environment(ContainerStore.self) private var containerStore
    @Environment(LeftBehindNudge.self) private var leftBehind
    @Environment(\.openURL) private var openURL
    @State private var notifications: NotificationState = .unknown

    enum NotificationState {
        case unknown, allowed, denied
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Two quick\nyeses")
                .nanaScreenTitle()
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
        // Already allowed (e.g. after Delete everything, which keeps the iOS
        // permission): the card says "Allowed", so the nudges must be on too.
        .onNotificationAuthorization { isAllowed in
            if isAllowed, notifications != .allowed { turnOnNudges() }
        }
    }

    private var bluetoothCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Bluetooth", systemImage: "dot.radiowaves.left.and.right", tile: .banana, color: .butter)
            Text("Reads the count and knows when your Pod is out of range.")
            Text(containerStore.isPaired && (!containerStore.usesDemo || AppSettings.isTakingScreenshots) ? "Allowed" : "Pair your Pod later in Settings")
                .nanaPill(.butter)
        }
        .foregroundStyle(.butter)
        .nanaCard(.cobalt, cornerRadius: 26, padding: 20)
        .accessibilityElement(children: .combine)
    }

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Notifications", systemImage: "bell", tile: .lilac, color: .cobalt)
            Text("For left-behind and low-supply nudges. Allowing turns both on; switch either off in Settings. They never say what's in your Pod, and you can make them fully discreet in Settings.")
            switch notifications {
            case .unknown:
                Button("Allow notifications") {
                    Task { await allowNotifications() }
                }
                .buttonStyle(NanaPillButtonStyle())
            case .allowed:
                Label("Allowed", systemImage: "checkmark")
                    .nanaPill(.cobalt, foreground: .butter)
            case .denied:
                Button("Turn on in iOS Settings") { openURL(.notificationSettings) }
                .buttonStyle(NanaPillButtonStyle())
            }
        }
        .nanaCard(cornerRadius: 26, padding: 20)
    }

    private func allowNotifications() async {
        if await NotificationScheduler.requestAuthorization() {
            turnOnNudges()
        } else {
            notifications = .denied
        }
    }

    private func turnOnNudges() {
        notifications = .allowed
        AppSettings.turnOnNudges()
        leftBehind.reschedule()
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
