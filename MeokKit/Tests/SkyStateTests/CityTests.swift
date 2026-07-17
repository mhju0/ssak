import XCTest
@testable import SkyState

final class CityTests: XCTestCase {
    func testSeoulIsTheDefaultPreset() {
        XCTAssertEqual(City.presets.first, .seoul)
        XCTAssertEqual(City.seoul.latitude, 37.5665, accuracy: 0.001)
    }

    func testPresetsSpanClimatesAndAreValid() {
        XCTAssertGreaterThanOrEqual(City.presets.count, 8)
        for city in City.presets {
            XCTAssert((-90 ... 90).contains(city.latitude), city.name)
            XCTAssert((-180 ... 180).contains(city.longitude), city.name)
        }
        // At least one southern-hemisphere city (season honesty matters).
        XCTAssert(City.presets.contains { $0.latitude < 0 })
    }

    func testFetchURLCarriesTheCityCoordinates() throws {
        let sydney = try XCTUnwrap(City.presets.first { $0.latitude < 0 })
        let url = SkyStore.url(for: sydney).absoluteString
        XCTAssert(url.contains("latitude=\(sydney.latitude)"), url)
        XCTAssert(url.contains("longitude=\(sydney.longitude)"), url)
        XCTAssert(url.contains("wind_speed_unit=ms"))
    }

    func testCityPersistsAcrossStoreInstances() throws {
        let suite = "meok-city-tests"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = SkyStore(defaults: defaults)
        XCTAssertEqual(store.city, .seoul)   // default

        let tokyo = City.presets.first { $0.name == "Tokyo" }!
        store.city = tokyo
        XCTAssertEqual(SkyStore(defaults: defaults).city, tokyo)
        defaults.removePersistentDomain(forName: suite)
    }

    func testSwitchingCityInvalidatesTheWeatherCache() throws {
        // Pillar 1: never faked. Seoul's cached rain must not render under
        // Sydney's sky — a city switch clears the cache, and the ladder
        // falls to the clear default for the new city.
        let suite = "meok-city-cache-tests"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = SkyStore(defaults: defaults)
        SkyCache(defaults: defaults).save(WorldConditions(
            weather: .rain, precipitation: 5, windSpeed: 3, timeOfDay: .day, season: .summer))
        XCTAssertEqual(store.current().weather, .rain)   // cache in effect

        store.city = City.presets.first { $0.name == "Sydney" }!
        XCTAssertEqual(store.current().weather, .clear)  // cache cleared
        defaults.removePersistentDomain(forName: suite)
    }

    func testSouthernHemisphereSeasonIsFlipped() {
        // July: Seoul is summer, Sydney is winter. January: the reverse.
        XCTAssertEqual(OpenMeteo.season(month: 7, latitude: 37.6), .summer)
        XCTAssertEqual(OpenMeteo.season(month: 7, latitude: -33.9), .winter)
        XCTAssertEqual(OpenMeteo.season(month: 1, latitude: -33.9), .summer)
        XCTAssertEqual(OpenMeteo.season(month: 10, latitude: -33.9), .spring)
    }
}
