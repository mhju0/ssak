import XCTest
@testable import SsakCore

final class WiltTests: XCTestCase {
    func testProlongedNeglectWiltsBackOneStage() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.5                 // mid "leaves" stage
        s.moisture = 0.1                 // already dry
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(5), species: SpeciesCatalog.marigold)  // 5 days unwatered ≥ 4
        XCTAssertTrue(out.isNursing)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .sprout)  // leaves → sprout
    }

    func testShortNeglectDoesNotWilt() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.5
        s.moisture = 0.1
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(2), species: SpeciesCatalog.marigold)  // 2 days < 4
        XCTAssertFalse(out.isNursing)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .leaves)  // unchanged
    }

    func testWiltNeverTakesProgressBelowSeed() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.05                // seed stage
        s.moisture = 0.0
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(6), species: SpeciesCatalog.marigold)
        XCTAssertGreaterThanOrEqual(out.progress, 0)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .seed)
    }
}
