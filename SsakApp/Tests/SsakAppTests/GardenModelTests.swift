import XCTest
import SsakCore
@testable import SsakApp

@MainActor
final class GardenModelTests: XCTestCase {

    func testNewGamePlantsStarter() {
        let m = GardenModel(store: tempStore(), now: day(0), calendar: utcCal)
        XCTAssertEqual(m.state.plant.speciesID, "marigold")
        XCTAssertEqual(m.stage, .seed)
        XCTAssertTrue(m.collected.isEmpty)
    }

    func testReconcileOnOpenAccruesHealthyGrowth() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 1.0                      // well-watered → stays in the healthy band
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        let before = m.state.plant.progress
        m.reconcileOnOpen(now: day(1))
        XCTAssertGreaterThan(m.state.plant.progress, before)
    }

    func testWaterRaisesMoistureAndMarksWateredToday() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.2
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        m.water(now: day(0, hour: 12))
        XCTAssertGreaterThan(m.state.plant.moisture, 0.2)
        XCTAssertTrue(m.hasWateredToday(now: day(0, hour: 13)))
    }

    func testStreakAliveUnlessFullDayMissed() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.lastWateredAt = day(0)
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        XCTAssertTrue(m.isStreakAlive(now: day(0, hour: 20)))   // same day
        XCTAssertTrue(m.isStreakAlive(now: day(1, hour: 8)))    // next day, today not yet missed
        XCTAssertFalse(m.isStreakAlive(now: day(2, hour: 8)))   // a full day (day 1) was missed
    }

    func testPressAndReplantCollectsOnceAndResets() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 1.0                      // bloomed
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        XCTAssertEqual(m.stage, .bloom)
        m.pressAndReplant(SpeciesCatalog.cosmos, now: day(1))
        XCTAssertEqual(m.collected, ["marigold"])
        XCTAssertEqual(m.state.plant.speciesID, "cosmos")
        XCTAssertEqual(m.stage, .seed)
        // pressing the new (seed, un-bloomed) plant does nothing
        m.pressAndReplant(SpeciesCatalog.zinnia, now: day(2))
        XCTAssertEqual(m.collected, ["marigold"])
    }

    func testGardenCompleteOnlyWithAllSix() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        let five = ["marigold", "nasturtium", "cosmos", "zinnia", "sunflower"]
        let m = GardenModel(state: GameState(plant: s, collected: five), store: tempStore(), calendar: utcCal)
        XCTAssertFalse(m.isGardenComplete)
        let m2 = GardenModel(state: GameState(plant: s, collected: five + ["morning_glory"]),
                             store: tempStore(), calendar: utcCal)
        XCTAssertTrue(m2.isGardenComplete)
    }

    /// "Day N" counts calendar days like the rest of the game (dayGap semantics), not
    /// 24-hour blocks: planted late evening, the next morning is Day 2 — not still Day 1.
    func testCurrentDayCountsCalendarDays() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0, hour: 23))
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        XCTAssertEqual(m.currentDay(now: day(0, hour: 23)), 1)   // planting day is Day 1
        XCTAssertEqual(m.currentDay(now: day(1, hour: 9)), 2)    // next calendar morning
        XCTAssertEqual(m.currentDay(now: day(7, hour: 9)), 8)
    }

    /// The press flow's "what grows next": catalog order, skipping the shelf AND the plant
    /// being pressed — a fresh marigold's next is nasturtium, never marigold itself.
    func testNextUncollectedSkipsShelfAndCurrentPlant() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        XCTAssertEqual(m.nextUncollected?.id, "nasturtium")

        let mid = GardenModel(state: GameState(plant: s, collected: ["nasturtium", "cosmos"]),
                              store: tempStore(), calendar: utcCal)
        XCTAssertEqual(mid.nextUncollected?.id, "zinnia")

        let allButCurrent = SpeciesCatalog.all.map(\.id).filter { $0 != "marigold" }
        let last = GardenModel(state: GameState(plant: s, collected: allButCurrent),
                               store: tempStore(), calendar: utcCal)
        XCTAssertNil(last.nextUncollected)
    }

    /// Onboarding pick: a fresh, untouched game can swap its starter seed for any species.
    func testChoosePlantSwapsFreshSeed() {
        let m = GardenModel(store: tempStore(), now: day(0), calendar: utcCal)
        m.choosePlant(SpeciesCatalog.sunflower, now: day(0))
        XCTAssertEqual(m.species.id, "sunflower")
        XCTAssertEqual(m.stage, .seed)
    }

    /// …but never once the game has progressed past the fresh seed or pressed a flower.
    func testChoosePlantIsNoOpOnceProgressed() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.3
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        m.choosePlant(SpeciesCatalog.sunflower, now: day(2))
        XCTAssertEqual(m.species.id, "marigold")
        XCTAssertEqual(m.state.plant.progress, 0.3)

        let fresh = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        let m2 = GardenModel(state: GameState(plant: fresh, collected: ["cosmos"]),
                             store: tempStore(), calendar: utcCal)
        m2.choosePlant(SpeciesCatalog.sunflower, now: day(0))
        XCTAssertEqual(m2.species.id, "marigold")
    }

    /// The full first-press loop the UI drives: bloomed starter + empty shelf →
    /// press lands marigold on the shelf and the next uncollected species is planted.
    func testFirstBloomPressesViaNextUncollected() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 1.0
        let m = GardenModel(state: GameState(plant: s, collected: []), store: tempStore(), calendar: utcCal)
        m.pressAndReplant(m.nextUncollected ?? m.species, now: day(7))
        XCTAssertEqual(m.collected, ["marigold"])
        XCTAssertEqual(m.species.id, "nasturtium")
        XCTAssertEqual(m.stage, .seed)
    }
}
