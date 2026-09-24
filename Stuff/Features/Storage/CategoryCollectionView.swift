import SwiftUI

struct CategoryCollectionView: View {
    private let colors: [Color] = [
        Color(red: 0.67, green: 0.64, blue: 0.76),
        Color(red: 0.56, green: 0.67, blue: 0.77),
        Color(red: 0.69, green: 0.56, blue: 0.63),
        Color(red: 0.72, green: 0.73, blue: 0.57),
        Color(red: 0.78, green: 0.67, blue: 0.56),
        Color(red: 0.58, green: 0.72, blue: 0.68),
        Color(red: 0.76, green: 0.65, blue: 0.72),
        Color(red: 0.69, green: 0.69, blue: 0.79)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Categories")
                .font(.system(size: 31, weight: .regular, design: .serif))
                .foregroundStyle(AppPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 39)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(FoodCategory.all.indices, id: \.self) { index in
                    FoodCategoryTile(
                        category: FoodCategory.all[index],
                        color: colors[index % colors.count]
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 19)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FoodCategoryTile: View {
    let category: FoodCategory
    let color: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 39)
                .fill(color)

            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.system(size: 23, weight: .regular, design: .serif))
                    .foregroundStyle(Color(red: 0.19, green: 0.19, blue: 0.20))
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)

                Text("0 Items")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.black.opacity(0.62))

                Spacer(minLength: 8)

                Text(category.emoji)
                    .font(.system(size: 56))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .shadow(color: .black.opacity(0.12), radius: 5, y: 5)
            }
            .padding(20)
        }
        .frame(height: 226)
        .accessibilityElement(children: .combine)
    }
}
