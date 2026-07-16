import XCTest
@testable import SkyState

final class RainIntensityTests: XCTestCase {
    private func conditions(_ weather: WorldConditions.Weather, mm: Double) -> WorldConditions {
        WorldConditions(weather: weather, precipitation: mm, windSpeed: 0, timeOfDay: .day, season: .summer)
    }

    func testDryIsZero() {
        XCTAssertEqual(conditions(.clear, mm: 0).rainIntensity, 0)
    }

    func testDrizzleBarelyWeeps() {
        let drizzle = conditions(.rain, mm: 0.2).rainIntensity
        XCTAssertGreaterThan(drizzle, 0.05)
        XCTAssertLessThan(drizzle, 0.25)
    }

    func testDownpourSaturatesAtOne() {
        XCTAssertEqual(conditions(.rain, mm: 8).rainIntensity, 1)
        XCTAssertEqual(conditions(.storm, mm: 14).rainIntensity, 1)
    }

    func testContinuousAndMonotonic() {
        let light = conditions(.rain, mm: 0.5).rainIntensity
        let moderate = conditions(.rain, mm: 2).rainIntensity
        let heavy = conditions(.rain, mm: 6).rainIntensity
        XCTAssertLessThan(light, moderate)
        XCTAssertLessThan(moderate, heavy)
    }

    func testSnowDoesNotBleed() {
        // Snow reserves paper white (spec §3); it never runs the ink.
        XCTAssertEqual(conditions(.snow, mm: 3).rainIntensity, 0)
    }
}
