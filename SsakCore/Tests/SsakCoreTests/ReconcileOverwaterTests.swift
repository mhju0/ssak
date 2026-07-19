import XCTest
@testable import SsakCore

final class ReconcileOverwaterTests: XCTestCase {
    func testWaterloggedPausesGrowth() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 1.3   // above tooWet 1.0; drains to 1.0 after (1.3-1.0)/0.55 = 0.545 day
        // window 0.5 day < 0.545 → waterlogged the whole time → no growth
        let out = GrowthEngine.reconcile(s, to: day(0, hour: 21), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, 0, accuracy: 0.003)
    }

    func testWaterloggedThenResumes() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 1.3
        // over 2 days: paused 0.545 day, then healthy until dry: (1.0-0.2)/0.55 = 1.454 day
        let out = GrowthEngine.reconcile(s, to: day(2), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, 1.454 / 7, accuracy: 0.02)
    }
}
