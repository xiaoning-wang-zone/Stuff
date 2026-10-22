import XCTest
import SwiftData
import UIKit
@testable import Stuff

/// High-level checks for Capture, Storage, and Inspiration.
/// Uses temporary files and an in-memory database; no camera or AI model is needed.
final class FeatureFunctionalityTests: XCTestCase {
    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([StoredCapture.self, StoredItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    @MainActor
    private func makeItem(name: String, category: String, captureID: UUID, number: Int) -> StoredItem {
        StoredItem(captureID: captureID, itemNumber: number, name: name,
                   categoryName: category, capturedAt: Date(timeIntervalSince1970: 0),
                   expiresAt: nil, expirySource: "unknown", storageNote: "", needsReview: true)
    }

    @MainActor
    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20), format: format).image {
            UIColor.green.setFill()
            $0.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
    }

    @MainActor
    func testCaptureCanSaveMultiplePhotosWithMultipleItems() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let photo = makeImage()
        let captureIDs = [UUID(), UUID()]

        for id in captureIDs {
            let folder = try CapturedPhotoStore.save(id: id, original: photo, foreground: photo,
                                                    items: [photo, photo, photo], directory: directory)
            for filename in ["original.jpg", "foreground.png", "item-1.png", "item-2.png", "item-3.png"] {
                XCTAssertNotNil(UIImage(contentsOfFile: folder.appendingPathComponent(filename).path),
                                "Each capture should retain a readable \(filename).")
            }
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 2)
    }

    @MainActor
    func testStorageCanSaveAndRetrieveMultipleItemsAcrossCaptures() throws {
        let context = try makeContext()
        let firstID = UUID()
        let secondID = UUID()
        let items = [makeItem(name: "Apple", category: "Fruits", captureID: firstID, number: 1),
                     makeItem(name: "Pear", category: "Fruits", captureID: firstID, number: 2),
                     makeItem(name: "Carrot", category: "Vegetables", captureID: secondID, number: 1)]
        for id in [firstID, secondID] {
            context.insert(StoredCapture(id: id, capturedAt: .now, folderName: id.uuidString))
        }
        for item in items { context.insert(item) }
        try context.save()

        // Read through another context to check saved data, rather than just the input array.
        let reader = ModelContext(context.container)
        let saved = try reader.fetch(FetchDescriptor<StoredItem>())
        XCTAssertEqual(Set(saved.map(\.id)), Set(items.map(\.id)))
        XCTAssertEqual(Set(saved.map(\.name)), Set(["Apple", "Pear", "Carrot"]))
        XCTAssertEqual(saved.filter { $0.categoryName == "Fruits" }.count, 2)
        XCTAssertEqual(saved.filter { $0.categoryName == "Vegetables" }.count, 1)
        XCTAssertEqual(try reader.fetchCount(FetchDescriptor<StoredCapture>()), 2)
    }

    @MainActor
    func testStorageCanSaveReviewedItemDetails() throws {
        let context = try makeContext()
        let item = makeItem(name: "Unknown item", category: "Unknown", captureID: UUID(), number: 1)
        context.insert(item)
        try context.save()

        item.name = "Milk"
        item.categoryName = "Dairy"
        item.expiresAt = Date(timeIntervalSince1970: 7 * 86_400)
        item.expirySource = "manual"
        item.storageNote = "Keep refrigerated"
        item.needsReview = false
        try context.save()

        let saved = try XCTUnwrap(ModelContext(context.container).fetch(FetchDescriptor<StoredItem>()).first)
        XCTAssertEqual(saved.name, "Milk")
        XCTAssertEqual(saved.categoryName, "Dairy")
        XCTAssertEqual(saved.expiresAt, item.expiresAt)
        XCTAssertEqual(saved.expirySource, "manual")
        XCTAssertEqual(saved.storageNote, "Keep refrigerated")
        XCTAssertFalse(saved.needsReview)
    }

    @MainActor
    func testCaptureSuggestionsCanBeReviewedIndependently() {
        let photo = makeImage()
        var drafts = ["Apple", "Pear", "Carrot"].map {
            ItemAnalyzer.makeDraft(image: photo, name: $0, category: "Fruits",
                                   estimatedDays: 7, storageNote: "Refrigerated", capturedAt: .now)
        }
        drafts[2].categoryName = "Vegetables"

        XCTAssertEqual(drafts.count, 3)
        XCTAssertEqual(Set(drafts.map(\.id)).count, 3)
        XCTAssertEqual(drafts.map(\.name), ["Apple", "Pear", "Carrot"])
        XCTAssertEqual(drafts.map(\.categoryName), ["Fruits", "Fruits", "Vegetables"])
        XCTAssertTrue(drafts.allSatisfy { $0.expiresAt != nil })
    }

    @MainActor
    func testInspirationCanPrepareMultipleIndependentRecipeResults() throws {
        // Fixtures check response handling. They do not call or validate live AI generation.
        let selections = [["Carrot", "Rice"], ["Eggs", "Milk"], ["Apple", "Pear"]]
        let recipes = try selections.map { ingredients in
            try RecipeGenerator.makeResult(title: ingredients.joined(separator: " and "),
                                           summary: "Meal idea", ingredients: ingredients,
                                           additionalIngredients: [],
                                           steps: ["Prepare " + ingredients.joined(separator: " and ")],
                                           canMakeMeal: true)
        }

        XCTAssertEqual(recipes.count, 3)
        XCTAssertEqual(Set(recipes.map(\.id)).count, 3)
        XCTAssertEqual(recipes.map(\.selectedIngredients), selections)
        XCTAssertTrue(recipes.allSatisfy { $0.canMakeMeal && !$0.steps.isEmpty })
    }

    @MainActor
    func testInspirationCanHandleAnUnavailableModelError() {
        XCTAssertEqual(RecipeGenerationError.modelUnavailable.errorDescription,
                       "Recipes need Apple Intelligence enabled on a supported iPhone.")
    }
}
