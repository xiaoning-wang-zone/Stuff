#if os(iOS)
import Foundation
import UIKit

enum CapturedPhotoStore {
    enum SaveError: Error {
        case imageEncodingFailed
    }

    @discardableResult
    static func save(
        original: UIImage,
        foreground: UIImage,
        items: [UIImage]
    ) throws -> URL {
        guard let originalData = original.jpegData(compressionQuality: 0.9),
              let foregroundData = foreground.pngData() else {
            throw SaveError.imageEncodingFailed
        }
        let itemData = try items.map { item -> Data in
            guard let data = item.pngData() else { throw SaveError.imageEncodingFailed }
            return data
        }

        let capturesDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Captures", isDirectory: true)
        let photoDirectory = capturesDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)

        do {
            try originalData.write(to: photoDirectory.appendingPathComponent("original.jpg"), options: .atomic)
            try foregroundData.write(to: photoDirectory.appendingPathComponent("foreground.png"), options: .atomic)
            for (index, data) in itemData.enumerated() {
                try data.write(
                    to: photoDirectory.appendingPathComponent("item-\(index + 1).png"),
                    options: .atomic
                )
            }
            return photoDirectory
        } catch {
            try? FileManager.default.removeItem(at: photoDirectory)
            throw error
        }
    }
}
#endif
