import SwiftUI

struct StorageView: View {
    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                CategoryCollectionView()
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
            }
            .defaultScrollAnchor(.top, for: .initialOffset)
        }
    }
}
