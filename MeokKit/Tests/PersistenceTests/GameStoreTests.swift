import XCTest
import SwiftData
import GameKernel
@testable import Persistence

@MainActor
final class GameStoreTests: XCTestCase {
    private var store: GameStore!

    override func setUp() async throws {
        store = try GameStore.inMemory()
    }

    private var crucian: FishSpecies {
        FishingTable.all.first { $0.id == "crucian-carp" }!
    }

    func testCatchAwardsXPAndRecordsTheVariant() throws {
        let outcome = store.record(catch: crucian, weather: .rain)

        XCTAssertEqual(outcome.xpAwarded, 60)
        XCTAssertEqual(outcome.level, 1)
        XCTAssertFalse(outcome.leveledUp)
        XCTAssertTrue(outcome.firstOfSpecies)
        XCTAssertTrue(outcome.newWeatherVariant)

        XCTAssertEqual(store.progress(for: .fishing).xp, 60)
        let record = try XCTUnwrap(store.record(for: "crucian-carp"))
        XCTAssertEqual(record.timesCaught, 1)
        XCTAssertEqual(record.caughtWeathers, ["rain"])
        XCTAssertFalse(record.gotAway)
    }

    func testRepeatCatchCountsButDoesNotDuplicateTheVariant() throws {
        _ = store.record(catch: crucian, weather: .rain)
        let second = store.record(catch: crucian, weather: .rain)

        XCTAssertFalse(second.firstOfSpecies)
        XCTAssertFalse(second.newWeatherVariant)
        let record = try XCTUnwrap(store.record(for: "crucian-carp"))
        XCTAssertEqual(record.timesCaught, 2)
        XCTAssertEqual(record.caughtWeathers, ["rain"])

        let clearCatch = store.record(catch: crucian, weather: .clear)
        XCTAssertTrue(clearCatch.newWeatherVariant)
        XCTAssertEqual(Set(store.record(for: "crucian-carp")!.caughtWeathers), ["rain", "clear"])
    }

    func testLevelUpIsDetectedAtTheThreshold() {
        // 250 XP ends level 1; five 60-XP crucians cross it.
        for _ in 0..<4 { _ = store.record(catch: crucian, weather: .clear) }
        XCTAssertEqual(store.progress(for: .fishing).xp, 240)

        let fifth = store.record(catch: crucian, weather: .clear)
        XCTAssertTrue(fifth.leveledUp)
        XCTAssertEqual(fifth.level, 2)
    }

    func testEscapeLogsTheShadowAndCostsNothing() throws {
        store.recordEscape(of: crucian)

        XCTAssertEqual(store.progress(for: .fishing).xp, 0, "a lost fish costs only the moment")
        let record = try XCTUnwrap(store.record(for: "crucian-carp"))
        XCTAssertTrue(record.gotAway)
        XCTAssertEqual(record.timesCaught, 0)

        // Catching it later keeps the shadow history but fills the entry.
        _ = store.record(catch: crucian, weather: .clear)
        XCTAssertEqual(store.record(for: "crucian-carp")!.timesCaught, 1)
    }

    private var mugwort: Forageable {
        ForagingTable.all.first { $0.id == "mugwort" }!
    }

    func testGatherAwardsForagingXPIndependentlyOfFishing() throws {
        let outcome = store.record(gather: mugwort, weather: .clear)

        XCTAssertEqual(outcome.xpAwarded, 40)
        XCTAssertTrue(outcome.firstOfSpecies)
        XCTAssertTrue(outcome.newWeatherVariant)

        // The haul lands on foraging, never fishing — separate currencies.
        XCTAssertEqual(store.progress(for: .foraging).xp, 40)
        XCTAssertEqual(store.progress(for: .fishing).xp, 0)

        let record = try XCTUnwrap(store.record(for: "mugwort"))
        XCTAssertEqual(record.timesCaught, 1)
        XCTAssertEqual(record.caughtWeathers, ["clear"])
    }

    func testGatherAccruesVariantsLikeAcatch() throws {
        _ = store.record(gather: mugwort, weather: .clear)
        let foggy = store.record(gather: mugwort, weather: .fog)
        XCTAssertFalse(foggy.firstOfSpecies)
        XCTAssertTrue(foggy.newWeatherVariant)
        XCTAssertEqual(Set(store.record(for: "mugwort")!.caughtWeathers), ["clear", "fog"])
    }

    private var radishP: Plantable { GardenTable.all.first { $0.id == "radish" }! }
    private var plumTree: Plantable { GardenTable.all.first { $0.id == "plum-tree" }! }
    private let noon = Date(timeIntervalSince1970: 1_000_000)

