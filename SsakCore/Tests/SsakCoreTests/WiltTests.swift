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

    // Regress from the LOWEST stage that can still wilt (sprout) and assert it lands
    // exactly on the seed floor — not just "≥ 0". Fails if the wilt block is deleted
    // (progress would stay in sprout) or if the floor were computed wrong.
    func testWiltFloorsExactlyAtSeedFromLowestStage() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.2                 // sprout — one stage above seed
        s.moisture = 0.0
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(6), species: SpeciesCatalog.marigold)
        XCTAssertTrue(out.isNursing)
        XCTAssertEqual(out.progress, GrowthEngine.progressAtStartOf(.seed))  // exactly 0.0, not below
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .seed)
    }

    // The `!isNursing` guard caps wilt at one stage per neglect episode. Without it, a
    // still-dry nursing plant would lose a stage on every reconcile (app foreground),
    // cascading to seed. Fails if that guard is removed (leaves → sprout here).
    func testAlreadyNursingDoesNotRegressAgain() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.5                 // leaves
        s.moisture = 0.0
        s.isNursing = true               // already nursing from a prior episode
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(6), species: SpeciesCatalog.marigold)  // 6 dry days
        XCTAssertTrue(out.isNursing)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .leaves)  // NOT regressed again
    }

    // Boundary: unwateredDays == wiltAfterDryDays must wilt (guard is `>=`, not `>`).
    // Fails if the comparison is tightened to `>`.
    func testWiltFiresAtExactDayThreshold() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.5
        s.moisture = 0.0
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(4), species: SpeciesCatalog.marigold)  // exactly 4 days
        XCTAssertTrue(out.isNursing)
    }

    // Boundary: moisture == dryThreshold must NOT wilt (guard is strict `<`). Uses a
    // drain-free tuning to pin moisture exactly on the threshold with no float drift.
    // Fails if the comparison is loosened to `<=`.
    func testWiltDoesNotFireAtExactMoistureThreshold() {
        var t = GrowthTuning.default
        t.drainPerDay = 0                // moisture stays put at startM
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.5
        s.moisture = t.dryThreshold      // exactly on the boundary
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(5), species: SpeciesCatalog.marigold, tuning: t)  // 5 dry days
        XCTAssertEqual(out.moisture, t.dryThreshold)  // confirm it landed on the boundary
        XCTAssertFalse(out.isNursing)                 // strict < → no wilt at the threshold
    }
}
