import SwiftUI

struct CaptureFrameView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                CaptureCorners()
                    .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))

                Text("Please place the object\nwithin the frame")
                    .font(.system(size: 19, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)
                    .shadow(color: .black.opacity(0.5), radius: 8)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CaptureCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 24
        let arm: CGFloat = 32
        let left = rect.minX
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY

        return Path { path in
            path.move(to: CGPoint(x: left, y: top + radius + arm))
            path.addLine(to: CGPoint(x: left, y: top + radius))
            path.addQuadCurve(to: CGPoint(x: left + radius, y: top), control: CGPoint(x: left, y: top))
            path.addLine(to: CGPoint(x: left + radius + arm, y: top))

            path.move(to: CGPoint(x: right - radius - arm, y: top))
            path.addLine(to: CGPoint(x: right - radius, y: top))
            path.addQuadCurve(to: CGPoint(x: right, y: top + radius), control: CGPoint(x: right, y: top))
            path.addLine(to: CGPoint(x: right, y: top + radius + arm))

            path.move(to: CGPoint(x: right, y: bottom - radius - arm))
            path.addLine(to: CGPoint(x: right, y: bottom - radius))
            path.addQuadCurve(to: CGPoint(x: right - radius, y: bottom), control: CGPoint(x: right, y: bottom))
            path.addLine(to: CGPoint(x: right - radius - arm, y: bottom))

            path.move(to: CGPoint(x: left + radius + arm, y: bottom))
            path.addLine(to: CGPoint(x: left + radius, y: bottom))
            path.addQuadCurve(to: CGPoint(x: left, y: bottom - radius), control: CGPoint(x: left, y: bottom))
            path.addLine(to: CGPoint(x: left, y: bottom - radius - arm))
        }
    }
}
