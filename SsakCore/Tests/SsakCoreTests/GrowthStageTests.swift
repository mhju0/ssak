import XCTest
@testable import SsakCore

final class GrowthStageTests: XCTestCase {
    func testStageThresholds() {
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.0), .seed)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.14), .seed)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.15), .sprout)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.50), .leaves)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.75), .bud)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 1.0), .bloom)
    }
    func testPreviousStage() {
        XCTAssertEqual(GrowthStage.bloom.previous, .bud)
        XCTAssertEqual(GrowthStage.sprout.previous, .seed)
        XCTAssertNil(GrowthStage.seed.previous)
    }
    func testProgressAtStartOf() {
        XCTAssertEqual(GrowthEngine.progressAtStartOf(.leaves), 0.40, accuracy: 0.0001)
        XCTAssertEqual(GrowthEngine.progressAtStartOf(.seed), 0.0, accuracy: 0.0001)
    }
}
