import XCTest
@testable import GameKernel

final class CraftingTests: XCTestCase {
    func testTableMatchesTheDraftedDesign() {
        let table = CraftingTable.all
        XCTAssertEqual(table.count, 10)
        XCTAssertEqual(Set(table.map(\.id)).count, 10, "craftable ids must be unique")
        for craftable in table {
            XCTAssertTrue((1...99).contains(craftable.unlockLevel), craftable.id)
            XCTAssertGreaterThan(craftable.xp, 0, craftable.id)
            XCTAssertFalse(craftable.materials.isEmpty, craftable.id)
            XCTAssertFalse(craftable.nameKO.isEmpty, craftable.id)
            for material in craftable.materials {
                XCTAssertGreaterThan(material.count, 0, craftable.id)
            }
        }
    }

    func testMaterialsReferenceRealCollectibles() {
        let known = Set(
            FishingTable.all.map(\.id)
                + ForagingTable.all.map(\.id)
                + GardenTable.all.map(\.id))
        for craftable in CraftingTable.all {
            for material in craftable.materials {
                XCTAssertTrue(
                    known.contains(material.item),
                    "\(craftable.id) wants unknown material \(material.item)")
            }
        }
    }

    func testLevelGatesCraftables() {
        XCTAssertFalse(Crafting.available(level: 9).contains { $0.id == "bamboo-rod" })
        XCTAssertTrue(Crafting.available(level: 10).contains { $0.id == "bamboo-rod" })
    }

    func testRodTiersAscend() {
        func tier(_ id: String) -> Int {
            if case .rodTier(let tier) = Crafting.craftable(id: id)!.effect { return tier }
            return 0
        }
        XCTAssertLessThan(tier("mend-rod"), tier("bamboo-rod"))
        XCTAssertLessThan(tier("bamboo-rod"), tier("keepers-rod"))
        XCTAssertLessThan(tier("keepers-rod"), tier("masters-rod"))
    }
}
