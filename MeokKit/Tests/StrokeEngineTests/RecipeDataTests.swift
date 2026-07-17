import XCTest
@testable import StrokeEngine

/// Sanity guards on authored recipe data — cheap typo insurance.
final class RecipeDataTests: XCTestCase {
    func testCarpIsAnOrderedRecipeWithSumiEconomy() {
        // Loose bounds — enough to catch emptied or exploded data without
        // pinning the art (only the keeper's 5–10 is an actual spec bound).
        let strokes = Recipes.carp.strokes
        XCTAssertGreaterThanOrEqual(strokes.count, 5)
        XCTAssertLessThanOrEqual(strokes.count, 15)
    }

    func testCarpPointsStayInsideUnitSquare() {
        for (index, stroke) in Recipes.carp.strokes.enumerated() {
            XCTAssertGreaterThanOrEqual(stroke.points.count, 2, "stroke \(index)")
            for point in stroke.points {
                XCTAssert((0 ... 1).contains(point.x), "stroke \(index) x=\(point.x)")
                XCTAssert((0 ... 1).contains(point.y), "stroke \(index) y=\(point.y)")
                XCTAssert((0 ... 1).contains(point.pressure), "stroke \(index)")
            }
        }
    }

    func testEveryCarpStrokeProducesDabs() {
        for (index, stroke) in Recipes.carp.strokes.enumerated() {
            let spacing = max(stroke.width / 2 * 0.38, 0.0015)
            XCTAssertFalse(stroke.dabs(spacing: spacing).isEmpty, "stroke \(index)")
        }
    }

    func testPropRecipesStayInBoundsAndProduceDabs() {
        let props: [(String, StrokeRecipe)] = [
            ("pine", Recipes.pine), ("rock", Recipes.rock), ("hut", Recipes.hut),
            ("gardenBeds", Recipes.gardenBeds), ("pondBank", Recipes.pondBank),
        ]
        for (name, recipe) in props {
            XCTAssertFalse(recipe.strokes.isEmpty, name)
            for (index, stroke) in recipe.strokes.enumerated() {
                for point in stroke.points {
                    XCTAssert((0 ... 1).contains(point.x), "\(name) stroke \(index)")
                    XCTAssert((0 ... 1).contains(point.y), "\(name) stroke \(index)")
                }
                let spacing = max(stroke.width / 2 * 0.38, 0.0015)
                XCTAssertFalse(stroke.dabs(spacing: spacing).isEmpty, "\(name) stroke \(index)")
            }
        }
    }

    func testKeeperPosesKeepStaffageEconomy() {
        // Spec D8: the keeper is 5–10 strokes with a 갓 silhouette.
        for (name, recipe) in [("standing", Recipes.keeperStanding), ("seated", Recipes.keeperSeated)] {
            XCTAssertGreaterThanOrEqual(recipe.strokes.count, 5, name)
            XCTAssertLessThanOrEqual(recipe.strokes.count, 10, name)
            for (index, stroke) in recipe.strokes.enumerated() {
                for point in stroke.points {
                    XCTAssert((0 ... 1).contains(point.x), "\(name) stroke \(index)")
                    XCTAssert((0 ... 1).contains(point.y), "\(name) stroke \(index)")
                }
            }
        }
    }
}
