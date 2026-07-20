import XCTest
@testable import SsakCore

final class CalendarDayGapTests: XCTestCase {
    func testSameDayIsZero() {
        XCTAssertEqual(utcCal.dayGap(from: day(0, hour: 9), to: day(0, hour: 23)), 0)
    }

    // Discriminates the start-of-day normalization: a naive elapsed-hours impl would call
    // 11pm → 1am (next day) a gap of 0; measured start-of-day to start-of-day it is 1.
    func testCrossesMidnightIsOne() {
        XCTAssertEqual(utcCal.dayGap(from: day(0, hour: 23), to: day(1, hour: 1)), 1)
    }

    func testMultipleDays() {
        XCTAssertEqual(utcCal.dayGap(from: day(0), to: day(3)), 3)
    }

    func testBackwardsIsNegative() {
        XCTAssertEqual(utcCal.dayGap(from: day(2), to: day(0)), -2)
    }
}
