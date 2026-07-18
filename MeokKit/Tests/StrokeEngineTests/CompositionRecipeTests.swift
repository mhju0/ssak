import XCTest
import GameKernel
@testable import StrokeEngine

final class CompositionRecipeTests: XCTestCase {
    func testEveryCompositionHasAScene() {
        for composition in Artistry.compositions {
            XCTAssertNotNil(Recipes.composition[composition.id], "no scene for \(composition.id)")
        }
        XCTAssertEqual(Recipes.composition.count, Artistry.compositions.count)
    }

    func testScenesAreDistinct() {
        let ids = Recipes.composition.keys.sorted()
        for (i, a) in ids.enumerated() {
            for b in ids[(i + 1)...] {
                XCTAssertNotEqual(
                    Recipes.composition[a]!.strokes.map(\.points),
                    Recipes.composition[b]!.strokes.map(\.points),
                    "\(a) and \(b) share stroke geometry")
            }
        }
    }

    func testScenesAreWellFormed() {
        for (id, recipe) in Recipes.composition {
            XCTAssertGreaterThanOrEqual(recipe.strokes.count, 4, "\(id) is a scene, not a sketch")
            for stroke in recipe.strokes {
                XCTAssertGreaterThanOrEqual(stroke.points.count, 2, id)
                for point in stroke.points {
                    XCTAssertTrue((0...1).contains(point.x), id)
                    XCTAssertTrue((0...1).contains(point.y), id)
                    XCTAssertTrue((0...1).contains(point.pressure), id)
                }
                XCTAssertTrue((0...1).contains(stroke.ink), id)
                XCTAssertGreaterThan(stroke.duration, 0, id)
            }
        }
    }
}
