import SwiftUI
import SwiftData

#if os(iOS)
private enum InspirationStyle {
    static let background = Color(red: 0.10, green: 0.15, blue: 0.23)
    static let card = Color(red: 0.16, green: 0.22, blue: 0.31)
    static let accent = Color(red: 1.0, green: 0.73, blue: 0.37)
}

struct InspirationView: View {
    @Query(sort: \StoredItem.capturedAt, order: .reverse) private var items: [StoredItem]
    @State private var selectedIDs: Set<UUID> = []
    @State private var isGenerating = false
    @State private var result: RecipeResult?
    @State private var errorMessage: String?

    private var selectedItems: [StoredItem] {
        items.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            InspirationStyle.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Inspiration")
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.top, 24)

                    Text(items.isEmpty
                         ? "Save something in Storage to get started."
                         : "Choose ingredients for your next meal. Drag them around.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.top, 8)

                    if items.isEmpty {
                        emptyState
                    } else {
                        floatingStage
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !selectedItems.isEmpty {
                generateButton
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(InspirationStyle.background.opacity(0.96))
            }
        }
        .sheet(item: $result) { recipe in
            RecipeResultView(recipe: recipe)
                .preferredColorScheme(.light)
        }
        .alert("Couldn’t generate a recipe", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .onChange(of: items.map(\.id)) { _, currentIDs in
            selectedIDs.formIntersection(Set(currentIDs))
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(InspirationStyle.accent)
            Text("Your saved items will float here")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)
            Text("Capture an item, then come back to build a meal.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 90)
    }

    private var floatingStage: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(InspirationStyle.card.gradient)
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let column = index % 2
                        let row = index / 2
                        let phase = Double(index) * 1.9
                        let x = geometry.size.width * (column == 0 ? 0.27 : 0.73)
                            + sin(time * 0.7 + phase) * 8
                        let y = CGFloat(row) * 170 + 96
                            + cos(time * 0.55 + phase) * 9

                        FloatingIngredientView(
                            item: item,
                            isSelected: selectedIDs.contains(item.id)
                        ) {
                            if selectedIDs.contains(item.id) {
                                selectedIDs.remove(item.id)
                            } else {
                                selectedIDs.insert(item.id)
                            }
                        }
                        .position(x: x, y: y)
                        .zIndex(selectedIDs.contains(item.id) ? 1 : 0)
                    }
                }
            }
        }
        .frame(height: CGFloat((items.count + 1) / 2) * 170 + 30)
        .clipShape(RoundedRectangle(cornerRadius: 34))
    }

    private var generateButton: some View {
        Button {
            let ingredients = selectedItems.map(\.name)
            guard !ingredients.isEmpty else { return }
            isGenerating = true
            Task {
                defer { isGenerating = false }
                do {
                    result = try await RecipeGenerator.generate(ingredients: ingredients)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView().tint(InspirationStyle.background)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "Creating your recipe…" : "Generate Recipe")
                if !isGenerating {
                    Text("\(selectedItems.count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(InspirationStyle.background.opacity(0.12), in: Capsule())
                }
            }
            .font(.headline)
            .foregroundStyle(InspirationStyle.background)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(InspirationStyle.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isGenerating)
    }
}

private struct FloatingIngredientView: View {
    let item: StoredItem
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var settledOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 2) {
            ItemStickerView(
                item: item,
                width: 102,
                height: 102,
                borderWidth: isSelected ? 6 : 2.5
            )
            .frame(width: 120, height: 114)
            .shadow(color: .white.opacity(isSelected ? 0.85 : 0), radius: isSelected ? 15 : 0)

            Text(item.name)
                .font(.subheadline.weight(isSelected ? .bold : .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 138, height: 42)
        }
        .frame(width: 140, height: 158)
        .contentShape(Rectangle())
        .offset(
            x: settledOffset.width + dragOffset.width,
            y: settledOffset.height + dragOffset.height
        )
        .onTapGesture(perform: onSelect)
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    settledOffset.width += value.translation.width
                    settledOffset.height += value.translation.height
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityAction(named: "Select") { onSelect() }
    }
}

private struct RecipeResultView: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: RecipeResult

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: recipe.canMakeMeal ? "fork.knife.circle.fill" : "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(AppPalette.orange)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(recipe.title.isEmpty ? "Your meal idea" : recipe.title)
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundStyle(AppPalette.ink)
                        Text(recipe.summary)
                            .font(.body)
                            .foregroundStyle(AppPalette.muted)
                    }

                    sectionTitle("From your Storage")
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(recipe.selectedIngredients.enumerated()), id: \.offset) { _, name in
                            Label(name, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(AppPalette.ink)
                        }
                    }

                    if recipe.canMakeMeal {
                        if !recipe.additionalIngredients.isEmpty {
                            sectionTitle("Also needed")
                            Text(recipe.additionalIngredients.joined(separator: ", "))
                                .foregroundStyle(AppPalette.ink)
                        }

                        sectionTitle("How to make it")
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(AppPalette.orange, in: Circle())
                                    Text(step)
                                        .foregroundStyle(AppPalette.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    Text("Check ingredient freshness and cook food thoroughly.")
                        .font(.footnote)
                        .foregroundStyle(AppPalette.muted)
                        .padding(.top, 8)
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(28)
                .frame(maxWidth: .infinity)
            }
            .background(AppPalette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(AppPalette.ink)
    }
}
#else
struct InspirationView: View {
    var body: some View {
        Text("Inspiration is available on iPhone.")
    }
}
#endif
