import XCTest
@testable import SsakCore

final class PersistenceTests: XCTestCase {
    func testSaveLoadRoundTrip() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ssak-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tmp) }

        let store = PlantStore(url: tmp)
        let state = GameState(plant: GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0)),
                              collected: ["cosmos", "zinnia"])
        try store.save(state)

        XCTAssertEqual(store.load(), state)
    }

    func testLoadMissingFileReturnsNil() {
        let store = PlantStore(url: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).json"))
        XCTAssertNil(store.load())
    }
}
