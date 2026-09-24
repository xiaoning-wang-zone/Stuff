#if os(iOS)
import SwiftUI
import UIKit

struct SegmentationReviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onSaved: () -> Void

    @State private var segmentation: ForegroundSegmenter.Output?
    @State private var originalOpacity = 1.0
    @State private var selectedItemIndex: Int?
    @State private var errorMessage: String?
    @State private var showsSaveError = false
    @State private var isSaving = false

    private let background = Color(red: 0.48, green: 0.40, blue: 0.32)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background.ignoresSafeArea()

                Image(uiImage: segmentation?.sourceImage ?? image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(originalOpacity)

                if let segmentation {
                    Image(uiImage: displayedCutout(from: segmentation))
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 25)
                        .padding(.top, 24)

                    Spacer()

                    if segmentation == nil {
                        processingMessage
                            .padding(.horizontal, 28)
                    } else if let selectedItemIndex, let segmentation {
                        Text("Item \(selectedItemIndex + 1) of \(segmentation.itemImages.count)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.35), in: Capsule())
                    }

                    Spacer()

                    controls
                        .padding(.horizontal, 34)
                        .padding(.bottom, 30)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .preferredColorScheme(.dark)
        .task { await segmentPhoto() }
        .alert("Couldn’t save photo", isPresented: $showsSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please try again.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            Text("Categories")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(.white)

            Spacer()

            Button {
                selectedItemIndex = nil
                withAnimation(.easeInOut(duration: 0.35)) {
                    originalOpacity = originalOpacity < 0.5 ? 1 : 0
                }
            } label: {
                Image(systemName: "photo")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.5)))
            }
            .buttonStyle(.plain)
            .disabled(segmentation == nil)
            .accessibilityLabel(originalOpacity < 0.5 ? "Show original photo" : "Show segmented items")
        }
    }

    private var processingMessage: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 26))
                Text(errorMessage)
                    .multilineTextAlignment(.center)
            } else {
                ProgressView()
                    .tint(.white)
                Text("Finding items…")
            }
        }
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(.white)
        .padding(20)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20))
    }

    private var controls: some View {
        HStack {
            Button(action: onRetake) {
                secondaryControl("arrow.uturn.backward")
            }
            .accessibilityLabel("Retake or choose another photo")

            Spacer()

            Button(action: save) {
                Group {
                    if isSaving {
                        ProgressView().tint(AppPalette.orange)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(AppPalette.orange)
                    }
                }
                .frame(width: 104, height: 104)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15), in: Circle())
            }
            .disabled(segmentation == nil || isSaving)
            .accessibilityLabel("Save segmented items")

            Spacer()

            Button(action: showNextItem) {
                secondaryControl("crop.rotate")
            }
            .disabled(segmentation == nil)
            .accessibilityLabel("Review individual items")
        }
        .buttonStyle(.plain)
    }

    private func secondaryControl(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 25, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.35)))
    }

    private func displayedCutout(from result: ForegroundSegmenter.Output) -> UIImage {
        guard let selectedItemIndex else { return result.foregroundImage }
        return result.itemImages[selectedItemIndex]
    }

    private func showNextItem() {
        guard let segmentation, !segmentation.itemImages.isEmpty else { return }
        selectedItemIndex = selectedItemIndex.map {
            ($0 + 1) % segmentation.itemImages.count
        } ?? 0
        withAnimation(.easeInOut(duration: 0.3)) {
            originalOpacity = 0
        }
    }

    private func segmentPhoto() async {
        do {
            let output = try await ForegroundSegmenter.segment(image)
            guard !Task.isCancelled else { return }
            segmentation = output
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 1.2)) {
                originalOpacity = 0
            }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        guard let segmentation else { return }
        isSaving = true
        do {
            try CapturedPhotoStore.save(
                original: segmentation.sourceImage,
                foreground: segmentation.foregroundImage,
                items: segmentation.itemImages
            )
            onSaved()
        } catch {
            isSaving = false
            showsSaveError = true
        }
    }
}
#endif
