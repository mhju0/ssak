import XCTest
import GameKernel
@testable import StrokeEngine

final class GardenRecipeTests: XCTestCase {
    func testEveryPlantableHasItsOwnRecipe() {
        for p in GardenTable.all {
            XCTAssertNotNil(Recipes.garden[p.id], "no recipe for \(p.id)")
        }
        XCTAssertEqual(
            Recipes.garden.count, GardenTable.all.count,
            "recipes must map 1:1 onto the plantable table")
    }

    func testRecipesAreDistinctNotSliderVariants() {
        let ids = Recipes.garden.keys.sorted()
        for (i, a) in ids.enumerated() {
            for b in ids[(i + 1)...] {
                XCTAssertNotEqual(
                    Recipes.garden[a]!.strokes.map(\.points),
                    Recipes.garden[b]!.strokes.map(\.points),
                    "\(a) and \(b) share stroke geometry")
            }
        }
    }

    func testRecipesAreWellFormed() {
        var all = Recipes.garden
        all["_seedling"] = Recipes.gardenSeedling
        for (id, recipe) in all {
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