    func testPlantingATreeYieldsAtPlantingAndPersists() {
        store.plant(plumTree, at: 0, now: noon)
        // A tree's yield is the planting itself — it stands forever.
        XCTAssertEqual(store.progress(for: .gardening).xp, plumTree.xp)
        XCTAssertEqual(store.plantings().count, 1)
    }

    func testCropGivesSmallPlantXPThenHarvestYield() throws {
        store.plant(radishP, at: 0, now: noon)
        let planting = try XCTUnwrap(store.plantings().first)
        XCTAssertEqual(store.progress(for: .gardening).xp, 15, "crop planting is a small tick, not the yield")

        XCTAssertNil(store.harvest(planting, now: noon), "an unripe crop yields nothing")
        XCTAssertEqual(store.progress(for: .gardening).xp, 15)

        let ripe = noon.addingTimeInterval(radishP.daysToMature * 86_400)
        let reward = store.harvest(planting, now: ripe)
        XCTAssertEqual(reward?.xpAwarded, radishP.xp)
        XCTAssertEqual(store.progress(for: .gardening).xp, 15 + radishP.xp)
        XCTAssertTrue(store.plantings().isEmpty, "harvest clears the bed")
        XCTAssertEqual(store.count(of: "radish"), 1, "the harvest becomes an ingredient")
    }

    func testWateringGivesXPAtMostOncePerDay() throws {
        store.plant(radishP, at: 0, now: noon)
        let planting = try XCTUnwrap(store.plantings().first)
        let base = store.progress(for: .gardening).xp

        XCTAssertNotNil(store.water(planting, now: noon))
        XCTAssertEqual(store.progress(for: .gardening).xp, base + 10)

        XCTAssertNil(store.water(planting, now: noon), "already watered today")
        XCTAssertEqual(store.progress(for: .gardening).xp, base + 10)

        let tomorrow = noon.addingTimeInterval(24 * 3_600)
        XCTAssertNotNil(store.water(planting, now: tomorrow))
        XCTAssertEqual(store.progress(for: .gardening).xp, base + 20)
    }

    func testGardeningXPIsIndependentOfFishingAndForaging() {
        store.plant(plumTree, at: 0, now: noon)
        XCTAssertEqual(store.progress(for: .fishing).xp, 0)
        XCTAssertEqual(store.progress(for: .foraging).xp, 0)
    }

    private var kitchen: Room { Hermitage.room(id: "kitchen")! }  // cost: repair-kit 1

    func testRestoringARoomSpendsGoodsAndUnlocksIt() {
        store.add("repair-kit", count: 1)
        XCTAssertFalse(store.isRestored("kitchen"))
        XCTAssertTrue(store.restore(kitchen))
        XCTAssertTrue(store.isRestored("kitchen"))
        XCTAssertEqual(store.count(of: "repair-kit"), 0, "restoration spent the kit")
        XCTAssertTrue(store.restoredRooms().contains("kitchen"))
    }

    func testRestoringFailsWithoutTheGoods() {
        XCTAssertFalse(store.restore(kitchen))  // no repair kit on hand
        XCTAssertFalse(store.isRestored("kitchen"))
    }

    func testARoomIsNotRestoredTwice() {
        store.add("repair-kit", count: 2)
        XCTAssertTrue(store.restore(kitchen))
        XCTAssertFalse(store.restore(kitchen), "already restored — no second spend")
        XCTAssertEqual(store.count(of: "repair-kit"), 1)
    }

    func testCraftingARodConsumesMaterialsAndSetsTheTier() {
        let bamboo = CraftingTable.all.first { $0.id == "bamboo-rod" }!  // shepherds-purse 3 → rodTier 2
        store.add("shepherds-purse", count: 3)
        let reward = store.craft(bamboo)
        XCTAssertEqual(reward?.xpAwarded, bamboo.xp)
        XCTAssertEqual(store.progress(for: .crafting).xp, bamboo.xp)
        XCTAssertEqual(store.count(of: "shepherds-purse"), 0)
        XCTAssertEqual(store.rodTier(), 2)
    }

    func testCraftingAGoodStocksIt() {
        let kit = CraftingTable.all.first { $0.id == "repair-kit" }!  // oyster 1 + mugwort 3
        store.add("oyster-mushroom", count: 1)
        store.add("mugwort", count: 3)
        _ = store.craft(kit)
        XCTAssertEqual(store.count(of: "repair-kit"), 1)
    }

