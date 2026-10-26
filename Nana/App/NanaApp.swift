import SwiftData
import SwiftUI

@main
struct NanaApp: App {
    private let modelContainer: ModelContainer
    @State private var containerStore: ContainerStore
    @State private var placeMonitor: PlaceMonitor
    @State private var leftBehind: LeftBehindNudge
    @State private var router: AppRouter

    init() {
        UserDefaults.standard.register(defaults: AppSettings.defaults)
        do {
            modelContainer = try ModelContainer(for: SupplyEvent.self, Place.self)
        } catch {
            fatalError("Could not open Nana's local store: \(error)")
        }

        // Composition root: build the services once and wire their events together.
        let scheduler = NotificationScheduler()
        let containerStore = ContainerStore(modelContext: modelContainer.mainContext, nudges: scheduler)
        let placeMonitor = PlaceMonitor()
        let leftBehind = LeftBehindNudge(scheduler: scheduler)
        let router = AppRouter()

        containerStore.onLinkChange = { leftBehind.charmLinkChanged(disconnectedSince: $0) }
        placeMonitor.onChange = { leftBehind.placeChanged(isInside: $0) }
        scheduler.onOpen = { router.open($0) }
        leftBehind.charmLinkChanged(disconnectedSince: containerStore.disconnectedSince)

        // Started here, not from a view: iOS relaunches the app in the background
        // for Bluetooth and place events, and no view appears then.
        containerStore.start()
        Task { await placeMonitor.start() }

        _containerStore = State(initialValue: containerStore)
        _placeMonitor = State(initialValue: placeMonitor)
        _leftBehind = State(initialValue: leftBehind)
        _router = State(initialValue: router)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.cobalt)
                .preferredColorScheme(.light)
                .environment(containerStore)
                .environment(placeMonitor)
                .environment(leftBehind)
                .environment(router)
        }
        .modelContainer(modelContainer)
    }
}
