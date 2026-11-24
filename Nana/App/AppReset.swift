import SwiftData
import UIKit
import UserNotifications

/// "Delete everything": forgets the Pod, the count history, every setting and
/// every notification.
enum AppReset {
    enum Failure: Error {
        /// The Pod couldn't be unpaired, so nothing was deleted.
        case unpair
        /// Unpaired, but the count history couldn't be deleted.
        case history
    }

    /// Unpairs first and stops if that fails, so the app never says "deleted"
    /// while the Pod is still paired.
    static func eraseAll(modelContext: ModelContext, containerStore: ContainerStore, router: AppRouter) async throws(Failure) {
        do {
            // Leaving the demo also switches back to Bluetooth, so the next "Pair"
            // looks for a real Pod.
            if containerStore.usesDemo {
                await containerStore.stopDemo()
            } else {
                try await containerStore.forget()
            }
        } catch {
            throw .unpair
        }
        do {
            try SupplyEvent.deleteAll(in: modelContext)
            try modelContext.save()
        } catch {
            throw .history
        }
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        try? await UIApplication.shared.setAlternateIconName(nil)
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        // Set, not just removed, so `@AppStorage` sees the change and shows Welcome.
        UserDefaults.standard.set(false, forKey: AppSettings.hasOnboarded)
        router.reset()
    }
}
