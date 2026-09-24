import SwiftUI

struct CaptureHomeView: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var isCameraPresented = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            GeometryReader { geometry in
                ZStack {
                    AppPalette.background.ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 26)
                            CaptureHeroView(
                                now: timeline.date,
                                width: geometry.size.width,
                                hidesText: scrollOffset >= 26,
                                onCapture: { isCameraPresented = true }
                            )
                            DateCollectionView(now: timeline.date)
                        }
                        .frame(maxWidth: 620)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 220)
                    }
                    .defaultScrollAnchor(.top, for: .initialOffset)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        max(0, geometry.contentOffset.y + geometry.contentInsets.top)
                    } action: { _, newOffset in
                        scrollOffset = newOffset
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .overlay(alignment: .top) {
                    if scrollOffset >= 26 && stickyTextOpacity > 0 {
                        CaptureHeroTextView(now: timeline.date)
                            .frame(maxWidth: .infinity)
                            .background(AppPalette.background)
                            .opacity(stickyTextOpacity)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CaptureCameraView()
        }
    }

    private var stickyTextOpacity: Double {
        let fadeProgress = min(max((scrollOffset - 46) / 80, 0), 1)
        return Double(1 - fadeProgress)
    }
}
