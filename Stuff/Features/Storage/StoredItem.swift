import Foundation
import SwiftData

@Model
final class StoredCapture {
    @Attribute(.unique) var id: UUID
    var capturedAt: Date
    var folderName: String

    init(id: UUID, capturedAt: Date, folderName: String) {
        self.id = id
        self.capturedAt = capturedAt
        self.folderName = folderName
    }
}

@Model
final class StoredItem {
    @Attribute(.unique) var id: UUID
    var captureID: UUID
    var itemNumber: Int
    var name: String
    var categoryName: String
    var capturedAt: Date
    var expiresAt: Date?
    var expirySource: String
    var storageNote: String
    var needsReview: Bool

    init(
        id: UUID = UUID(),
        captureID: UUID,
        itemNumber: Int,
        name: String,
        categoryName: String,
        capturedAt: Date,
        expiresAt: Date?,
        expirySource: String,
        storageNote: String,
        needsReview: Bool
    ) {
        self.id = id
        self.captureID = captureID
        self.itemNumber = itemNumber
        self.name = name
        self.categoryName = categoryName
        self.capturedAt = capturedAt
        self.expiresAt = expiresAt
        self.expirySource = expirySource
        self.storageNote = storageNote
        self.needsReview = needsReview
    }

    var imageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Captures", isDirectory: true)
            .appendingPathComponent(captureID.uuidString, isDirectory: true)
            .appendingPathComponent("item-\(itemNumber).png")
    }
}
