import XCTest
@testable import SsakCore

final class ReconcileDrynessTests: XCTestCase {
    func testDrySoilAccruesNoGrowth() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.1   // below dryThreshold 0.2
        let out = GrowthEngine.reconcile(s, to: day(2), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, 0, accuracy: 0.0001)
    }

    func testGrowthStopsWhenMoistureRunsDry() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.75   // drains to dry(0.2) after (0.75-0.2)/0.55 = 1.0 day
        let out = GrowthEngine.reconcile(s, to: day(3), species: SpeciesCatalog.marigold)
        // only ~1.0 healthy day out of 3 elapsed
        XCTAssertEqual(out.progress, 1.0 / 7, accuracy: 0.02)
        XCTAssertEqual(out.moisture, 0, accuracy: 0.0001)  // fully drained (clamped)
    }
}
