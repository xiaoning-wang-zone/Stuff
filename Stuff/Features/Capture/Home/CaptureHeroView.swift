import SwiftUI

struct CaptureHeroView: View {
    let now: Date
    let width: CGFloat
    let hidesText: Bool
    let onCapture: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CaptureHeroTextView(now: now)
                .opacity(hidesText ? 0 : 1)

            Button(action: onCapture) {
                ColorWheelArtwork()
                    .frame(width: min(width * 0.70, 296), height: min(width * 0.70, 296))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open camera")
            .padding(.top, 51)
            .padding(.bottom, 61)
        }
    }
}

struct CaptureHeroTextView: View {
    let now: Date

    var body: some View {
        VStack(spacing: 0) {
            Text(now, format: .dateTime.month(.abbreviated).day())
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(AppPalette.muted)
                .padding(.top, 2)

            Text(greeting)
                .font(.system(size: 39, weight: .regular, design: .serif))
                .foregroundStyle(AppPalette.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .padding(.top, 7)

            Text("Start your day with a new word!")
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundStyle(AppPalette.muted)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .padding(.horizontal, 18)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }
}
