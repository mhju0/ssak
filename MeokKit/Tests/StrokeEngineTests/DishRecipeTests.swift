import XCTest
import GameKernel
@testable import StrokeEngine

final class DishRecipeTests: XCTestCase {
    func testEveryDishArchetypeHasArt() {
        for dish in CookingTable.all {
            XCTAssertNotNil(
                Recipes.dishArt[dish.archetype],
                "no art for \(dish.id) archetype \(dish.archetype)")
        }
    }

    func testRecipesAreWellFormed() {
        for (id, recipe) in Recipes.dishArt {
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
