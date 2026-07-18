import XCTest
@testable import GameKernel

final class VisitorTests: XCTestCase {
    private func sky(
        _ time: WorldConditions.TimeOfDay, _ weather: WorldConditions.Weather,
        season: WorldConditions.Season = .summer
    ) -> WorldConditions {
        WorldConditions(weather: weather, precipitation: 0, windSpeed: 0, timeOfDay: time, season: season)
    }

    // MARK: Presence (spec §2 conditions)

    func testOldFishermanComesOnMorningRain() {
        XCTAssertEqual(Visitors.present(sky(.dawn, .rain), peddlerToday: false)?.id, .oldFisherman)
    }

    func testDokkaebiComesOnStormNights() {
        XCTAssertEqual(Visitors.present(sky(.night, .storm), peddlerToday: false)?.id, .dokkaebi)
    }

    func testPeddlerArrivesWhenItIsTheirDay() {
        XCTAssertEqual(Visitors.present(sky(.day, .clear), peddlerToday: true)?.id, .peddler)
        XCTAssertNil(Visitors.present(sky(.day, .clear), peddlerToday: false), "otherwise the grounds are quiet")
    }

    func testAConditionVisitorOutranksThePeddler() {
        XCTAssertEqual(
            Visitors.present(sky(.night, .storm), peddlerToday: true)?.id, .dokkaebi,
            "the storm-night dokkaebi wins over a peddler day")
    }

    // MARK: Trades (barter, no currency — spec §2)

    func testTheFishermanAndDokkaebiTradeSpecies() {
        XCTAssertTrue(Visitors.offers(for: .oldFisherman, climate: allWeathers).contains { $0.get == .species("eel") })
        XCTAssertTrue(Visitors.offers(for: .dokkaebi, climate: allWeathers).contains { $0.get == .species("ink-carp") })
    }

    func testThePeddlerIsTheClimateValve() {
        // Snowless sky: the snow lotus is climate-locked, so the peddler carries it.
        let snowless = allWeathers.subtracting([.snow])
        let offers = Visitors.offers(for: .peddler, climate: snowless)
        XCTAssertTrue(offers.contains { $0.get == .species("snow-lotus") },
                      "the peddler is the slow path to what the sky can't produce")
        // A full-climate sky produces the snow lotus itself — the peddler needn't carry it.
        let full = Visitors.offers(for: .peddler, climate: allWeathers)
        XCTAssertFalse(full.contains { $0.get == .species("snow-lotus") })
    }

    func testEveryOfferGivesSomethingRealForSomethingReal() {
        let known = Set(FishingTable.all.map(\.id) + ForagingTable.all.map(\.id) + GardenTable.all.map(\.id))
        for visitor in VisitorID.allCases {
            for offer in Visitors.offers(for: visitor, climate: allWeathers.subtracting([.snow])) {
                XCTAssertGreaterThan(offer.give.count, 0, offer.id)
                if case .species(let id) = offer.get { XCTAssertTrue(known.contains(id), offer.id) }
            }
        }
    }

    private var allWeathers: Set<WorldConditions.Weather> { Set(WorldConditions.Weather.allCases) }
}
