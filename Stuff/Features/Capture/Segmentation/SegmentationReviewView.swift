#if os(iOS)
import SwiftUI
import SwiftData
import UIKit

struct SegmentationReviewView: View {
    @Environment(\.modelContext) private var modelContext
    let image: UIImage
    let onRetake: () -> Void
    let onSaved: () -> Void

    @State private var segmentation: ForegroundSegmenter.Output?
    @State private var originalOpacity = 1.0
    @State private var selectedItemIndex: Int?
    @State private var errorMessage: String?
    @State private var showsSaveError = false
    @State private var isSaving = false
    @State private var isAnalyzing = false
    @State private var drafts: [ItemDraft] = []
    @State private var showingItemReview = false
    @State private var saveErrorMessage = "Please try again."
    @State private var captureDate = Date.now

    private let background = Color(red: 0.48, green: 0.40, blue: 0.32)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background.ignoresSafeArea()

                GeometryReader { canvas in
                    ZStack {
                        Image(uiImage: segmentation?.sourceImage ?? image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: canvas.size.width, height: canvas.size.height)
                            .clipped()
                            .opacity(originalOpacity)

                        if let segmentation {
                            Image(uiImage: displayedCutout(from: segmentation))
                                .resizable()
                                .aspectRatio(contentMode: selectedItemIndex == nil ? .fill : .fit)
                                .frame(width: canvas.size.width, height: canvas.size.height)
                                .clipped()
                        }
                    }
                    .frame(width: canvas.size.width, height: canvas.size.height)
                    .clipped()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 25)
                        .padding(.top, 24)

                    Spacer()

                    if segmentation == nil || isAnalyzing {
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
        .sheet(isPresented: $showingItemReview) { itemReviewSheet }
        .alert("Couldn’t save items", isPresented: $showsSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
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
                Text(isAnalyzing ? "Identifying items on this iPhone…" : "Finding items…")
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

            Button { showingItemReview = true } label: {
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
            .disabled(segmentation == nil || isAnalyzing || isSaving)
            .accessibilityLabel("Review and save items")

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
            isAnalyzing = true
            drafts = await ItemAnalyzer.analyze(output.itemImages, capturedAt: captureDate)
            isAnalyzing = false
            guard !Task.isCancelled else { return }
            showingItemReview = true
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        guard let segmentation, drafts.count == segmentation.itemImages.count else { return }
        isSaving = true
        let captureID = UUID()
        let capturedAt = captureDate
        do {
            let folder = try CapturedPhotoStore.save(
                id: captureID,
                original: segmentation.sourceImage,
                foreground: segmentation.foregroundImage,
                items: segmentation.itemImages
            )
            let capture = StoredCapture(id: captureID, capturedAt: capturedAt, folderName: captureID.uuidString)
            modelContext.insert(capture)
            let items = drafts.enumerated().map { index, draft in
                StoredItem(
                    captureID: captureID,
                    itemNumber: index + 1,
                    name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown item" : draft.name,
                    categoryName: draft.categoryName,
                    capturedAt: capturedAt,
                    expiresAt: draft.hasExpiryEstimate ? draft.expiresAt : nil,
                    expirySource: draft.hasExpiryEstimate ? draft.expirySource : "unknown",
                    storageNote: draft.storageNote,
                    needsReview: draft.name == "Unknown item" || draft.categoryName == "Unknown" || !draft.hasExpiryEstimate
                )
            }
            items.forEach { modelContext.insert($0) }
            do {
                try modelContext.save()
                onSaved()
            } catch {
                items.forEach { modelContext.delete($0) }
                modelContext.delete(capture)
                try? FileManager.default.removeItem(at: folder)
                throw error
            }
        } catch {
            isSaving = false
            saveErrorMessage = error.localizedDescription
            showsSaveError = true
        }
    }

    private var itemReviewSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Check each suggestion before saving. Dates are estimates based on the photo and stated storage condition; use the package date when you have one.")
                        .font(.footnote)
                }

                ForEach(drafts.indices, id: \.self) { index in
                    Section("Item \(index + 1)") {
                        HStack {
                            Image(uiImage: drafts[index].image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 74, height: 74)
                            TextField("Item name", text: $drafts[index].name)
                        }

                        Picker("Category", selection: $drafts[index].categoryName) {
                            Text("Unknown").tag("Unknown")
                            ForEach(FoodCategory.all) { category in
                                Text(category.name).tag(category.name)
                            }
                        }

                        Toggle("Set expiry date", isOn: Binding(
                            get: { drafts[index].hasExpiryEstimate },
                            set: { enabled in
                                drafts[index].hasExpiryEstimate = enabled
                                if enabled && drafts[index].expiresAt == nil {
                                    drafts[index].expiresAt = .now
                                    drafts[index].expirySource = "manual"
                                }
                            }
                        ))
                        if drafts[index].hasExpiryEstimate {
                            DatePicker(
                                "Estimated expiry",
                                selection: Binding(
                                    get: { drafts[index].expiresAt ?? .now },
                                    set: {
                                        drafts[index].expiresAt = $0
                                        drafts[index].expirySource = "manual"
                                    }
                                ),
                                displayedComponents: .date
                            )
                            TextField("Storage assumption", text: $drafts[index].storageNote)
                        }
                    }
                }
            }
            .navigationTitle("Review items")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingItemReview = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving || drafts.isEmpty)
                }
            }
        }
    }
}
#endif
