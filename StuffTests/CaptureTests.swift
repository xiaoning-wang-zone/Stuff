import XCTest
import UIKit
@testable import Stuff

final class CaptureTests: XCTestCase {
    @MainActor
    private func image(width: CGFloat = 32, height: CGFloat = 16) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image {
            UIColor.red.setFill()
            $0.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @MainActor
    func testDecoderRejectsInvalidDataAndMissingFiles() {
        XCTAssertNil(CaptureImageDecoder.decode(Data()))
        XCTAssertNil(CaptureImageDecoder.decode(Data("not an image".utf8)))
        XCTAssertNil(CaptureImageDecoder.decode(at: URL(fileURLWithPath: "/missing/\(UUID()).png"), maxPixelSize: 100))
    }

    @MainActor
    func testDecoderDownsamplesLargePhotosWithTheirAspectRatio() throws {
        let data = try XCTUnwrap(image(width: 3000, height: 1500).jpegData(compressionQuality: 0.9))
        let result = try XCTUnwrap(CaptureImageDecoder.decode(data))
        let cgImage = try XCTUnwrap(result.image.cgImage)
        XCTAssertEqual(cgImage.width, 2048)
        XCTAssertEqual(cgImage.height, 1024)
        XCTAssertEqual(result.image.imageOrientation, .up)
    }

    @MainActor
    func testFileDecoderUsesRequestedPixelLimit() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("source.png")
        try XCTUnwrap(image(width: 400, height: 200).pngData()).write(to: url)
        let result = try XCTUnwrap(CaptureImageDecoder.decode(at: url, maxPixelSize: 100))
        XCTAssertEqual(result.image.cgImage?.width, 100)
        XCTAssertEqual(result.image.cgImage?.height, 50)
    }

    @MainActor
    func testSaveWritesOriginalForegroundAndNumberedCutouts() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID()
        let photo = image()
        let folder = try CapturedPhotoStore.save(id: id, original: photo, foreground: photo,
                                                items: [photo, photo], directory: directory)
        XCTAssertEqual(folder.lastPathComponent, id.uuidString)
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)),
                       Set(["original.jpg", "foreground.png", "item-1.png", "item-2.png"]))
        for name in ["original.jpg", "foreground.png", "item-1.png", "item-2.png"] {
            let saved = try XCTUnwrap(UIImage(contentsOfFile: folder.appendingPathComponent(name).path))
            XCTAssertEqual(saved.size, photo.size)
        }
    }

    @MainActor
    func testEncodingFailureDoesNotCreateCaptureFolder() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID()
        XCTAssertThrowsError(try CapturedPhotoStore.save(id: id, original: image(), foreground: image(),
                                                       items: [UIImage()], directory: directory)) { error in
            guard case CapturedPhotoStore.SaveError.imageEncodingFailed = error else {
                return XCTFail("Expected imageEncodingFailed, got \(error)")
            }
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent(id.uuidString).path))
    }

    @MainActor
    func testSegmentationRejectsAnEmptyImage() async {
        do {
            _ = try await ForegroundSegmenter.segment(UIImage())
            XCTFail("Expected invalidImage")
        } catch {
            guard case ForegroundSegmenter.SegmentationError.invalidImage = error else {
                return XCTFail("Expected invalidImage, got \(error)")
            }
        }
    }
}
