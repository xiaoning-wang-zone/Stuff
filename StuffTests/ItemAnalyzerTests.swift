import XCTest
import UIKit
@testable import Stuff

final class ItemAnalyzerTests: XCTestCase {
    @MainActor
    private func draft(name: String = "Apple", category: String = "Fruits", days: Int = 7,
                       note: String = "refrigerated") -> ItemDraft {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return ItemAnalyzer.makeDraft(image: UIImage(), name: name, category: category,
                                      estimatedDays: days, storageNote: note,
                                      capturedAt: Date(timeIntervalSince1970: 0), calendar: calendar)
    }

    @MainActor
    func testSuggestionNormalizesNameCategoryAndExpiry() {
        let result = draft(name: " \nApple \n", category: " fruits \n")
        XCTAssertEqual(result.name, "Apple")
        XCTAssertEqual(result.categoryName, "Fruits")
        XCTAssertEqual(result.expiresAt, Date(timeIntervalSince1970: 7 * 86_400))
        XCTAssertTrue(result.hasExpiryEstimate)
        XCTAssertEqual(result.expirySource, "estimated")
        XCTAssertEqual(result.storageNote, "refrigerated")
    }

    @MainActor
    func testUnknownNameNeverGetsAnExpiryEstimate() {
        for name in [" \n", "Unknown item"] {
            let result = draft(name: name)
            XCTAssertEqual(result.name, "Unknown item")
            XCTAssertNil(result.expiresAt)
            XCTAssertFalse(result.hasExpiryEstimate)
            XCTAssertEqual(result.expirySource, "unknown")
        }
    }

    @MainActor
    func testInvalidShelfLifeIsRejected() {
        for days in [-1, 0, 366, Int.max] {
            let result = draft(days: days)
            XCTAssertNil(result.expiresAt)
            XCTAssertFalse(result.hasExpiryEstimate)
            XCTAssertEqual(result.expirySource, "unknown")
        }
    }

    @MainActor
    func testShelfLifeBoundariesAreAccepted() {
        for days in [1, 365] {
            XCTAssertEqual(draft(days: days).expiresAt, Date(timeIntervalSince1970: Double(days * 86_400)))
        }
    }

    @MainActor
    func testUnsupportedCategoryAndLongTextAreHandled() {
        let result = draft(name: String(repeating: "a", count: 100), category: "Not a category",
                           note: String(repeating: "b", count: 200))
        XCTAssertEqual(result.categoryName, "Unknown")
        XCTAssertEqual(result.name.count, 80)
        XCTAssertEqual(result.storageNote.count, 160)
    }

    @MainActor
    func testEmptyImageSelectionProducesNoDrafts() async {
        let results = await ItemAnalyzer.analyze([])
        XCTAssertTrue(results.isEmpty)
    }

    @MainActor
    func testUnreadableImagesRemainEditableUnknownDrafts() async {
        let results = await ItemAnalyzer.analyze([UIImage(), UIImage()])
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(Set(results.map(\.id)).count, 2)
        for result in results {
            XCTAssertEqual(result.name, "Unknown item")
            XCTAssertEqual(result.categoryName, "Unknown")
            XCTAssertNil(result.expiresAt)
            XCTAssertFalse(result.hasExpiryEstimate)
            XCTAssertEqual(result.expirySource, "unknown")
        }
    }

}
