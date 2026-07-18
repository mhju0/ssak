import XCTest
@testable import GameKernel

final class CookingTests: XCTestCase {
    func testTableMatchesTheDraftedDesign() {
        let table = CookingTable.all
        XCTAssertEqual(table.count, 9)
        XCTAssertEqual(Set(table.map(\.id)).count, 9, "dish ids must be unique")
        for dish in table {
            XCTAssertTrue((1...99).contains(dish.unlockLevel), dish.id)
            XCTAssertGreaterThan(dish.xp, 0, dish.id)
            XCTAssertFalse(dish.ingredients.isEmpty, dish.id)
            XCTAssertFalse(dish.nameKO.isEmpty, dish.id)
            for ingredient in dish.ingredients {
                XCTAssertGreaterThan(ingredient.count, 0, dish.id)
            }
            if dish.buff != nil {
                XCTAssertGreaterThan(dish.buffMinutes, 0, "\(dish.id) buff needs a duration")
            }
        }
    }

    func testIngredientsReferenceRealCollectibles() {
        // A dish can only ask for something the player can actually obtain —
        // every ingredient id must be a known fish, forageable, or plantable.
        let known = Set(
            FishingTable.all.map(\.id)
                + ForagingTable.all.map(\.id)
                + GardenTable.all.map(\.id))
        for dish in CookingTable.all {
            for ingredient in dish.ingredients {
                XCTAssertTrue(
                    known.contains(ingredient.item),
                    "\(dish.id) wants unknown ingredient \(ingredient.item)")
            }
        }
    }

    func testLevelGatesDishes() {
        XCTAssertFalse(Cooking.available(level: 19).contains { $0.id == "spicy-fish-stew" })
        XCTAssertTrue(Cooking.available(level: 20).contains { $0.id == "spicy-fish-stew" })
    }

    func testBuffDishesCarryTheBiteRateBuff() {
        XCTAssertEqual(Cooking.dish(id: "spicy-fish-stew")?.buff, .biteRate)
        XCTAssertNil(Cooking.dish(id: "herb-rice")?.buff, "a plain dish grants no buff")
    }
}
