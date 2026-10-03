import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

enum StoredItemFilter {
    case category(String)
    case day(Date)
}

struct StoredItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredItem.capturedAt, order: .reverse) private var allItems: [StoredItem]
    @State private var deleteError: String?

    let title: String
    let filter: StoredItemFilter

    private var items: [StoredItem] {
        allItems.filter { item in
            switch filter {
            case .category(let categoryName):
                item.categoryName == categoryName
            case .day(let date):
                Calendar.current.isDate(item.capturedAt, inSameDayAs: date)
            }
        }
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            DottedGalleryBackground().ignoresSafeArea()

            GeometryReader { galleryGeometry in
                let availableWidth = min(galleryGeometry.size.width, 620)
                let stickerWidth = min(CGFloat(136), max(CGFloat(72), (availableWidth - 62) / 2 - 16))

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(.system(size: 34, weight: .regular, design: .serif))
                                .foregroundStyle(AppPalette.ink)
                            Text("\(items.count) \(items.count == 1 ? "Item" : "Items")")
                                .font(.system(size: 17))
                                .foregroundStyle(AppPalette.muted)
                        }

                        if items.isEmpty {
                            ContentUnavailableView("No items yet", systemImage: "archivebox")
                                .frame(maxWidth: .infinity)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)],
                                spacing: 30
                            ) {
                                ForEach(items) { item in
                                    NavigationLink {
                                        StoredItemDetailView(item: item)
                                    } label: {
                                        VStack(spacing: 10) {
                                            ItemStickerView(item: item, width: stickerWidth, height: 150, borderWidth: 6)
                                            Text(item.name)
                                                .font(.system(size: 19, weight: .semibold, design: .rounded))
                                                .foregroundStyle(AppPalette.ink)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 4)
                                                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            delete(item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 22)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("")
        .toolbar(.visible, for: .navigationBar)
        .alert("Couldn’t delete item", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "Please try again.")
        }
    }

    private func delete(_ item: StoredItem) {
        do {
            try StoredItemStore.delete(item, in: modelContext)
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

private struct DottedGalleryBackground: View {
    var body: some View {
        Canvas { context, size in
            for x in stride(from: CGFloat(12), through: size.width, by: 24) {
                for y in stride(from: CGFloat(12), through: size.height, by: 24) {
                    let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3))
                    context.fill(dot, with: .color(.black.opacity(0.055)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct StoredItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: StoredItem
    @State private var hasExpiry = false
    @State private var confirmDelete = false
    @State private var itemDeleted = false
    @State private var deleteError: String?

    var body: some View {
        Form {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: item.imageURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
            }
            #endif
            Section("Item") {
                TextField("Name", text: $item.name)
                Picker("Category", selection: $item.categoryName) {
                    Text("Unknown").tag("Unknown")
                    ForEach(FoodCategory.all) { category in
                        Text(category.name).tag(category.name)
                    }
                }
            }
            Section("Expiry") {
                Toggle("Set expiry date", isOn: $hasExpiry)
                if hasExpiry {
                    DatePicker("Date", selection: Binding(
                        get: { item.expiresAt ?? .now },
                        set: { item.expiresAt = $0; item.expirySource = "manual" }
                    ), displayedComponents: .date)
                    Text(item.expirySource == "estimated" ? "AI estimate — verify with the package date." : "Date entered by you")
                        .font(.footnote)
                }
                TextField("Storage assumption", text: $item.storageNote)
            }
        }
        .navigationTitle(item.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    confirmDelete = true
                }
                .popover(isPresented: $confirmDelete, attachmentAnchor: .rect(.bounds)) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Delete \(item.name)?")
                            .font(.headline)
                        Text("Its saved photo will also be removed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Delete item", role: .destructive) { deleteItem() }
                        Button("Cancel") { confirmDelete = false }
                    }
                    .padding(20)
                    .frame(width: 260)
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
        .alert("Couldn’t delete item", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "Please try again.")
        }
        .onAppear { hasExpiry = item.expiresAt != nil }
        .onChange(of: confirmDelete) { _, isPresented in
            if !isPresented && itemDeleted { dismiss() }
        }
        .onChange(of: hasExpiry) { _, enabled in
            if enabled && item.expiresAt == nil {
                item.expiresAt = .now
                item.expirySource = "manual"
            } else if !enabled {
                item.expiresAt = nil
                item.expirySource = "unknown"
            }
        }
        .onDisappear { try? modelContext.save() }
    }

    private func deleteItem() {
        do {
            try StoredItemStore.delete(item, in: modelContext)
            itemDeleted = true
            confirmDelete = false
        } catch {
            confirmDelete = false
            deleteError = error.localizedDescription
        }
    }
}
