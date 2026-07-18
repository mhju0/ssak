import XCTest
@testable import GameKernel

final class SweepingTests: XCTestCase {
    private func sky(
        _ season: WorldConditions.Season,
        _ weather: WorldConditions.Weather,
        wind: Double = 0
    ) -> WorldConditions {
        WorldConditions(
            weather: weather, precipitation: 0, windSpeed: wind,
            timeOfDay: .day, season: season)
    }

    func testSnowfallDriftsSnow() {
        XCTAssertEqual(Sweeping.litter(for: sky(.winter, .snow)), .snow)
    }

    func testAutumnGathersLeaves() {
        XCTAssertEqual(Sweeping.litter(for: sky(.autumn, .clear)), .leaves)
    }

    func testWindGathersLeavesInAnySeason() {
        XCTAssertEqual(Sweeping.litter(for: sky(.summer, .clear, wind: 6)), .leaves)
        XCTAssertNil(Sweeping.litter(for: sky(.summer, .clear, wind: 2)))
    }

    func testCalmClearSummerPathStaysClean() {
        XCTAssertNil(Sweeping.litter(for: sky(.summer, .clear)))
    }

    func testSnowWinsOverLeaves() {
        // A snowy autumn gale drifts snow, not leaves — snow is the stronger cue.
        XCTAssertEqual(Sweeping.litter(for: sky(.autumn, .snow, wind: 9)), .snow)
    }
}
