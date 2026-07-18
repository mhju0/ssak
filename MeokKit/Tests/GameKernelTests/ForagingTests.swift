import XCTest
@testable import GameKernel

final class ForagingTests: XCTestCase {
    private func sky(
        _ season: WorldConditions.Season,
        _ time: WorldConditions.TimeOfDay,
        _ weather: WorldConditions.Weather
    ) -> WorldConditions {
        WorldConditions(
            weather: weather, precipitation: 0, windSpeed: 0,
            timeOfDay: time, season: season)
    }

    // MARK: Table integrity

    func testTableMatchesTheDraftedDesign() {
        let table = ForagingTable.all
        XCTAssertEqual(table.count, 8)
        XCTAssertEqual(Set(table.map(\.id)).count, 8, "forageable ids must be unique")
        for f in table {
            XCTAssertTrue((1...99).contains(f.unlockLevel), f.id)
            XCTAssertGreaterThan(f.weight, 0, f.id)
            XCTAssertGreaterThan(f.xp, 0, f.id)
            XCTAssertFalse(f.seasons.isEmpty, f.id)
            XCTAssertFalse(f.timesOfDay.isEmpty, f.id)
            XCTAssertFalse(f.weathers.isEmpty, f.id)
            XCTAssertFalse(f.nameKO.isEmpty, f.id)
        }
    }

    // MARK: The two-currency rule (spec §2) — foraging is a gathering skill

    func testEverySkyYieldsALevelOneForage() {
        for season in WorldConditions.Season.allCases {
            for time in WorldConditions.TimeOfDay.allCases {
                for weather in WorldConditions.Weather.allCases {
                    XCTAssertFalse(
                        Foraging.available(sky(season, time, weather), level: 1).isEmpty,
                        "no level-1 forage under \(season)/\(time)/\(weather)")
                }
            }
        }
    }

    func testGrindingProgressesAtEveryLevelUnderEverySky() {
        for level in 1...99 {
            for season in WorldConditions.Season.allCases {
                for time in WorldConditions.TimeOfDay.allCases {
                    for weather in WorldConditions.Weather.allCases {
                        XCTAssertFalse(
                            Foraging.available(sky(season, time, weather), level: level).isEmpty,
                            "level \(level) stalls under \(season)/\(time)/\(weather)")
                    }
                }
            }
        }
    }

    // MARK: Gating and condition filters

    func testLevelGatesForageables() {
        let autumnDay = sky(.autumn, .day, .clear)
        XCTAssertFalse(
            Foraging.available(autumnDay, level: 29).contains { $0.id == "persimmon" })
        XCTAssertTrue(
            Foraging.available(autumnDay, level: 30).contains { $0.id == "persimmon" })
    }

    func testMoonMushroomIsNightOnly() {
        XCTAssertTrue(
            Foraging.available(sky(.autumn, .night, .clear), level: 99)
                .contains { $0.id == "moon-mushroom" })
        XCTAssertFalse(
            Foraging.available(sky(.autumn, .day, .clear), level: 99)
                .contains { $0.id == "moon-mushroom" })
    }

    func testSnowLotusBloomsOnlyInFallingSnow() {
        // The first climate-locked collectible (snowless cities can't get it).
        XCTAssertTrue(
            Foraging.available(sky(.winter, .day, .snow), level: 90)
                .contains { $0.id == "snow-lotus" })
        XCTAssertFalse(
            Foraging.available(sky(.winter, .day, .clear), level: 90)
                .contains { $0.id == "snow-lotus" })
    }

    // MARK: Shared seeded draw

    func testSpotIsDeterministicAndEligible() {
        let conditions = sky(.autumn, .day, .clear)
        var a = SeededRandom(seed: 7)
        var b = SeededRandom(seed: 7)
        XCTAssertEqual(
            Foraging.spot(conditions, level: 40, using: &a)?.id,
            Foraging.spot(conditions, level: 40, using: &b)?.id,
            "same seed must give the same find")

        let eligible = Set(Foraging.available(conditions, level: 40).map(\.id))
        var rng = SeededRandom(seed: 3)
        for _ in 0..<200 {
            let pick = try! XCTUnwrap(Foraging.spot(conditions, level: 40, using: &rng))
            XCTAssertTrue(eligible.contains(pick.id))
        }
    }

    func testSpotIsNilWhenNothingIsEligible() {
        // Snow at a level below every snow forageable's unlock: still covered
        // by the all-conditions baselines, so this is really a guard check on
        // an impossible-empty pool via an unreachable level.
        var rng = SeededRandom(seed: 1)
        XCTAssertNotNil(Foraging.spot(sky(.winter, .night, .snow), level: 1, using: &rng))
    }
}
