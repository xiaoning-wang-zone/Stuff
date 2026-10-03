import SwiftUI
import SwiftData

struct DateCollectionView: View {
    @Query(sort: \StoredItem.capturedAt, order: .reverse) private var items: [StoredItem]

    let now: Date
    let onCapture: () -> Void

    private let cardColors: [Color] = [
        Color(red: 0.76, green: 0.71, blue: 0.85),
        Color(red: 0.78, green: 0.75, blue: 0.67),
        Color(red: 0.72, green: 0.77, blue: 0.64),
        Color(red: 0.70, green: 0.78, blue: 0.80)
    ]

    private var months: [CaptureMonth] {
        let calendar = Calendar.current
        var grouped = Dictionary(grouping: items) { calendar.startOfDay(for: $0.capturedAt) }
        let today = calendar.startOfDay(for: now)
        if grouped[today] == nil { grouped[today] = [] }

        let days = grouped.map { CaptureDay(date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
        let byMonth = Dictionary(grouping: days) {
            calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date
        }
        return byMonth.map { CaptureMonth(date: $0.key, days: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(months) { month in
                VStack(alignment: .leading, spacing: 16) {
                    Text(month.date, format: .dateTime.month(.wide).year())
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundStyle(AppPalette.ink)
                        .padding(.leading, 2)

                    ForEach(month.days) { day in
                        if day.items.isEmpty {
                            Button(action: onCapture) { dateCard(for: day) }
                                .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                StoredItemListView(
                                    title: day.date.formatted(.dateTime.month(.abbreviated).day()),
                                    filter: .day(day.date)
                                )
                            } label: {
                                dateCard(for: day)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func dateCard(for day: CaptureDay) -> some View {
        let colorIndex = abs(Calendar.current.dateComponents([.day], from: day.date, to: now).day ?? 0)
        return VStack(alignment: .leading, spacing: 4) {
            Text(day.date, format: .dateTime.month(.abbreviated).day())
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(AppPalette.ink)

            Text(day.items.isEmpty ? "Scan your shopping." : "\(day.items.count) \(day.items.count == 1 ? "Item" : "Items")")
                .font(.system(size: 17))
                .foregroundStyle(AppPalette.ink.opacity(0.75))

            Spacer(minLength: 8)

            if !day.items.isEmpty {
                GeometryReader { cardGeometry in
                    let visibleCount = min(day.items.count, 4)
                    let overflowWidth: CGFloat = day.items.count > 4 ? 30 : 0
                    let stickerWidth = min(
                        CGFloat(56),
                        max(CGFloat(30), (cardGeometry.size.width - overflowWidth - CGFloat(visibleCount - 1) * 8) / CGFloat(visibleCount) - 10)
                    )
                    HStack(spacing: 8) {
                        ForEach(Array(day.items.prefix(4))) { item in
                            ItemStickerView(item: item, width: stickerWidth, height: 74, borderWidth: 3)
                                .frame(maxWidth: .infinity)
                        }
                        if day.items.count > 4 {
                            Text("+\(day.items.count - 4)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
                .frame(height: 86)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background(cardColors[colorIndex % cardColors.count], in: RoundedRectangle(cornerRadius: 43))
        .accessibilityLabel(day.items.isEmpty ? "Open camera" : "\(day.items.count) saved items on \(day.date.formatted(date: .abbreviated, time: .omitted))")
    }
}

private struct CaptureDay: Identifiable {
    let date: Date
    let items: [StoredItem]
    var id: Date { date }
}

private struct CaptureMonth: Identifiable {
    let date: Date
    let days: [CaptureDay]
    var id: Date { date }
}
