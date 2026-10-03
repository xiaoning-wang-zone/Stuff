#if os(iOS)
import AVFoundation
import SwiftUI
import UIKit

/// A preview layer fills its SwiftUI view, including the area behind the shutter controls.
struct CameraPicker: UIViewRepresentable {
    let onCapture: (UIImage) -> Void
    let captureRequest: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.session = context.coordinator.session
        view.previewLayer.videoGravity = .resizeAspectFill
        context.coordinator.start()
        return view
    }

    func updateUIView(_ view: CameraPreviewView, context: Context) {
        guard captureRequest > context.coordinator.lastCaptureRequest else { return }
        context.coordinator.lastCaptureRequest = captureRequest
        context.coordinator.takePhoto()
    }

    static func dismantleUIView(_ view: CameraPreviewView, coordinator: Coordinator) {
        coordinator.stop()
        view.previewLayer.session = nil
    }

    nonisolated final class Coordinator: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
        let session = AVCaptureSession()
        private let photoOutput = AVCapturePhotoOutput()
        private let sessionQueue = DispatchQueue(label: "Stuff.camera.session")
        private let onCapture: (UIImage) -> Void
        var lastCaptureRequest = 0
        private var isConfigured = false

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func start() {
            sessionQueue.async { [self] in
                guard !session.isRunning else { return }
                if !isConfigured {
                    session.beginConfiguration()
                    session.sessionPreset = .photo
                    defer { session.commitConfiguration() }

                    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                          let input = try? AVCaptureDeviceInput(device: camera),
                          session.canAddInput(input),
                          session.canAddOutput(photoOutput) else { return }

                    session.addInput(input)
                    session.addOutput(photoOutput)
                    do {
                        try camera.lockForConfiguration()
                        if camera.isFocusModeSupported(.continuousAutoFocus) {
                            camera.focusMode = .continuousAutoFocus
                        }
                        if camera.isExposureModeSupported(.continuousAutoExposure) {
                            camera.exposureMode = .continuousAutoExposure
                        }
                        camera.unlockForConfiguration()
                    } catch {
                        // Keep the device's existing camera settings.
                    }
                    isConfigured = true
                }
                session.startRunning()
            }
        }

        func stop() {
            sessionQueue.async { [self] in
                if session.isRunning { session.stopRunning() }
            }
        }

        func takePhoto() {
            sessionQueue.async { [self] in
                guard isConfigured, session.isRunning else { return }
                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = .speed
                settings.flashMode = photoOutput.supportedFlashModes.contains(.auto) ? .auto : .off
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }

        func photoOutput(
            _ output: AVCapturePhotoOutput,
            didFinishProcessingPhoto photo: AVCapturePhoto,
            error: Error?
        ) {
            guard error == nil,
                  let data = photo.fileDataRepresentation(),
                  let decoded = CaptureImageDecoder.decode(data) else { return }
            DispatchQueue.main.async { [onCapture] in onCapture(decoded.image) }
        }
    }
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
#endif
