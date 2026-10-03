import SwiftUI
import SwiftData

private enum AppTab: Hashable {
    case capture
    case storage
    case inspiration
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .capture

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Capture", systemImage: "camera.aperture", value: AppTab.capture) {
                CaptureHomeView()
            }

            Tab("Storage", systemImage: "archivebox", value: AppTab.storage) {
                StorageView()
            }

            Tab("Inspiration", systemImage: "sparkles", value: AppTab.inspiration) {
                InspirationView()
            }
        }
        .tint(AppPalette.orange)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StoredCapture.self, StoredItem.self], inMemory: true)
}
