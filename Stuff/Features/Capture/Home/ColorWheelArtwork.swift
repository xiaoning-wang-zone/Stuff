import SwiftUI

struct ColorWheelArtwork: View {
    let showsOuterDots: Bool

    init(showsOuterDots: Bool = true) {
        self.showsOuterDots = showsOuterDots
    }

    private let segments: [(Color, CGFloat, CGFloat)] = [
        (Color(red: 0.55, green: 0.83, blue: 0.69), 0.01, 0.17),
        (Color(red: 0.68, green: 0.67, blue: 0.89), 0.19, 0.42),
        (Color(red: 0.67, green: 0.85, blue: 1.00), 0.45, 0.60),
        (Color(red: 1.00, green: 0.72, blue: 0.87), 0.63, 0.79),
        (Color(red: 0.88, green: 0.94, blue: 0.00), 0.82, 0.98)
    ]

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                if showsOuterDots {
                    ForEach(0..<48, id: \.self) { index in
                        Capsule()
                            .fill(Color.gray.opacity(0.17))
                            .frame(width: 3, height: 5)
                            .offset(y: -size * 0.48)
                            .rotationEffect(.degrees(Double(index) * 7.5))
                    }
                }

                Circle()
                    .fill(.white)
                    .frame(width: size * 0.77, height: size * 0.77)

                ForEach(segments.indices, id: \.self) { index in
                    Circle()
                        .trim(from: segments[index].1, to: segments[index].2)
                        .stroke(segments[index].0, style: StrokeStyle(lineWidth: size * 0.075))
                        .frame(width: size * 0.66, height: size * 0.66)
                        .rotationEffect(.degrees(-90))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel("Colorful circular artwork")
    }
}
