import XCTest
@testable import SsakCore

final class ReconcileGrowthTests: XCTestCase {
    func testHealthyGrowthAccruesProportionally() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.85   // stays healthy across a short window
        let out = GrowthEngine.reconcile(s, to: day(0, hour: 21), species: SpeciesCatalog.marigold)
        // 0.5 day of healthy growth ÷ bloomDays 7
        XCTAssertEqual(out.progress, 0.5 / 7, accuracy: 0.005)
        XCTAssertEqual(out.moisture, 0.85 - 0.55 * 0.5, accuracy: 0.002)
        XCTAssertEqual(out.lastUpdate, day(0, hour: 21))
    }

    func testBloomsAfterExactlyBloomDaysOfHealthyTime() {
        var tuning = GrowthTuning.default
        tuning.drainPerDay = 0   // hold moisture so bloomDays alone governs
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.8
        let out = GrowthEngine.reconcile(s, to: day(7), species: SpeciesCatalog.marigold, tuning: tuning)
        XCTAssertEqual(out.progress, 1.0, accuracy: 0.001)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .bloom)
    }

    func testNoElapsedNoChange() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        let out = GrowthEngine.reconcile(s, to: day(0), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, s.progress, accuracy: 0.0001)
    }

    func testDrainZeroAtDryThresholdDoesNotNaN() {
        var tuning = GrowthTuning.default
        tuning.drainPerDay = 0
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = tuning.dryThreshold   // exactly at the dry boundary
        let out = GrowthEngine.reconcile(s, to: day(3), species: SpeciesCatalog.marigold, tuning: tuning)
        XCTAssertFalse(out.progress.isNaN)
        XCTAssertEqual(out.progress, 0, accuracy: 0.0001)   // at/below dry boundary → no growth
    }
}
