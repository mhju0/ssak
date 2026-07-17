import XCTest
import GameKernel
@testable import SkyState

final class SolarTests: XCTestCase {
    private let seoulLat = 37.5665
    private let seoulLon = 126.978

    private func seoulDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        (components.year, components.month, components.day) = (year, month, day)
        (components.hour, components.minute) = (hour, minute)
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private func elevation(_ date: Date) -> Double {
        Solar.elevation(date: date, latitude: seoulLat, longitude: seoulLon)
    }

    // MARK: Elevation against known astronomy

    func testSummerSolsticeNoonElevation() {
        // Solar noon in Seoul ≈ 12:33 KST; solstice max ≈ 90 − (37.57 − 23.44).
        let el = elevation(seoulDate(2026, 6, 21, 12, 33))
        XCTAssertEqual(el, 75.9, accuracy: 1.5)
    }

    func testWinterSolsticeNoonElevation() {
        // ≈ 90 − 37.57 − 23.44.
        let el = elevation(seoulDate(2026, 12, 21, 12, 33))
        XCTAssertEqual(el, 29.0, accuracy: 1.5)
    }

    func testSummerMidnightIsDeepBelowHorizon() {
        XCTAssertLessThan(elevation(seoulDate(2026, 6, 21, 0, 0)), -20)
    }

    func testEquinoxSunriseNearSixThirtyFive() {
        // Seoul equinox *apparent* sunrise ≈ 06:35 KST; geometric center
        // elevation there ≈ −0.8° (refraction + semidiameter). The sun moves
        // ~0.2°/min at the horizon, so ±2° keeps this minutes-level.
        let el = elevation(seoulDate(2026, 3, 20, 6, 35))
        XCTAssertEqual(el, -0.8, accuracy: 2)
    }

    // MARK: Darkness curve

    func testDarknessBoundsAndContinuity() {
        // Full day at high sun, full night deep below the horizon.
        XCTAssertEqual(Solar.darkness(date: seoulDate(2026, 6, 21, 12, 33),
                                      latitude: seoulLat, longitude: seoulLon), 0)
        XCTAssertEqual(Solar.darkness(date: seoulDate(2026, 6, 21, 0, 0),
                                      latitude: seoulLat, longitude: seoulLon), 1)
        // Twilight sits strictly between — the curve is continuous, not a step.
        let dusk = Solar.darkness(date: seoulDate(2026, 7, 17, 20, 5),
                                  latitude: seoulLat, longitude: seoulLon)
        XCTAssertGreaterThan(dusk, 0.05)
        XCTAssertLessThan(dusk, 0.95)
    }

    func testDarknessMonotonicThroughEvening() {
        let hours: [(Int, Int)] = [(17, 0), (19, 0), (20, 0), (20, 40), (22, 0)]
        let values = hours.map {
            Solar.darkness(date: seoulDate(2026, 7, 17, $0.0, $0.1),
                           latitude: seoulLat, longitude: seoulLon)
        }
        for pair in zip(values, values.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0, pair.1 + 0.001)
        }
    }

    // MARK: Time of day from the real sun

    func testTimeOfDayFollowsTheRealSun() {
        // 2026-07-17 Seoul: sunrise ≈ 05:26, sunset ≈ 19:52 KST.
        func timeOfDay(_ hour: Int, _ minute: Int) -> WorldConditions.TimeOfDay {
            Solar.timeOfDay(date: seoulDate(2026, 7, 17, hour, minute),
                            latitude: seoulLat, longitude: seoulLon)
        }
        XCTAssertEqual(timeOfDay(12, 0), .day)
        XCTAssertEqual(timeOfDay(23, 0), .night)
        XCTAssertEqual(timeOfDay(5, 20), .dawn)   // just before sunrise, sun rising
        XCTAssertEqual(timeOfDay(20, 10), .dusk)  // just after sunset, sun falling
        // Winter 05:00 is deep pre-dawn — NOT dawn (the fixed-hour buckets
        // this replaces would have said dawn).
        XCTAssertEqual(
            Solar.timeOfDay(date: seoulDate(2026, 1, 16, 5, 0),
                            latitude: seoulLat, longitude: seoulLon),
            .night)
    }
}
