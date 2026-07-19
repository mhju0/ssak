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

    // A file that exists but holds garbage/incompatible JSON (interrupted write, schema
    // change) must load as nil — a graceful reset, never a crash. Exercises the decode-
    // failure branch of load(), which the round-trip and missing-file tests never reach.
    func testLoadCorruptFileReturnsNil() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ssak-corrupt-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tmp) }
        try Data("{ not valid json".utf8).write(to: tmp)

        let store = PlantStore(url: tmp)
        XCTAssertNil(store.load())
    }
}
