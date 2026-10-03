#if os(iOS)
import Foundation
import ImageIO
import UIKit

nonisolated enum CaptureImageDecoder {
    struct Result: @unchecked Sendable {
        let image: UIImage
    }

    /// Decode only the pixels used by review, segmentation, and local storage.
    static func decode(_ data: Data) -> Result? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        return thumbnail(from: source, maxPixelSize: 2048)
    }

    static func decode(at url: URL, maxPixelSize: Int) -> Result? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }
        return thumbnail(from: source, maxPixelSize: maxPixelSize)
    }

    private static func thumbnail(from source: CGImageSource, maxPixelSize: Int) -> Result? {
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source, 0, thumbnailOptions as CFDictionary
        ) else {
            return nil
        }
        return Result(image: UIImage(cgImage: thumbnail))
    }
}
#endif
