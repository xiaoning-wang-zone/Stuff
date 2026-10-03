import XCTest
import SwiftData
@testable import Stuff

final class StoredItemStoreTests: XCTestCase {
    @MainActor
    private func context() throws -> ModelContext {
        let schema = Schema([StoredCapture.self, StoredItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    @MainActor
    private func item(captureID: UUID, number: Int = 1) -> StoredItem {
        StoredItem(captureID: captureID, itemNumber: number, name: "Apple", categoryName: "Fruits",
                   capturedAt: Date(timeIntervalSince1970: 0), expiresAt: nil, expirySource: "unknown",
                   storageNote: "", needsReview: true)
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func captureFolder(in directory: URL, id: UUID) throws -> URL {
        let folder = directory.appendingPathComponent(id.uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for name in ["original.jpg", "foreground.png", "item-1.png", "item-2.png"] {
            try Data([1]).write(to: folder.appendingPathComponent(name))
        }
        return folder
    }

    @MainActor
    func testDeletingOneItemKeepsItsSiblingAndCaptureImages() throws {
        let context = try context()
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID()
        let folder = try captureFolder(in: directory, id: id)
        let first = item(captureID: id)
        let second = item(captureID: id, number: 2)
        context.insert(StoredCapture(id: id, capturedAt: .now, folderName: id.uuidString))
        context.insert(first)
        context.insert(second)
        try context.save()

        try StoredItemStore.delete(first, in: context, capturesDirectory: directory)

        XCTAssertEqual(try context.fetch(FetchDescriptor<StoredItem>()).map(\.id), [second.id])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<StoredCapture>()), 1)
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)),
                       Set(["original.jpg", "foreground.png", "item-2.png"]))
    }

    @MainActor
    func testDeletingLastItemRemovesOnlyItsCapture() throws {
        let context = try context()
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID()
        let otherID = UUID()
        let folder = try captureFolder(in: directory, id: id)
        let otherFolder = try captureFolder(in: directory, id: otherID)
        let last = item(captureID: id)
        let other = item(captureID: otherID)
        for captureID in [id, otherID] {
            context.insert(StoredCapture(id: captureID, capturedAt: .now, folderName: captureID.uuidString))
        }
        context.insert(last)
        context.insert(other)
        try context.save()

        try StoredItemStore.delete(last, in: context, capturesDirectory: directory)

        XCTAssertEqual(try context.fetch(FetchDescriptor<StoredItem>()).map(\.id), [other.id])
        XCTAssertEqual(try context.fetch(FetchDescriptor<StoredCapture>()).map(\.id), [otherID])
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: otherFolder.path))
    }

    @MainActor
    func testDeletionSucceedsWhenImageFilesAreAlreadyMissing() throws {
        let context = try context()
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID()
        let last = item(captureID: id)
        context.insert(last)
        context.insert(StoredCapture(id: id, capturedAt: .now, folderName: id.uuidString))
        try context.save()
        try StoredItemStore.delete(last, in: context, capturesDirectory: directory)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<StoredItem>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<StoredCapture>()), 0)
    }

    @MainActor
    func testStoredItemImagePathUsesCaptureIDAndItemNumber() {
        let id = UUID()
        let url = item(captureID: id, number: 3).imageURL
        XCTAssertEqual(url.lastPathComponent, "item-3.png")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, id.uuidString)
        XCTAssertEqual(url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent, "Captures")
    }

    @MainActor
    func testFoodCategoriesHaveUniqueNonemptyIdentifiers() {
        XCTAssertEqual(FoodCategory.all.count, 24)
        XCTAssertEqual(Set(FoodCategory.all.map(\.id)).count, 24)
        XCTAssertTrue(FoodCategory.all.allSatisfy { !$0.name.isEmpty && !$0.emoji.isEmpty })
    }
}
