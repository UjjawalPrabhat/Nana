import Foundation
import Testing
@testable import Nana

struct DebugLogTests {
    @Test func entriesWrittenWithLoggerCanBeReadBack() throws {
        let marker = "debug-log-test \(UUID().uuidString)"
        DebugLog.add(marker)
        DebugLog.add("\(marker) failed", isError: true)

        let entries = try DebugLog.entries()
        let ours = entries.filter { $0.message.hasPrefix(marker) }
        #expect(ours.map(\.isError) == [false, true])
        #expect(ours.first?.category == "pod")
    }
}
