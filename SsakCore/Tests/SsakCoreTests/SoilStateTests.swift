import XCTest
@testable import SsakCore

final class SoilStateTests: XCTestCase {
    let t = GrowthTuning.default   // dryThreshold 0.2, tooWetThreshold 1.0

    func testDryBelowThreshold() {
        XCTAssertEqual(SoilState(moisture: 0.0, tuning: t), .dry)
        XCTAssertEqual(SoilState(moisture: 0.19, tuning: t), .dry)
    }

    // Boundary: exactly dryThreshold is moist — matches the engine's `>= dryThreshold` growth gate.
    func testAtDryThresholdIsMoist() {
        XCTAssertEqual(SoilState(moisture: 0.2, tuning: t), .moist)
    }

    func testMidRangeMoist() {
        XCTAssertEqual(SoilState(moisture: 0.6, tuning: t), .moist)
    }

    // Boundary: exactly tooWetThreshold is moist — matches the engine's `> tooWetThreshold` waterlog pause.
    func testAtWetThresholdIsMoist() {
        XCTAssertEqual(SoilState(moisture: 1.0, tuning: t), .moist)
    }

    func testAboveWetIsOverfull() {
        XCTAssertEqual(SoilState(moisture: 1.01, tuning: t), .overfull)
        XCTAssertEqual(SoilState(moisture: 1.3, tuning: t), .overfull)   // moistureMax cap is still over-full
    }
}
