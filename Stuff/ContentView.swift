import SwiftUI

private enum AppTab: Hashable {
    case capture
    case storage
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
        }
        .tint(AppPalette.orange)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
