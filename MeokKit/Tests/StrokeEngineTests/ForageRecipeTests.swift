import XCTest
import GameKernel
@testable import StrokeEngine

final class ForageRecipeTests: XCTestCase {
    func testEveryForageableHasItsOwnRecipe() {
        for f in ForagingTable.all {
            XCTAssertNotNil(Recipes.forage[f.id], "no recipe for \(f.id)")
        }
        XCTAssertEqual(
            Recipes.forage.count, ForagingTable.all.count,
            "recipes must map 1:1 onto the forageable table")
    }

    func testRecipesAreDistinctNotSliderVariants() {
        // Spec §3: each is a distinct recipe, never one template with sliders.
        let ids = Recipes.forage.keys.sorted()
        for (i, a) in ids.enumerated() {
            for b in ids[(i + 1)...] {
                XCTAssertNotEqual(
                    Recipes.forage[a]!.strokes.map(\.points),
                    Recipes.forage[b]!.strokes.map(\.points),
                    "\(a) and \(b) share stroke geometry")
            }
        }
    }

    func testRecipesAreWellFormed() {
        for (id, recipe) in Recipes.forage {
            XCTAssertFalse(recipe.strokes.isEmpty, id)
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
