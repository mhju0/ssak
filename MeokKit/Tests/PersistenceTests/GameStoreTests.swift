import XCTest
import SwiftData
import GameKernel
@testable import Persistence

@MainActor
final class GameStoreTests: XCTestCase {
    private var store: GameStore!

    override func setUp() async throws {
        store = try GameStore.inMemory()
    }

    private var crucian: FishSpecies {
        FishingTable.all.first { $0.id == "crucian-carp" }!
    }

    func testCatchAwardsXPAndRecordsTheVariant() throws {
        let outcome = store.record(catch: crucian, weather: .rain)

        XCTAssertEqual(outcome.xpAwarded, 60)
        XCTAssertEqual(outcome.level, 1)
        XCTAssertFalse(outcome.leveledUp)
        XCTAssertTrue(outcome.firstOfSpecies)
        XCTAssertTrue(outcome.newWeatherVariant)

        XCTAssertEqual(store.progress(for: .fishing).xp, 60)
        let record = try XCTUnwrap(store.record(for: "crucian-carp"))
        XCTAssertEqual(record.timesCaught, 1)
        XCTAssertEqual(record.caughtWeathers, ["rain"])
        XCTAssertFalse(record.gotAway)
    }

    func testRepeatCatchCountsButDoesNotDuplicateTheVariant() throws {
        _ = store.record(catch: crucian, weather: .rain)
        let second = store.record(catch: crucian, weather: .rain)

        XCTAssertFalse(second.firstOfSpecies)
        XCTAssertFalse(second.newWeatherVariant)
        let record = try XCTUnwrap(store.record(for: "crucian-carp"))
        XCTAssertEqual(record.timesCaught, 2)
        XCTAssertEqual(record.caughtWeathers, ["rain"])

        let clearCatch = store.record(catch: crucian, weather: .clear)
        XCTAssertTrue(clearCatch.newWeatherVariant)
        XCTAssertEqual(Set(store.record(for: "crucian-carp")!.caughtWeathers), ["rain", "clear"])
    }

    func testLevelUpIsDetectedAtTheThreshold() {
        // 250 XP ends level 1; five 60-XP crucians cross it.
        for _ in 0..<4 { _ = store.record(catch: crucian, weather: .clear) }
        XCTAssertEqual(store.progress(for: .fishing).xp, 240)

        let fifth = store.record(catch: crucian, weather: .clear)
        XCTAssertTrue(fifth.leveledUp)
        XCTAssertEqual(fifth.level, 2)
    }

    func testEscapeLogsTheShadowAndCostsNothing() throws {
        store.recordEscape(of: crucian)

        XCTAssertEqual(store.progress(for: .fishing).xp, 0, "a lost fish costs only the moment")
        let record = try XCTUnwrap(store.record(for: "crucian-carp"))
        XCTAssertTrue(record.gotAway)
        XCTAssertEqual(record.timesCaught, 0)

        // Catching it later keeps the shadow history but fills the entry.
        _ = store.record(catch: crucian, weather: .clear)
        XCTAssertEqual(store.record(for: "crucian-carp")!.timesCaught, 1)
    }

    private var mugwort: Forageable {
        ForagingTable.all.first { $0.id == "mugwort" }!
    }

    func testGatherAwardsForagingXPIndependentlyOfFishing() throws {
        let outcome = store.record(gather: mugwort, weather: .clear)

        XCTAssertEqual(outcome.xpAwarded, 40)
        XCTAssertTrue(outcome.firstOfSpecies)
        XCTAssertTrue(outcome.newWeatherVariant)

        // The haul lands on foraging, never fishing — separate currencies.
        XCTAssertEqual(store.progress(for: .foraging).xp, 40)
        XCTAssertEqual(store.progress(for: .fishing).xp, 0)

        let record = try XCTUnwrap(store.record(for: "mugwort"))
        XCTAssertEqual(record.timesCaught, 1)
        XCTAssertEqual(record.caughtWeathers, ["clear"])
    }

    func testGatherAccruesVariantsLikeAcatch() throws {
        _ = store.record(gather: mugwort, weather: .clear)
        let foggy = store.record(gather: mugwort, weather: .fog)
        XCTAssertFalse(foggy.firstOfSpecies)
        XCTAssertTrue(foggy.newWeatherVariant)
        XCTAssertEqual(Set(store.record(for: "mugwort")!.caughtWeathers), ["clear", "fog"])
    }

    func testProgressRowIsCreatedOnce() throws {
        _ = store.progress(for: .fishing)
        _ = store.progress(for: .fishing)
        let rows = try store.context.fetch(FetchDescriptor<SkillProgress>())
        XCTAssertEqual(rows.count, 1)
    }
}
