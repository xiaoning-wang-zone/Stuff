import SwiftUI

#if os(iOS)
import UIKit
#endif

struct ItemStickerView: View {
    let item: StoredItem
    let width: CGFloat
    let height: CGFloat
    let borderWidth: CGFloat

    #if os(iOS)
    @State private var image: UIImage?
    #endif

    var body: some View {
        Group {
            #if os(iOS)
            if let image {
                ZStack {
                    ForEach(0..<12, id: \.self) { index in
                        stickerLayer(image, white: true)
                            .offset(
                                x: cos(Double(index) * .pi / 6) * borderWidth,
                                y: sin(Double(index) * .pi / 6) * borderWidth
                            )
                    }
                    stickerLayer(image, white: false)
                }
                .shadow(color: .black.opacity(0.12), radius: 5, y: 4)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 34))
                    .foregroundStyle(AppPalette.muted)
                    .frame(width: width, height: height)
            }
            #else
            Image(systemName: "photo")
                .font(.system(size: 34))
                .foregroundStyle(AppPalette.muted)
                .frame(width: width, height: height)
            #endif
        }
        .frame(maxWidth: .infinity)
        .padding(borderWidth + 2)
        #if os(iOS)
        .task(id: item.imageURL) {
            let url = item.imageURL
            let decoded = await Task.detached(priority: .utility) {
                CaptureImageDecoder.decode(at: url, maxPixelSize: 480)
            }.value
            guard !Task.isCancelled else { return }
            image = decoded?.image
        }
        #endif
    }

    #if os(iOS)
    private func stickerLayer(_ image: UIImage, white: Bool) -> some View {
        Image(uiImage: image)
            .renderingMode(white ? .template : .original)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .foregroundStyle(white ? .white : .clear)
    }
    #endif
}
