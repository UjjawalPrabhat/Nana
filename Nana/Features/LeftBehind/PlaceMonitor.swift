import CoreLocation
import Foundation

/// Watches the saved places with `CLMonitor` and says whether you're inside one.
/// iOS relaunches the app on a place event, so `start()` runs at every launch.
@Observable
final class PlaceMonitor: NSObject {
    private(set) var isInsidePlace = false
    private(set) var authorization: CLAuthorizationStatus

    /// Called whenever `isInsidePlace` changes.
    @ObservationIgnored var onChange: ((Bool) -> Void)?

    @ObservationIgnored private let manager = CLLocationManager()
    /// One monitor per name is allowed, so every caller shares this task.
    @ObservationIgnored private var monitorTask: Task<CLMonitor, Never>?
    @ObservationIgnored private var session: CLServiceSession?
    @ObservationIgnored private var insideIDs: Set<String> = [] {
        didSet {
            guard isInsidePlace != !insideIDs.isEmpty else { return }
            isInsidePlace = !insideIDs.isEmpty
            onChange?(isInsidePlace)
        }
    }

    // Letters only: CLMonitor rejects names with punctuation.
    private static let monitorName = "NanaPlaces"

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var hasAlwaysAccess: Bool { authorization == .authorizedAlways }

    func start() async {
        _ = await monitor()
    }

    /// Makes the monitored regions match the saved places.
    func sync(_ regions: [PlaceRegion]) async {
        let monitor = await monitor()
        let wanted = Set(regions.map(\.id))
        for id in await monitor.identifiers where !wanted.contains(id) {
            await monitor.remove(id)
        }
        for region in regions {
            let condition = CLMonitor.CircularGeographicCondition(center: region.center, radius: region.radius)
            await monitor.add(condition, identifier: region.id)
        }
        // Keep "Always" access alive only while there's something to watch.
        session = regions.isEmpty ? nil : (session ?? CLServiceSession(authorization: .always))
        await refreshInside(monitor)
    }

    private func monitor() async -> CLMonitor {
        if let monitorTask { return await monitorTask.value }
        let task = Task { await CLMonitor(Self.monitorName) }
        monitorTask = task
        let monitor = await task.value
        await refreshInside(monitor)
        Task { [weak self] in
            do {
                for try await event in await monitor.events {
                    self?.record(id: event.identifier, isInside: event.state == .satisfied)
                }
            } catch {}
        }
        return monitor
    }

    /// Asks for location in context: While Using first, then iOS offers Always.
    func requestAlwaysAccess() {
        session = session ?? CLServiceSession(authorization: .always)
    }

    /// One fix for "Use my location", asking for While Using access if needed.
    func currentLocation() async -> CLLocationCoordinate2D? {
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location { return location.coordinate }
                if update.authorizationDenied || update.authorizationDeniedGlobally { return nil }
            }
        } catch {}
        return nil
    }

    private func refreshInside(_ monitor: CLMonitor) async {
        var inside: Set<String> = []
        for id in await monitor.identifiers {
            if await monitor.record(for: id)?.lastEvent.state == .satisfied { inside.insert(id) }
        }
        insideIDs = inside
    }

    private func record(id: String, isInside: Bool) {
        if isInside { insideIDs.insert(id) } else { insideIDs.remove(id) }
    }
}

extension PlaceMonitor: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
    }
}
