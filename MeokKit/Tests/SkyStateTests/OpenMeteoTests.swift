import XCTest
@testable import SkyState

final class OpenMeteoTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(
            forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    func testDecodesClearSeoulFixture() throws {
        let conditions = try OpenMeteo.conditions(fromJSON: fixture("open-meteo-seoul-clear"))

        XCTAssertEqual(conditions.weather, .clear)
        XCTAssertEqual(conditions.precipitation, 0.0)
        XCTAssertEqual(conditions.windSpeed, 1.32)
        // Fixture timestamp: 2026-07-16T15:45 in Asia/Seoul.
        XCTAssertEqual(conditions.timeOfDay, .day)
        XCTAssertEqual(conditions.season, .summer)
    }

    func testDecodesRainSeoulFixture() throws {
        let conditions = try OpenMeteo.conditions(fromJSON: fixture("open-meteo-seoul-rain"))

        XCTAssertEqual(conditions.weather, .rain)
        XCTAssertEqual(conditions.precipitation, 3.2)
        XCTAssertEqual(conditions.windSpeed, 4.1)
    }

    func testWMOCodeMapping() {
        // Expected kinds from the WMO weather-code table (Open-Meteo docs).
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 0), .clear)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 1), .clear)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 2), .cloudy)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 3), .cloudy)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 45), .fog)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 48), .fog)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 51), .rain)   // drizzle
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 63), .rain)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 67), .rain)   // freezing rain
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 82), .rain)   // violent showers
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 71), .snow)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 77), .snow)   // snow grains
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 86), .snow)   // snow showers
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 95), .storm)
        XCTAssertEqual(OpenMeteo.weather(fromWMOCode: 99), .storm)
    }

    func testTimeOfDayAndSeasonBoundaries() {
        XCTAssertEqual(OpenMeteo.timeOfDay(hour: 4), .night)
        XCTAssertEqual(OpenMeteo.timeOfDay(hour: 5), .dawn)
        XCTAssertEqual(OpenMeteo.timeOfDay(hour: 8), .day)
        XCTAssertEqual(OpenMeteo.timeOfDay(hour: 17), .dusk)
        XCTAssertEqual(OpenMeteo.timeOfDay(hour: 20), .night)
        XCTAssertEqual(OpenMeteo.timeOfDay(hour: 0), .night)

        XCTAssertEqual(OpenMeteo.season(month: 12), .winter)
        XCTAssertEqual(OpenMeteo.season(month: 2), .winter)
        XCTAssertEqual(OpenMeteo.season(month: 3), .spring)
        XCTAssertEqual(OpenMeteo.season(month: 6), .summer)
        XCTAssertEqual(OpenMeteo.season(month: 9), .autumn)
        XCTAssertEqual(OpenMeteo.season(month: 11), .autumn)
    }
}