    func testABetterRodNeverDowngrades() {
        let keeper = CraftingTable.all.first { $0.id == "keepers-rod" }!  // rodTier 3
        let mend = CraftingTable.all.first { $0.id == "mend-rod" }!       // rodTier 1
        store.add("pine-nuts", count: 2)
        _ = store.craft(keeper)
        XCTAssertEqual(store.rodTier(), 3)
        store.add("mugwort", count: 2)
        _ = store.craft(mend)  // crafting a lesser rod
        XCTAssertEqual(store.rodTier(), 3, "the best rod owned stays the best")
    }

    func testCraftFailsWhenMaterialsAreShort() {
        let bamboo = CraftingTable.all.first { $0.id == "bamboo-rod" }!
        store.add("shepherds-purse", count: 1)  // needs 3
        XCTAssertNil(store.craft(bamboo))
        XCTAssertEqual(store.progress(for: .crafting).xp, 0)
        XCTAssertEqual(store.count(of: "shepherds-purse"), 1)
    }

    func testCatchAndGatherStockTheInventory() {
        _ = store.record(catch: crucian, weather: .clear)
        _ = store.record(catch: crucian, weather: .clear)
        _ = store.record(gather: mugwort, weather: .clear)
        XCTAssertEqual(store.count(of: "crucian-carp"), 2)
        XCTAssertEqual(store.count(of: "mugwort"), 1)
    }

    func testAddAndConsumeStock() {
        store.add("bamboo", count: 3)
        XCTAssertEqual(store.count(of: "bamboo"), 3)
        XCTAssertTrue(store.consume("bamboo", count: 2))
        XCTAssertEqual(store.count(of: "bamboo"), 1)
        XCTAssertFalse(store.consume("bamboo", count: 2), "a shortfall changes nothing")
        XCTAssertEqual(store.count(of: "bamboo"), 1)
    }

    func testConsumeIngredientListIsAtomic() {
        store.add("catfish", count: 1)
        store.add("mugwort", count: 2)
        XCTAssertTrue(store.has([Ingredient("catfish", 1), Ingredient("mugwort", 2)]))

        // A list that can't be fully satisfied consumes nothing.
        XCTAssertFalse(store.consume([Ingredient("catfish", 1), Ingredient("mugwort", 3)]))
        XCTAssertEqual(store.count(of: "catfish"), 1, "atomic: catfish untouched on failure")
        XCTAssertEqual(store.count(of: "mugwort"), 2)

        XCTAssertTrue(store.consume([Ingredient("catfish", 1), Ingredient("mugwort", 2)]))
        XCTAssertEqual(store.count(of: "catfish"), 0)
        XCTAssertEqual(store.count(of: "mugwort"), 0)
    }

    private var stew: Dish { CookingTable.all.first { $0.id == "spicy-fish-stew" }! }  // catfish+mugwort, biteRate 30m

    func testCookConsumesIngredientsAndAwardsCookingXP() {
        store.add("catfish", count: 1)
        store.add("mugwort", count: 1)

        let reward = store.cook(stew, now: noon)
        XCTAssertEqual(reward?.xpAwarded, stew.xp)
        XCTAssertEqual(store.progress(for: .cooking).xp, stew.xp)
        XCTAssertEqual(store.count(of: "catfish"), 0, "cooking ate the ingredients")
        XCTAssertEqual(store.count(of: "mugwort"), 0)
    }

    func testCookFailsWhenThePantryIsShort() {
        store.add("catfish", count: 1)   // missing the mugwort
        XCTAssertNil(store.cook(stew, now: noon))
        XCTAssertEqual(store.progress(for: .cooking).xp, 0)
        XCTAssertEqual(store.count(of: "catfish"), 1, "a failed cook consumes nothing")
    }

    func testCookingABuffDishStartsAndLapsesTheBuff() {
        store.add("catfish", count: 1)
        store.add("mugwort", count: 1)
        XCTAssertFalse(store.isActive(.biteRate, now: noon))

        _ = store.cook(stew, now: noon)  // biteRate for 30 minutes
        XCTAssertTrue(store.isActive(.biteRate, now: noon.addingTimeInterval(29 * 60)))
        XCTAssertFalse(
            store.isActive(.biteRate, now: noon.addingTimeInterval(31 * 60)),
            "the buff lapses with real time")
    }

    func testProgressRowIsCreatedOnce() throws {
        _ = store.progress(for: .fishing)
        _ = store.progress(for: .fishing)
        let rows = try store.context.fetch(FetchDescriptor<SkillProgress>())
        XCTAssertEqual(rows.count, 1)
    }
}
