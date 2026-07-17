import XCTest
@testable import SkyState

final class OpenMeteoTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(
            forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    /// 2026-07-16 15:45 KST — the moment the fixtures were recorded.
    private var fixtureInstant: Date {
        var components = DateComponents()
        (components.year, components.month, components.day) = (2026, 7, 16)
        (components.hour, components.minute) = (15, 45)
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    func testDecodesClearSeoulFixture() throws {
        let conditions = try OpenMeteo.conditions(
            fromJSON: fixture("open-meteo-seoul-clear"), now: fixtureInstant)

        XCTAssertEqual(conditions.weather, .clear)
        XCTAssertEqual(conditions.precipitation, 0.0)
        XCTAssertEqual(conditions.windSpeed, 1.32)
        // Derived from `now` in the response's own utc_offset (Seoul, +9):
        // 15:45 in July → day, summer.
        XCTAssertEqual(conditions.timeOfDay, .day)
        XCTAssertEqual(conditions.season, .summer)
    }

    func testTimeOfDayFollowsResponseCoordinatesNotDeviceZone() throws {
        // 2026-01-15T20:00Z is 05:00 on Jan 16 in Seoul. Seoul's winter
        // sunrise is ~07:47, so the real sun says deep pre-dawn NIGHT —
        // where the old fixed-hour buckets would have said dawn. Season
        // still derives from the response's own UTC offset (winter).
        var components = DateComponents()
        (components.year, components.month, components.day, components.hour) = (2026, 1, 15, 20)
        components.timeZone = TimeZone(identifier: "UTC")
        let instant = Calendar(identifier: .gregorian).date(from: components)!

        let conditions = try OpenMeteo.conditions(
            fromJSON: fixture("open-meteo-seoul-clear"), now: instant)

        XCTAssertEqual(conditions.timeOfDay, .night)
        XCTAssertGreaterThan(conditions.darkness, 0.95)
        XCTAssertEqual(conditions.season, .winter)
    }

    func testDecodesRainSeoulFixture() throws {
        let conditions = try OpenMeteo.conditions(
            fromJSON: fixture("open-meteo-seoul-rain"), now: fixtureInstant)

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

        let seoulLat = 37.5665
        XCTAssertEqual(OpenMeteo.season(month: 12, latitude: seoulLat), .winter)
        XCTAssertEqual(OpenMeteo.season(month: 2, latitude: seoulLat), .winter)
        XCTAssertEqual(OpenMeteo.season(month: 3, latitude: seoulLat), .spring)
        XCTAssertEqual(OpenMeteo.season(month: 6, latitude: seoulLat), .summer)
        XCTAssertEqual(OpenMeteo.season(month: 9, latitude: seoulLat), .autumn)
        XCTAssertEqual(OpenMeteo.season(month: 11, latitude: seoulLat), .autumn)
    }
}
