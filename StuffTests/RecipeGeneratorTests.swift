import XCTest
@testable import Stuff

final class RecipeGeneratorTests: XCTestCase {
    @MainActor
    func testRecipeCleansTextAndPreservesSelectedIngredients() throws {
        let result = try RecipeGenerator.makeResult(
            title: " Soup \n", summary: " A warm meal. \n", ingredients: ["Carrot", "Rice", "Carrot"],
            additionalIngredients: [" Salt ", " \n", "Water"],
            steps: [" Chop carrot. \n", " ", "Cook rice."], canMakeMeal: true)
        XCTAssertEqual(result.title, "Soup")
        XCTAssertEqual(result.summary, "A warm meal.")
        XCTAssertEqual(result.selectedIngredients, ["Carrot", "Rice", "Carrot"])
        XCTAssertEqual(result.additionalIngredients, ["Salt", "Water"])
        XCTAssertEqual(result.steps, ["Chop carrot.", "Cook rice."])
        XCTAssertTrue(result.canMakeMeal)
    }

    @MainActor
    func testMealWithoutUsableStepsIsRejected() {
        for steps in [[], [" ", "\n"]] as [[String]] {
            XCTAssertThrowsError(try RecipeGenerator.makeResult(
                title: "Meal", summary: "", ingredients: ["Rice"], additionalIngredients: [],
                steps: steps, canMakeMeal: true)) { error in
                guard case RecipeGenerationError.emptyResponse = error else {
                    return XCTFail("Expected emptyResponse, got \(error)")
                }
            }
        }
    }

    @MainActor
    func testDeclinedMealCanExplainWhyWithoutSteps() throws {
        let result = try RecipeGenerator.makeResult(
            title: "No meal", summary: " Unknown ingredient. ", ingredients: ["Unknown item"],
            additionalIngredients: [], steps: [], canMakeMeal: false)
        XCTAssertFalse(result.canMakeMeal)
        XCTAssertTrue(result.steps.isEmpty)
        XCTAssertEqual(result.summary, "Unknown ingredient.")
        XCTAssertEqual(result.selectedIngredients, ["Unknown item"])
    }
}
