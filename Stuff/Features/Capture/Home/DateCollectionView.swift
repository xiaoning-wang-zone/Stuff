import SwiftUI

struct DateCollectionView: View {
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(now, format: .dateTime.month(.wide))
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(AppPalette.ink)
                .padding(.leading, 22)

            VStack(alignment: .leading, spacing: 6) {
                Text(now, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color(red: 0.27, green: 0.28, blue: 0.29))

                Text("Scan your shopping.")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(red: 0.42, green: 0.43, blue: 0.44))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 23)
            .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
            .background(AppPalette.card, in: RoundedRectangle(cornerRadius: 43))

            RoundedRectangle(cornerRadius: 43)
                .fill(Color(red: 0.95, green: 0.94, blue: 0.92))
                .frame(height: 150)
        }
        .padding(.horizontal, 20)
    }
}
