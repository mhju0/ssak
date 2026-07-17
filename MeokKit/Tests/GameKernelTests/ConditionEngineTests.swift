import XCTest
@testable import GameKernel

final class ConditionEngineTests: XCTestCase {
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
        let table = FishingTable.all
        XCTAssertEqual(table.count, 11)
        XCTAssertEqual(Set(table.map(\.id)).count, 11, "species ids must be unique")
        for species in table {
            XCTAssertTrue((1...99).contains(species.unlockLevel), species.id)
            XCTAssertGreaterThan(species.weight, 0, species.id)
            XCTAssertGreaterThan(species.xp, 0, species.id)
            XCTAssertFalse(species.seasons.isEmpty, species.id)
            XCTAssertFalse(species.timesOfDay.isEmpty, species.id)
            XCTAssertFalse(species.weathers.isEmpty, species.id)
            XCTAssertFalse(species.nameKO.isEmpty, species.id)
        }
    }

    func testBitePatternsAreWellFormed() {
        for species in FishingTable.all {
            let taps = species.bitePattern
            XCTAssertFalse(taps.isEmpty, species.id)
            XCTAssertEqual(taps.map(\.offset), taps.map(\.offset).sorted(), species.id)
            for tap in taps {
                XCTAssertTrue((0...1).contains(tap.intensity), species.id)
                XCTAssertTrue((0...1).contains(tap.sharpness), species.id)
                XCTAssertGreaterThan(tap.duration, 0, species.id)
            }
        }
    }

    // MARK: The two-currency rule (spec §2, kernel-tested)

    func testEverySkyYieldsALevelOneCatch() {
        // "Any day, any sky, grinding always progresses" — all 96
        // (season × time × weather) combinations must offer a level-1 fish.
        for season in WorldConditions.Season.allCases {
            for time in WorldConditions.TimeOfDay.allCases {
                for weather in WorldConditions.Weather.allCases {
                    let eligible = ConditionEngine.eligibleSpecies(
                        sky(season, time, weather), level: 1)
                    XCTAssertFalse(
                        eligible.isEmpty,
                        "no level-1 catch under \(season)/\(time)/\(weather)")
                }
            }
        }
    }

    func testGrindingProgressesAtEveryLevelUnderEverySky() {
        // The rule's other half: "no XP requirement may demand specific
        // weather" — at every level, every sky still offers something to
        // catch, so hours (never weather) gate levels.
        for level in 1...99 {
            for season in WorldConditions.Season.allCases {
                for time in WorldConditions.TimeOfDay.allCases {
                    for weather in WorldConditions.Weather.allCases {
                        XCTAssertFalse(
                            ConditionEngine.eligibleSpecies(
                                sky(season, time, weather), level: level).isEmpty,
                            "level \(level) stalls under \(season)/\(time)/\(weather)")
                    }
                }
            }
        }
    }

    // MARK: Gating and condition filters

    func testLevelGatesSpecies() {
        let night = sky(.summer, .night, .clear)
        XCTAssertFalse(
            ConditionEngine.eligibleSpecies(night, level: 9).contains { $0.id == "catfish" })
        XCTAssertTrue(
            ConditionEngine.eligibleSpecies(night, level: 10).contains { $0.id == "catfish" })
    }

    func testConditionKeysGateSpecies() {
        // Eel: spring–autumn, night, rain/storm only.
        let level = 99
        XCTAssertTrue(
            ConditionEngine.eligibleSpecies(sky(.summer, .night, .rain), level: level)
                .contains { $0.id == "eel" })
        for wrong in [
            sky(.winter, .night, .rain),   // wrong season
            sky(.summer, .day, .rain),     // wrong time
            sky(.summer, .night, .clear),  // wrong weather
        ] {
            XCTAssertFalse(
                ConditionEngine.eligibleSpecies(wrong, level: level)
                    .contains { $0.id == "eel" })
        }
    }

    func testInkCarpIsTheStormNightApex() {
        let stormNight = sky(.autumn, .night, .storm)
        XCTAssertFalse(
            ConditionEngine.eligibleSpecies(stormNight, level: 89).contains { $0.id == "ink-carp" })
        let atNinety = ConditionEngine.eligibleSpecies(stormNight, level: 90)
        XCTAssertTrue(atNinety.contains { $0.id == "ink-carp" })
        XCTAssertTrue(atNinety.first { $0.id == "ink-carp" }!.triggersFight)
    }

    // MARK: Weighted seeded draw

    func testNextBiteIsDeterministicAndEligible() {
        let conditions = sky(.summer, .night, .rain)
        var a = SeededRandom(seed: 7)
        var b = SeededRandom(seed: 7)
        let biteA = ConditionEngine.nextBite(conditions, level: 50, using: &a)
        let biteB = ConditionEngine.nextBite(conditions, level: 50, using: &b)
        XCTAssertEqual(biteA, biteB, "same seed must give the same bite")

        let eligibleIDs = Set(ConditionEngine.eligibleSpecies(conditions, level: 50).map(\.id))
        var rng = SeededRandom(seed: 99)
        for _ in 0..<200 {
            let bite = try! XCTUnwrap(ConditionEngine.nextBite(conditions, level: 50, using: &rng))
            XCTAssertTrue(eligibleIDs.contains(bite.species.id))
            XCTAssertTrue(FishingRules.biteDelay.contains(bite.delay))
        }
    }

    func testDrawFollowsTheWeights() {
        // Under clear summer day at level 1: crucian (w100), carp (w45),
        // pale chub (w80). Over many seeded draws the heaviest weight wins
        // most often — deterministic because the seed is fixed.
        var rng = SeededRandom(seed: 4)
        var counts: [String: Int] = [:]
        let conditions = sky(.summer, .day, .clear)
        for _ in 0..<600 {
            let bite = ConditionEngine.nextBite(conditions, level: 1, using: &rng)!
            counts[bite.species.id, default: 0] += 1
        }
        XCTAssertEqual(counts.keys.count, 3, "all three level-1 species should appear")
        XCTAssertGreaterThan(counts["crucian-carp"]!, counts["common-carp"]!)
    }
}
