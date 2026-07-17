import XCTest
@testable import GameKernel

final class ClimateTests: XCTestCase {
    func testSnowlessCitiesLoseOnlySnow() {
        let snowless = ["Singapore", "Sydney", "Cairo", "San Francisco"]
        for city in City.presets where snowless.contains(city.name) {
            let capability = Climate.capability(of: city)
            XCTAssertFalse(capability.contains(.snow), city.name)
            XCTAssertEqual(capability.count, 5, "\(city.name) should lose only snow")
        }
    }

    func testTemperateCitiesProduceEverything() {
        for city in City.presets where !["Singapore", "Sydney", "Cairo", "San Francisco"].contains(city.name) {
            XCTAssertEqual(
                Climate.capability(of: city),
                Set(WorldConditions.Weather.allCases), city.name)
        }
    }

    func testUnknownCityIsNeverLocked() {
        // Missing data must not lock content (climate honesty cuts both ways).
        let somewhere = City(name: "Ulaanbaatar", latitude: 47.9, longitude: 106.9)
        XCTAssertEqual(Climate.capability(of: somewhere), Set(WorldConditions.Weather.allCases))
    }

    func testSpeciesNativeness() {
        let singapore = City.presets.first { $0.name == "Singapore" }!
        // Every M2 fish is native everywhere — no fish requires snow.
        for species in FishingTable.all {
            XCTAssertTrue(Climate.isNative(species, to: singapore), species.id)
        }
        // A snow-only species (the M3 snow lotus shape) is the first
        // "not native to your sky" case.
        let snowOnly = FishSpecies(
            id: "snow-lotus-proxy", nameEN: "Snowbound", nameKO: "설련",
            tier: .rare, unlockLevel: 1,
            seasons: Set(WorldConditions.Season.allCases),
            timesOfDay: Set(WorldConditions.TimeOfDay.allCases),
            weathers: [.snow],
            xp: 1, weight: 1,
            bitePattern: [BiteTap(offset: 0, intensity: 1, sharpness: 1, duration: 0.1)],
            archetype: "small-fry")
        XCTAssertFalse(Climate.isNative(snowOnly, to: singapore))
        XCTAssertTrue(Climate.isNative(snowOnly, to: .seoul))
    }
}
