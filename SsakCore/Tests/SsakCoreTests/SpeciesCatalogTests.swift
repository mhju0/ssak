import XCTest
@testable import SsakCore

final class SpeciesCatalogTests: XCTestCase {
    func testAllSixPresentInPacingOrder() {
        let ids = SpeciesCatalog.all.map(\.id)
        XCTAssertEqual(ids, ["marigold", "nasturtium", "cosmos", "zinnia", "sunflower", "morning_glory"])
    }
    func testStarterIsMarigoldAndFastest() {
        XCTAssertEqual(SpeciesCatalog.starter.id, "marigold")
        XCTAssertEqual(SpeciesCatalog.all.min(by: { $0.bloomDays < $1.bloomDays })?.id, "marigold")
    }
    func testLookup() {
        XCTAssertEqual(SpeciesCatalog.species(id: "cosmos")?.nameKO, "코스모스")
        XCTAssertNil(SpeciesCatalog.species(id: "rose"))
    }
}
