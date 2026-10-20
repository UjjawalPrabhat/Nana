import Foundation
import Testing
@testable import Nana

struct ContainerProtocolTests {
    @Test func parsesExactCount() {
        let reading = StockPacket.parse(Data([0x01, 0x01, 0x06, 0xFF]))
        #expect(reading == StockReading(count: 6, levelPercent: nil))
        #expect(reading?.estimatedCount(capacity: 12) == 6)
        #expect(reading?.isEstimate == false)
    }

    @Test func levelOnlyBecomesEstimate() {
        let reading = StockPacket.parse(Data([0x01, 0x02, 0xFF, 50]))
        #expect(reading?.count == nil)
        #expect(reading?.estimatedCount(capacity: 12) == 6)
        #expect(reading?.isEstimate == true)
    }

    @Test func flagsAreDecoded() {
        let reading = StockPacket.parse(Data([0x01, 0b1101, 0x03, 0xFF]))
        #expect(reading?.lidOpen == true)
        #expect(reading?.needsCalibration == true)
    }

    @Test func rejectsUnknownVersionAndShortPackets() {
        #expect(StockPacket.parse(Data([0x02, 0x01, 0x06, 0xFF])) == nil)
        #expect(StockPacket.parse(Data([0x01, 0x01])) == nil)
    }

    @Test func unknownValuesAreIgnoredEvenIfFlagged() {
        let reading = StockPacket.parse(Data([0x01, 0x03, 0xFF, 0xFF]))
        #expect(reading?.estimatedCount(capacity: 12) == nil)
    }

    @Test func encodeRoundTrips() {
        let original = StockReading(count: 4, levelPercent: 33, lidOpen: true, needsCalibration: false)
        #expect(StockPacket.parse(StockPacket.encode(original)) == original)
    }

    @Test func countAboveCapacityIsClamped() {
        #expect(StockReading(count: 30).estimatedCount(capacity: 12) == 12)
    }

    @Test(arguments: [
        (Optional(5), 2, true), (Optional(3), 2, true), (Optional(2), 2, false),
        (Optional(1), 0, false), (nil, 2, true), (Optional(5), 3, false),
    ])
    func lowSupplyFiresOnlyWhenCrossingThreshold(previous: Int?, current: Int, expected: Bool) {
        #expect(LowSupplyReminder.shouldNotify(previous: previous, current: current, threshold: 2) == expected)
    }
}
