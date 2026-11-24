import SwiftData
import SwiftUI
import UIKit
import UserNotifications

/// Everything about the Pod in one place, for testing on a phone without a Mac:
/// the link, the last packet, the count, the left-behind state and an event log.
/// Opened by long-pressing the "nana" wordmark on Home, in Xcode and TestFlight
/// builds only (see `DebugLog.isAvailable`).
struct DebugView: View {
    @Environment(ContainerStore.self) private var containerStore
    @Environment(LeftBehindNudge.self) private var leftBehind
    @Query(SupplyEvent.latest) private var events: [SupplyEvent]
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationStatus = "Checking…"
    @State private var copied = false
    @State private var logEntries: [DebugLog.Entry] = []
    @State private var logError: String?
    /// "Clear" hides older entries; the system log itself can't be emptied.
    @State private var clearedAt: Date?

    @AppStorage(AppSettings.leftBehindNudgeOn) private var leftBehindOn = false
    @AppStorage(AppSettings.lowSupplyNudgeOn) private var lowSupplyOn = false
    @AppStorage(AppSettings.leftBehindWaitMinutes) private var waitMinutes = 2
    @AppStorage(AppSettings.discreetNudges) private var isDiscreet = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                Text("Debugger").nanaScreenTitle()
                pod
                // Ages like "12 s ago" and the left-behind state change with time alone.
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .leading, spacing: 22) {
                        lastPacket(now: context.date)
                        count
                        leftBehindState(now: context.date)
                    }
                }
                notifications
                eventLog
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .nanaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .task(id: scenePhase) { await checkNotifications() }
        .task(id: LogPolling(clearedAt: clearedAt, isActive: scenePhase == .active)) { await keepLogFresh() }
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }

    /// Restarts log polling when the log is cleared, and stops it in the background.
    private struct LogPolling: Equatable {
        var clearedAt: Date?
        var isActive: Bool
    }

    // MARK: Sections

    private var pod: some View {
        section("Pod") {
            row("Mode", containerStore.usesDemo ? "Demo Pod" : "Real Pod (Bluetooth)")
            row("Paired", yesNo(containerStore.isPaired))
            row("Connection", connectionText, tint: containerStore.connection == .connected ? .cobalt : .tangerine)
            row("Battery", containerStore.battery.map { "\($0)%" } ?? "Not reported")
            row("Capacity", "\(containerStore.capacity) slots")
        }
    }

    private func lastPacket(now: Date) -> some View {
        section("Last reading from the Pod") {
            if let reading = containerStore.lastReading, let at = containerStore.lastReadingAt {
                row("Count", reading.count.map(String.init) ?? "Unknown")
                row("Lid", reading.lidOpen ? "Open" : "Shut", tint: reading.lidOpen ? .tangerine : .cobalt)
                row("Fill level", reading.levelPercent.map { "\($0)%" } ?? "Not reported")
                row("Received", "\(age(of: at, now: now)) (\(at.formatted(date: .omitted, time: .standard)))")
            } else {
                row("Received", "Nothing yet since the app started")
            }
        }
    }

    private var count: some View {
        section("Count in the app") {
            if let latest = events.first {
                row("Shown on Home", "\(latest.amount)")
                row("Recorded", latest.date.formatted(date: .abbreviated, time: .standard))
                row("Level", "\(SupplyLedger.level(of: latest.amount))")
            } else {
                row("Shown on Home", "Nothing counted yet")
            }
        }
    }

    private func leftBehindState(now: Date) -> some View {
        section("Left behind") {
            row("Out of range since", leftBehind.disconnectedSince.map { time($0) } ?? "In range")
            row("Left behind now", yesNo(leftBehind.isLeftBehind(at: now)))
            row("Paused (Bluetooth off)", yesNo(leftBehind.isBluetoothOff))
            row("Next nudge due", leftBehind.nextNudgeDate.map { time($0) } ?? "None")
            row("Last scheduled", leftBehind.scheduledFor.map { time($0) } ?? "None")
            row("Snoozed until", leftBehind.snoozedUntil.map { time($0) } ?? "No")
            row("Left on purpose", yesNo(leftBehind.isDismissed))
        }
    }

    private var notifications: some View {
        section("Notifications") {
            row("iOS permission", notificationStatus)
            row("Left-behind nudge", onOff(leftBehindOn))
            row("Running-low nudge", onOff(lowSupplyOn))
            row("Wait before nudging", "\(waitMinutes) min")
            row("Discreet", onOff(isDiscreet))
            Button("Send a test notification in 5 s", action: sendTestNotification)
                .font(.nanaLabel)
                .foregroundStyle(.cobalt)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Event log").nanaCaptionStyle()
            HStack(spacing: 10) {
                Button(copied ? "Copied" : "Copy log") {
                    UIPasteboard.general.string = DebugLog.text(for: logEntries)
                    copied = true
                }
                .buttonStyle(NanaPillButtonStyle())
                Button("Clear") { clearedAt = .now }
                    .buttonStyle(NanaPillButtonStyle())
            }
            LazyVStack(alignment: .leading, spacing: 8) {
                if let logError {
                    Text(logError).font(.nanaFootnote).foregroundStyle(Color.destructive)
                } else if logEntries.isEmpty {
                    Text("Nothing logged yet.").font(.nanaFootnote).foregroundStyle(.inkSoft)
                }
                // Newest first; long sessions only show the latest 300.
                ForEach(logEntries.suffix(300).reversed()) { entry in
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(entry.date.formatted(.dateTime.hour().minute().second())) · \(entry.category)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.inkSoft)
                        Text(entry.message)
                            .font(.footnote.monospaced())
                            .foregroundStyle(entry.isError ? Color.destructive : .nightInk)
                            .textSelection(.enabled)
                    }
                }
            }
            .nanaCard()
        }
    }

    // MARK: Building blocks

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).nanaCaptionStyle()
            VStack(alignment: .leading, spacing: 10) { content() }
                .nanaCard()
        }
    }

    private func row(_ label: LocalizedStringKey, _ value: String, tint: Color = .nightInk) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.nanaCallout).foregroundStyle(.inkSoft)
            Spacer(minLength: 12)
            Text(value)
                .font(.nanaLabel)
                .foregroundStyle(tint)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private var connectionText: String {
        switch containerStore.connection {
        case .notPaired: "Not paired"
        case .connecting: "Connecting…"
        case .connected: "Connected"
        case .disconnected: "Out of range"
        case .unavailable: "Bluetooth off or not allowed"
        }
    }

    private func yesNo(_ value: Bool) -> String { value ? "Yes" : "No" }
    private func onOff(_ value: Bool) -> String { value ? "On" : "Off" }
    private func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .standard) }

    private func age(of date: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        return seconds < 60 ? "\(seconds) s ago" : "\(seconds / 60) min ago"
    }

    // MARK: Actions

    private func checkNotifications() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = switch settings.authorizationStatus {
        case .authorized: "Allowed"
        case .denied: "Denied in iOS Settings"
        case .notDetermined: "Not asked yet"
        case .provisional: "Provisional"
        case .ephemeral: "Ephemeral"
        @unknown default: "Unknown"
        }
    }

    /// `OSLogStore` has no change feed, so the log is read again every 2 s while the
    /// screen is up and the app is in front.
    private func keepLogFresh() async {
        while !Task.isCancelled, scenePhase == .active {
            let since = clearedAt
            do {
                logEntries = try await Task.detached { try DebugLog.entries(since: since) }.value
                logError = nil
            } catch {
                logError = "Couldn't read the log: \(error.localizedDescription)"
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Nana debugger"
        content.body = "Test notification. If you see this, delivery works."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "nana.debug.test", content: content, trigger: trigger))
        DebugLog.add("Test notification scheduled for 5 s from now", logger: .nudges)
    }
}

#if DEBUG
#Preview {
    NavigationStack { DebugView() }
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(ContainerStore.preview())
        .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
}
#endif
