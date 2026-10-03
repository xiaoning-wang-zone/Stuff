import SwiftUI
import SwiftData

struct StorageView: View {
    @Query(sort: \StoredItem.capturedAt, order: .reverse) private var items: [StoredItem]

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        if !items.isEmpty {
                            Text("\(items.count) saved \(items.count == 1 ? "item" : "items")")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 39)
                        }
                        if items.contains(where: { $0.categoryName == "Unknown" }) {
                            NavigationLink("Review uncategorized items") {
                                StoredItemListView(title: "Uncategorized", filter: .category("Unknown"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 39)
                        }
                        CategoryCollectionView(items: items)
                    }
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
                .defaultScrollAnchor(.top, for: .initialOffset)
            }
        }
    }
}
