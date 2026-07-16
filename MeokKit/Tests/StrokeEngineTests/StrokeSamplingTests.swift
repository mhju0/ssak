import XCTest
@testable import StrokeEngine

final class StrokeSamplingTests: XCTestCase {
    // MARK: Straight line — the worked example

    func testStraightLineDabsAreEvenlySpaced() {
        let stroke = Stroke(
            points: [StrokePoint(0, 0), StrokePoint(10, 0)],
            width: 2
        )
        let dabs = stroke.dabs(spacing: 1)

        // 10 units of arc at spacing 1 → 11 dabs at x ≈ 0, 1, …, 10 on y = 0.
        XCTAssertEqual(dabs.count, 11)
        for (index, dab) in dabs.enumerated() {
            XCTAssertEqual(dab.position.x, Double(index), accuracy: 0.05)
            XCTAssertEqual(dab.position.y, 0, accuracy: 0.001)
        }
    }

    func testHalvingSpacingRoughlyDoublesDabCount() {
        let stroke = Stroke(
            points: [StrokePoint(0, 0), StrokePoint(4, 3), StrokePoint(9, 1)],
            width: 2
        )
        let coarse = stroke.dabs(spacing: 0.5).count
        let fine = stroke.dabs(spacing: 0.25).count
        assertClose(fine, coarse * 2 - 1, within: 2)
    }

    // MARK: Spline shape

    func testCurvePassesThroughInteriorControlPoint() {
        let stroke = Stroke(
            points: [StrokePoint(0, 0), StrokePoint(5, 5), StrokePoint(10, 0)],
            width: 2
        )
        let dabs = stroke.dabs(spacing: 0.1)
        let nearest = dabs.map { $0.position.distance(to: .init(x: 5, y: 5)) }.min()!
        XCTAssertLessThan(nearest, 0.15)
    }

    // MARK: Pressure → radius

    func testPressureInterpolatesAlongStroke() {
        let stroke = Stroke(
            points: [StrokePoint(0, 0, pressure: 0.1), StrokePoint(10, 0, pressure: 1.0)],
            width: 4
        )
        let dabs = stroke.dabs(spacing: 0.5)

        // Radius = width/2 × pressure: 0.2 at the start, 2.0 at the end.
        XCTAssertEqual(dabs.first!.radius, 0.2, accuracy: 0.05)
        XCTAssertEqual(dabs.last!.radius, 2.0, accuracy: 0.05)
        // Monotonic under monotonic pressure.
        for pair in zip(dabs, dabs.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0.radius, pair.1.radius + 0.001)
        }
    }

    // MARK: Reveal timing parameter

    func testDabTRunsZeroToOneMonotonically() {
        let stroke = Stroke(
            points: [StrokePoint(0, 0), StrokePoint(3, 4), StrokePoint(8, 2)],
            width: 2
        )
        let dabs = stroke.dabs(spacing: 0.3)

        XCTAssertEqual(dabs.first!.t, 0, accuracy: 0.001)
        XCTAssertEqual(dabs.last!.t, 1, accuracy: 0.05)
        for pair in zip(dabs, dabs.dropFirst()) {
            XCTAssertLessThan(pair.0.t, pair.1.t)
        }
    }

    // MARK: Recipes are data

    func testRecipeRoundTripsThroughJSON() throws {
        let recipe = StrokeRecipe(strokes: [
            Stroke(points: [StrokePoint(0, 0, pressure: 0.3), StrokePoint(1, 1)],
                   width: 0.1, ink: 0.9, dryness: 0.4, pooling: 0.7, duration: 0.8)
        ])
        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(StrokeRecipe.self, from: data)
        XCTAssertEqual(decoded, recipe)
    }
}

private extension XCTestCase {
    func assertClose(_ a: Int, _ b: Int, within tolerance: Int) {
        XCTAssertLessThanOrEqual(abs(a - b), tolerance, "\(a) not within \(tolerance) of \(b)")
    }
}
