import XCTest
@testable import SsakCore

final class PlantLifecycleTests: XCTestCase {
    func testPlantStartsSeedMoistAndWatered() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        XCTAssertEqual(s.speciesID, "marigold")
        XCTAssertEqual(s.progress, 0, accuracy: 0.0001)
        XCTAssertEqual(GrowthEngine.stage(forProgress: s.progress), .seed)
        XCTAssertGreaterThan(s.moisture, GrowthTuning.default.dryThreshold)
        XCTAssertEqual(s.streak, 1)
        XCTAssertFalse(s.isNursing)
        XCTAssertEqual(s.lastWateredAt, day(0))
    }
    func testHasWateredToday() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        XCTAssertTrue(GrowthEngine.hasWateredToday(s, now: day(0, hour: 20), calendar: utcCal))
        XCTAssertFalse(GrowthEngine.hasWateredToday(s, now: day(2), calendar: utcCal))
    }
}
