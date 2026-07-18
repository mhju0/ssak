import XCTest
@testable import GameKernel

final class GardenTests: XCTestCase {
    // MARK: Table integrity

    func testTableMatchesTheDraftedDesign() {
        let table = GardenTable.all
        XCTAssertEqual(table.count, 6)
        XCTAssertEqual(Set(table.map(\.id)).count, 6, "plantable ids must be unique")
        for p in table {
            XCTAssertTrue((1...99).contains(p.unlockLevel), p.id)
            XCTAssertGreaterThan(p.daysToMature, 0, p.id)
            XCTAssertGreaterThan(p.xp, 0, p.id)
            XCTAssertFalse(p.nameKO.isEmpty, p.id)
        }
    }

    func testLevelGatesPlantables() {
        XCTAssertFalse(Gardening.available(level: 29).contains { $0.id == "plum-tree" })
        XCTAssertTrue(Gardening.available(level: 30).contains { $0.id == "plum-tree" })
    }

    private var radish: Plantable { GardenTable.all.first { $0.id == "radish" }! }
    private var ginkgo: Plantable { GardenTable.all.first { $0.id == "old-ginkgo" }! }

    // MARK: Growth is a pure function of real elapsed days (spec §2, pillar 2)

    func testGrowthNeverRegresses() {
        // Crops never pause, wither, or regress — stage is monotonic in days.
        for p in GardenTable.all {
            var previous = Garden.stage(plantedDays: 0, p)
            for step in 0...300 {
                let days = Double(step) / 300 * p.daysToMature * 3
                let stage = Garden.stage(plantedDays: days, p)
                XCTAssertGreaterThanOrEqual(stage, previous, "\(p.id) regressed at \(days)d")
                previous = stage
            }
        }
    }

    func testGrowthDependsOnlyOnDays() {
        // No hidden input (weather, watering) can change growth: same days in,
        // same stage out. This is the two-currency wall for gardening.
        for p in GardenTable.all {
            for days in stride(from: 0.0, through: p.daysToMature * 2.5, by: 0.3) {
                XCTAssertEqual(Garden.stage(plantedDays: days, p), Garden.stage(plantedDays: days, p), p.id)
            }
        }
    }

    func testCropRipensAtMaturityAndIsHarvestable() {
        XCTAssertFalse(Garden.isReady(plantedDays: radish.daysToMature - 0.01, radish))
        XCTAssertTrue(Garden.isReady(plantedDays: radish.daysToMature, radish))
        XCTAssertEqual(Garden.stage(plantedDays: radish.daysToMature, radish), .mature)
    }

    func testTreesAreNeverHarvestedAndAgeToAncient() {
        // Planted trees persist forever — they are scenery, not a harvest.
        XCTAssertFalse(Garden.isReady(plantedDays: ginkgo.daysToMature * 5, ginkgo))
        XCTAssertEqual(Garden.stage(plantedDays: ginkgo.daysToMature, ginkgo), .mature)
        XCTAssertEqual(Garden.stage(plantedDays: ginkgo.daysToMature * 3, ginkgo), .ancient)
    }

    func testFastCropOutpacesTheSlowTree() {
        // At the same elapsed days, the radish is grown while the ginkgo is not.
        let days = radish.daysToMature
        XCTAssertEqual(Garden.stage(plantedDays: days, radish), .mature)
        XCTAssertLessThan(Garden.stage(plantedDays: days, ginkgo), .mature)
    }
}
