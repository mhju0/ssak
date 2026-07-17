import XCTest
@testable import GameKernel

/// The four pinned pacing invariants from the spec (§2 Pacing model) and
/// docs/design/unlock-tables.md §1, at the 100 XP/min reference rate.
final class XPCurveTests: XCTestCase {
    func testTotalToNinetyNineIsRoughlyFifteenHours() {
        // ~91k XP ≈ 15.2 h at reference rate; ×6 skills ≈ the 90-hour budget.
        let total = XPCurve.xpForLevel(99)
        XCTAssertTrue((90_000...92_000).contains(total), "total was \(total)")
    }

    func testLevelTwoCostsMinutes() {
        XCTAssertEqual(XPCurve.cost(toLeaveLevel: 1), 250) // 2.5 min
    }

    func testSteepTailIsFortyPercentOfTheSkill() {
        let total = Double(XPCurve.xpForLevel(99))
        let tail = total - Double(XPCurve.xpForLevel(90))
        let fraction = tail / total
        XCTAssertTrue((0.39...0.42).contains(fraction), "tail fraction was \(fraction)")
    }

    func testFinalLevelAloneIsAFocusedWeek() {
        // 98→99 ≈ 1.5 h at reference pace.
        let last = XPCurve.cost(toLeaveLevel: 98)
        XCTAssertTrue((9_000...9_600).contains(last), "98→99 cost was \(last)")
    }

    func testCostGrowsTheWholeWayIncludingTheSeam() {
        // "Cost-per-level grows the whole way" — no dip where the tail
        // regime takes over at 90.
        for level in 1..<98 {
            XCTAssertLessThanOrEqual(
                XPCurve.cost(toLeaveLevel: level),
                XPCurve.cost(toLeaveLevel: level + 1),
                "cost dipped between \(level) and \(level + 1)")
        }
    }

    func testLevelForXPInvertsTheCurve() {
        XCTAssertEqual(XPCurve.level(forXP: 0), 1)
        XCTAssertEqual(XPCurve.level(forXP: XPCurve.xpForLevel(50)), 50)
        XCTAssertEqual(XPCurve.level(forXP: XPCurve.xpForLevel(50) - 1), 49)
        XCTAssertEqual(XPCurve.level(forXP: XPCurve.xpForLevel(99)), 99)
        XCTAssertEqual(XPCurve.level(forXP: .max), 99) // capped forever
    }

    func testSixSkillsExist() {
        XCTAssertEqual(Skill.allCases.count, 6)
    }
}
