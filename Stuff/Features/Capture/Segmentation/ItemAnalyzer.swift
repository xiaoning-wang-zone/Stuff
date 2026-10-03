#if os(iOS)
import Foundation
import FoundationModels
import UIKit

@Generable
private struct ItemSuggestion {
    @Guide(description: "Short, specific common name for the single visible food item. Use Unknown item if unclear.")
    var name: String

    @Guide(description: "One category from the supplied category list, or Unknown.")
    var category: String

    @Guide(description: "Typical number of days until this food may expire when stored as instructed. Return 0 if uncertain.")
    var estimatedDays: Int

    @Guide(description: "Short storage assumption, such as refrigerated, frozen, or pantry. Say uncertain if unclear.")
    var storageNote: String
}

struct ItemDraft: Identifiable {
    let id = UUID()
    let image: UIImage
    var name: String = "Unknown item"
    var categoryName: String = "Unknown"
    var expiresAt: Date?
    var hasExpiryEstimate = false
    var expirySource = "unknown"
    var storageNote = ""
}

enum ItemAnalyzer {
    static func analyze(_ images: [UIImage], capturedAt: Date = .now) async -> [ItemDraft] {
        var drafts: [ItemDraft] = []
        for image in images {
            var draft = ItemDraft(image: image)
            if SystemLanguageModel.default.isAvailable, let cgImage = image.cgImage {
                do {
                    let session = LanguageModelSession(
                        model: .default,
                        instructions: "Identify one photographed food item. Never invent a printed use-by date. Estimate a typical shelf life only when the food and storage condition are reasonably clear."
                    )
                    let categories = FoodCategory.all.map(\.name).joined(separator: ", ")
                    let response = try await session.respond(
                        generating: ItemSuggestion.self,
                        options: GenerationOptions(samplingMode: .greedy)
                    ) {
                        "Identify this isolated food item. Choose its category from: \(categories). Estimate days from capture until expiry based on the visible item and your stated storage assumption. If you cannot identify it or estimate safely, use Unknown and 0 days."
                        Attachment(cgImage)
                    }
                    let suggestion = response.content
                    let cleanName = suggestion.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    draft.name = cleanName.isEmpty ? "Unknown item" : String(cleanName.prefix(80))
                    draft.categoryName = FoodCategory.all.first {
                        $0.name.caseInsensitiveCompare(suggestion.category.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
                    }?.name ?? "Unknown"
                    draft.storageNote = String(suggestion.storageNote.prefix(160))
                    if (1...365).contains(suggestion.estimatedDays), draft.name != "Unknown item" {
                        draft.expiresAt = Calendar.current.date(byAdding: .day, value: suggestion.estimatedDays, to: capturedAt)
                        draft.hasExpiryEstimate = draft.expiresAt != nil
                        draft.expirySource = draft.hasExpiryEstimate ? "estimated" : "unknown"
                    }
                } catch {
                    // A failed or unavailable model leaves an editable unknown item.
                }
            }
            drafts.append(draft)
        }
        return drafts
    }
}
#endif
