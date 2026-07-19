import XCTest
@testable import SsakCore

final class WateringTests: XCTestCase {
    func testWaterRaisesMoistureCappedAtMax() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 1.0
        let out = GrowthEngine.water(s, at: day(0), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(out.moisture, 1.3, accuracy: 0.001)  // 1.0 + 0.6, capped at moistureMax 1.3
    }

    func testStreakConsecutiveSameGap() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))   // streak 1
        s = GrowthEngine.water(s, at: day(1), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(s.streak, 2)                                        // next day
        s = GrowthEngine.water(s, at: day(1, hour: 20), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(s.streak, 2)                                        // same day → unchanged
        s = GrowthEngine.water(s, at: day(4), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(s.streak, 1)                                        // gap → reset
    }

    func testWateringClearsNursing() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.isNursing = true
        let out = GrowthEngine.water(s, at: day(1), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertFalse(out.isNursing)
    }
}
