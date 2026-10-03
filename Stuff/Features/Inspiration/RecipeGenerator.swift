#if os(iOS)
import Foundation
import FoundationModels

@Generable
private struct GeneratedRecipe {
    @Guide(description: "A short, appealing name for the meal.")
    var title: String

    @Guide(description: "One or two sentences describing the meal, or explaining why these items cannot safely make a meal.")
    var summary: String

    @Guide(description: "True only if all selected items are edible and can reasonably be used in one meal.")
    var canMakeMeal: Bool

    @Guide(description: "Optional additional ingredients, such as oil, salt, or water. Keep this list short.")
    var additionalIngredients: [String]

    @Guide(description: "Clear, ordered preparation and cooking steps that use every selected ingredient. Empty if no safe meal is possible.")
    var steps: [String]
}

struct RecipeResult: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let selectedIngredients: [String]
    let additionalIngredients: [String]
    let steps: [String]
    let canMakeMeal: Bool
}

enum RecipeGenerationError: LocalizedError {
    case modelUnavailable
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            "Recipes need Apple Intelligence enabled on a supported iPhone."
        case .emptyResponse:
            "The iPhone could not make a recipe from these items. Please try again."
        }
    }
}

enum RecipeGenerator {
    static func generate(ingredients: [String]) async throws -> RecipeResult {
        guard SystemLanguageModel.default.isAvailable else {
            throw RecipeGenerationError.modelUnavailable
        }

        let session = LanguageModelSession(
            model: .default,
            instructions: "You are a practical home cook. Make one realistic meal using every selected edible ingredient. Never pretend that an inedible item is food. Do not claim an item is fresh or safe based only on its name. If the selected items cannot reasonably and safely make a meal together, say so instead of inventing a recipe."
        )
        let ingredientList = ingredients.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
        let response = try await session.respond(
            generating: GeneratedRecipe.self,
            options: GenerationOptions(samplingMode: .greedy)
        ) {
            "Create one meal using ALL of these selected Storage items. Each item must appear in the cooking instructions and be used in the meal; do not silently omit or replace any of them. You may add a few basic pantry ingredients, listed separately. If an item is not edible, unknown, or incompatible with a safe meal, set canMakeMeal to false and explain why. Selected items:\n\(ingredientList)"
        }
        let recipe = response.content
        return try makeResult(
            title: recipe.title,
            summary: recipe.summary,
            ingredients: ingredients,
            additionalIngredients: recipe.additionalIngredients,
            steps: recipe.steps,
            canMakeMeal: recipe.canMakeMeal
        )
    }

    /// Normalize and validate the response without requiring Apple Intelligence.
    static func makeResult(
        title: String,
        summary: String,
        ingredients: [String],
        additionalIngredients: [String],
        steps: [String],
        canMakeMeal: Bool
    ) throws -> RecipeResult {
        let steps = steps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !canMakeMeal || !steps.isEmpty else {
            throw RecipeGenerationError.emptyResponse
        }

        return RecipeResult(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            selectedIngredients: ingredients,
            additionalIngredients: additionalIngredients
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            steps: steps,
            canMakeMeal: canMakeMeal
        )
    }
}
#endif
