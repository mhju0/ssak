import XCTest
import GameKernel
@testable import StrokeEngine

final class FishRecipeTests: XCTestCase {
    func testEverySpeciesHasItsOwnRecipe() {
        for species in FishingTable.all {
            XCTAssertNotNil(Recipes.fish[species.id], "no recipe for \(species.id)")
        }
        XCTAssertEqual(
            Recipes.fish.count, FishingTable.all.count,
            "recipes must map 1:1 onto the species table")
    }

    func testRecipesAreDistinctNotSliderVariants() {
        // Spec §3: each species is a distinct recipe — never one template
        // with slider variants. No two species may share stroke geometry.
        let ids = Recipes.fish.keys.sorted()
        for (i, a) in ids.enumerated() {
            for b in ids[(i + 1)...] {
                XCTAssertNotEqual(
                    Recipes.fish[a]!.strokes.map(\.points),
                    Recipes.fish[b]!.strokes.map(\.points),
                    "\(a) and \(b) share stroke geometry")
            }
        }
    }

    func testRecipesAreWellFormed() {
        for (id, recipe) in Recipes.fish {
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
