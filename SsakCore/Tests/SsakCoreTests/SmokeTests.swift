import XCTest
@testable import SsakCore

final class SmokeTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(SsakCore.version, "0.1.0")
    }
    func testDayHelperIsUTC() {
        XCTAssertEqual(day(1).timeIntervalSince(day(0)), 86400, accuracy: 0.5)
    }
}
