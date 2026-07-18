import XCTest
@testable import GameKernel

final class HermitageTests: XCTestCase {
    func testFourRoomsWithCraftableCosts() {
        XCTAssertEqual(Hermitage.rooms.count, 4)
        XCTAssertEqual(Set(Hermitage.rooms.map(\.id)).count, 4, "room ids must be unique")

        // Restoration consumes crafting: every cost must be a craftable good.
        let goods = Set(CraftingTable.all.compactMap { craftable -> String? in
            if case .good(let id) = craftable.effect { return id }
            return nil
        })
        for room in Hermitage.rooms {
            XCTAssertFalse(room.cost.isEmpty, room.id)
            XCTAssertFalse(room.nameKO.isEmpty, room.id)
            for cost in room.cost {
                XCTAssertTrue(goods.contains(cost.item), "\(room.id) needs uncraftable \(cost.item)")
            }
        }
    }

    func testEveryFunctionHasExactlyOneRoom() {
        XCTAssertEqual(Set(Hermitage.rooms.map(\.unlocks)).count, 4)
    }
}
