import XCTest
import GameKernel
@testable import StrokeEngine

final class CraftRecipeTests: XCTestCase {
    func testEveryCraftableArchetypeHasArt() {
        for craftable in CraftingTable.all {
            XCTAssertNotNil(
                Recipes.craftArt[craftable.archetype],
                "no art for \(craftable.id) archetype \(craftable.archetype)")
        }
    }

    func testRecipesAreWellFormed() {
        for (id, recipe) in Recipes.craftArt {
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
