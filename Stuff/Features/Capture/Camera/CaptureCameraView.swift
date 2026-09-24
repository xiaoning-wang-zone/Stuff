#if os(iOS)
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct CaptureCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasCameraAccess = false
    @State private var cameraMessage = "Preparing camera…"
    @State private var permissionDenied = false
    @State private var captureRequest = 0
    @State private var cameraSessionID = UUID()
    @State private var photoForSegmentation: CapturePhoto?
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if hasCameraAccess {
                    CameraPicker(onCapture: openSegmentation, captureRequest: captureRequest)
                        .id(cameraSessionID)
                        .ignoresSafeArea()
                } else {
                    unavailableView
                }

                VStack(spacing: 0) {
                    HStack {
                        Text(Date.now, format: .dateTime.month(.abbreviated).day())
                            .font(.system(size: 30, weight: .regular, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 6)
                        Spacer()
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 24)

                    Spacer(minLength: 32)

                    if hasCameraAccess {
                        CaptureFrameView()
                            .frame(
                                width: min(geometry.size.width * 0.78, 440),
                                height: min(geometry.size.height * 0.47, 530)
                            )
                    } else {
                        Color.clear
                            .frame(height: min(geometry.size.height * 0.47, 530))
                    }

                    Spacer(minLength: 32)

                    controls
                        .padding(.horizontal, 34)
                        .padding(.bottom, 30)
                }

                if let photoForSegmentation {
                    SegmentationReviewView(
                        image: photoForSegmentation.image,
                        onRetake: {
                            self.photoForSegmentation = nil
                            selectedPhoto = nil
                            captureRequest = 0
                            cameraSessionID = UUID()
                        },
                        onSaved: { dismiss() }
                    )
                    .zIndex(1)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .preferredColorScheme(.dark)
        .task { await prepareCamera() }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                openSegmentation(image)
            }
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill")
                .font(.system(size: 34))
            Text(cameraMessage)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)

            if permissionDenied {
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 4)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 45)
    }

    private var controls: some View {
        HStack {
            Button { dismiss() } label: {
                roundControl("xmark")
            }
            .accessibilityLabel("Close camera")

            Spacer()

            Button { captureRequest += 1 } label: {
                ColorWheelArtwork(showsOuterDots: false)
                    .frame(width: 104, height: 104)
                    .background(Circle().fill(.white))
            }
            .buttonStyle(.plain)
            .disabled(!hasCameraAccess)
            .accessibilityLabel("Take photo")

            Spacer()

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                roundControl("photo")
            }
            .accessibilityLabel("Choose a photo")
        }
        .buttonStyle(.plain)
    }

    private func roundControl(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
    }

    private func prepareCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraMessage = "Camera is unavailable on this device. You can choose a photo instead."
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraAccess = true
        case .notDetermined:
            hasCameraAccess = await AVCaptureDevice.requestAccess(for: .video)
            if !hasCameraAccess {
                permissionDenied = true
                cameraMessage = "Allow camera access in Settings to scan your shopping."
            }
        case .denied, .restricted:
            permissionDenied = true
            cameraMessage = "Allow camera access in Settings to scan your shopping."
        @unknown default:
            cameraMessage = "Camera is unavailable right now."
        }
    }

    private func openSegmentation(_ image: UIImage) {
        photoForSegmentation = CapturePhoto(image: image)
    }
}

private struct CapturePhoto {
    let image: UIImage
}
#else
import SwiftUI

struct CaptureCameraView: View {
    var body: some View {
        Text("Camera capture is available on iPhone.")
    }
}
#endif
