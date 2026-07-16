import XCTest
@testable import SkyState

final class SkyStoreTests: XCTestCase {
    private let seoul = TimeZone(identifier: "Asia/Seoul")!

    private var fetched: WorldConditions {
        WorldConditions(weather: .rain, precipitation: 3.2, windSpeed: 4.1, timeOfDay: .day, season: .summer)
    }
    private var cached: WorldConditions {
        WorldConditions(weather: .cloudy, precipitation: 0, windSpeed: 2.0, timeOfDay: .dusk, season: .summer)
    }

    // MARK: Fallback ladder — never blank, never an error

    func testFallbackPrefersFetchedOverCached() {
        let resolved = SkyStore.resolve(fetched: fetched, cached: cached, now: .now, timeZone: seoul)
        XCTAssertEqual(resolved, fetched)
    }

    func testFallbackUsesCacheWhenFetchMissing() {
        let resolved = SkyStore.resolve(fetched: nil, cached: cached, now: .now, timeZone: seoul)
        XCTAssertEqual(resolved, cached)
    }

    func testColdStartFallsBackToClearDefault() {
        // 2026-01-15 03:00 in Seoul: winter, night.
        var components = DateComponents()
        (components.year, components.month, components.day, components.hour) = (2026, 1, 15, 3)
        components.timeZone = seoul
        let date = Calendar(identifier: .gregorian).date(from: components)!

        let resolved = SkyStore.resolve(fetched: nil, cached: nil, now: date, timeZone: seoul)

        XCTAssertEqual(resolved.weather, .clear)
        XCTAssertEqual(resolved.precipitation, 0)
        XCTAssertEqual(resolved.timeOfDay, .night)
        XCTAssertEqual(resolved.season, .winter)
    }

    // MARK: Cache persistence

    func testCacheRoundTripsAcrossInstances() throws {
        let suite = "meok-sky-tests"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        SkyCache(defaults: defaults).save(fetched)
        let reloaded = SkyCache(defaults: defaults).load()

        XCTAssertEqual(reloaded, fetched)
        defaults.removePersistentDomain(forName: suite)
    }

    func testCacheLoadIsNilWhenEmpty() throws {
        let suite = "meok-sky-tests-empty"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        XCTAssertNil(SkyCache(defaults: defaults).load())
    }
}
