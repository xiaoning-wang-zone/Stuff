import Foundation
import SwiftData

@MainActor
enum StoredItemStore {
    static func delete(_ item: StoredItem, in context: ModelContext) throws {
        let captureID = item.captureID
        let itemURL = item.imageURL
        let siblingDescriptor = FetchDescriptor<StoredItem>(
            predicate: #Predicate { $0.captureID == captureID }
        )
        let hasOtherItems = try context.fetch(siblingDescriptor).contains { $0.id != item.id }

        let capture: StoredCapture?
        if hasOtherItems {
            capture = nil
        } else {
            let captureDescriptor = FetchDescriptor<StoredCapture>(
                predicate: #Predicate { $0.id == captureID }
            )
            capture = try context.fetch(captureDescriptor).first
        }

        context.delete(item)
        if let capture { context.delete(capture) }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        // Remove the whole capture only when its last item is gone.
        let imageOrCaptureURL = hasOtherItems ? itemURL : itemURL.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: imageOrCaptureURL)
    }
}
