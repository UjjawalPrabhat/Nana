import Foundation
import SwiftData
import Testing
@testable import Nana

struct ContainerStoreTests {
    /// Held for the test's lifetime: a context whose container is released traps on save.
    private let container: ModelContainer
    private let defaults: UserDefaults
    private let scheduler = RecordingScheduler()
    private var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: SupplyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        defaults = UserDefaults(suiteName: "tests.\(UUID().uuidString)")!
        defaults.set(true, forKey: AppSettings.lowSupplyNudgeOn)
    }

    private func makeStore() -> ContainerStore {
        ContainerStore(modelContext: context, nudges: scheduler, defaults: defaults, forceDemo: true)
    }

    private func storedAmounts() throws -> [Int] {
        try context.fetch(FetchDescriptor<SupplyEvent>()).map(\.amount)
    }

    @Test func olderReadingsAreDroppedAtLaunch() throws {
        let start = Date(timeIntervalSince1970: 1_000_000)
        for (minutes, amount) in [(0.0, 3), (5.0, 2), (9.0, 1)] {
            context.insert(SupplyEvent(date: start.addingTimeInterval(minutes * 60), kind: .deviceReading, amount: amount))
        }
        try context.save()

        _ = makeStore()

        #expect(try storedAmounts() == [1])
    }

    @Test func keepsOneReadingAndNudgesOnceWhenRunningLow() throws {
        let store = makeStore()  // the transport holds it weakly
        let demo = try #require(store.demo)
        demo.simulateChange(by: 0)  // the demo starts at 2
        demo.simulateChange(by: -1)
        demo.simulateChange(by: 0)  // a reconnect re-sends the same count

        #expect(try storedAmounts() == [1])
        #expect(scheduler.scheduled.map(\.nudge) == [.lowSupply])
    }

    @Test func noLowNudgeWhenSwitchedOff() throws {
        defaults.set(false, forKey: AppSettings.lowSupplyNudgeOn)
        let store = makeStore()  // the transport holds it weakly
        let demo = try #require(store.demo)
        demo.simulateChange(by: -1)

        #expect(try storedAmounts() == [1])
        #expect(scheduler.scheduled.isEmpty)
    }
}
