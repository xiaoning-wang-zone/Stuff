#if os(iOS)
import CoreImage
import UIKit
import Vision

nonisolated enum ForegroundSegmenter {
    struct Output: @unchecked Sendable {
        let sourceImage: UIImage
        let foregroundImage: UIImage
        let itemImages: [UIImage]
    }

    enum SegmentationError: LocalizedError {
        case invalidImage
        case noForeground
        case imageRenderingFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "This photo could not be read. Please choose another photo."
            case .noForeground:
                return "No separate items were found. Try a photo with the items clearly visible."
            case .imageRenderingFailed:
                return "The item cutouts could not be created. Please try again."
            }
        }
    }

    nonisolated static func segment(_ image: UIImage) async throws -> Output {
        try await Task.detached(priority: .userInitiated) {
            try Self.segmentSynchronously(image)
        }.value
    }

    private nonisolated static func segmentSynchronously(_ image: UIImage) throws -> Output {
        let source = try normalizedImage(image)
        guard let cgImage = source.cgImage else { throw SegmentationError.invalidImage }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])

        guard let observation = request.results?.first,
              !observation.allInstances.isEmpty else {
            throw SegmentationError.noForeground
        }

        let context = CIContext()
        let foregroundBuffer = try observation.generateMaskedImage(
            ofInstances: observation.allInstances,
            from: handler,
            croppedToInstancesExtent: false
        )
        let foregroundImage = try renderedImage(from: foregroundBuffer, context: context)

        let itemImages = try observation.allInstances.map { index in
            let buffer = try observation.generateMaskedImage(
                ofInstances: IndexSet(integer: index),
                from: handler,
                croppedToInstancesExtent: true
            )
            return try renderedImage(from: buffer, context: context)
        }

        return Output(
            sourceImage: source,
            foregroundImage: foregroundImage,
            itemImages: itemImages
        )
    }

    private nonisolated static func normalizedImage(_ image: UIImage) throws -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        guard pixelWidth > 0, pixelHeight > 0 else { throw SegmentationError.invalidImage }

        let scale = min(1, 2048 / max(pixelWidth, pixelHeight))
        let size = CGSize(width: pixelWidth * scale, height: pixelHeight * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private nonisolated static func renderedImage(
        from buffer: CVPixelBuffer,
        context: CIContext
    ) throws -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw SegmentationError.imageRenderingFailed
        }
        return UIImage(cgImage: cgImage)
    }
}
#endif
