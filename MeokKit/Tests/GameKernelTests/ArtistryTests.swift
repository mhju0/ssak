import XCTest
@testable import GameKernel

final class ArtistryTests: XCTestCase {
    func testTableMatchesTheDraftedDesign() {
        let compositions = Artistry.compositions
        XCTAssertEqual(compositions.count, 5)
        XCTAssertEqual(Set(compositions.map(\.id)).count, 5, "composition ids must be unique")
        XCTAssertEqual(Set(compositions.map(\.zone)).count, 5, "one composition per zone")
        for composition in compositions {
            XCTAssertTrue((1...99).contains(composition.unlockLevel), composition.id)
            XCTAssertGreaterThan(composition.xp, 0, composition.id)
            XCTAssertFalse(composition.nameKO.isEmpty, composition.id)
        }
    }

    func testLevelGatesCompositions() {
        XCTAssertFalse(Artistry.available(level: 9).contains { $0.id == "hermitage" })
        XCTAssertTrue(Artistry.available(level: 10).contains { $0.id == "hermitage" })
    }

    func testTechniquesUnlockByLevel() {
        XCTAssertTrue(Artistry.techniques(level: 19).isEmpty)
        XCTAssertEqual(Artistry.techniques(level: 20), [.wetWash])
        XCTAssertTrue(Artistry.techniques(level: 50).isSuperset(of: [.wetWash, .dryBrush, .pooling]))
        XCTAssertFalse(Artistry.techniques(level: 69).contains(.mist))
        XCTAssertTrue(Artistry.techniques(level: 70).contains(.mist))
    }

    func testTheSealIsEarnedAtNinety() {
        XCTAssertFalse(Artistry.sealEarned(level: 89))
        XCTAssertTrue(Artistry.sealEarned(level: 90), "the red seal — the game's only color (spec §2)")
    }

    func testPondVistaIsTheFirstFrame() {
        let pond = Artistry.composition(id: "pond-vista")
        XCTAssertEqual(pond?.unlockLevel, 1)
        XCTAssertEqual(pond?.zone, .valleyPond)
    }
}
