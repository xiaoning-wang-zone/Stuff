struct FoodCategory: Identifiable, Sendable {
    let name: String
    let emoji: String

    var id: String { name }

    static let all: [FoodCategory] = [
        FoodCategory(name: "Fruits", emoji: "🍎"),
        FoodCategory(name: "Vegetables", emoji: "🥕"),
        FoodCategory(name: "Grains", emoji: "🌾"),
        FoodCategory(name: "Legumes", emoji: "🫘"),
        FoodCategory(name: "Nuts and seeds", emoji: "🥜"),
        FoodCategory(name: "Meat", emoji: "🥩"),
        FoodCategory(name: "Poultry", emoji: "🍗"),
        FoodCategory(name: "Fish and seafood", emoji: "🐟"),
        FoodCategory(name: "Eggs", emoji: "🥚"),
        FoodCategory(name: "Dairy", emoji: "🥛"),
        FoodCategory(name: "Fats and oils", emoji: "🫒"),
        FoodCategory(name: "Sweets and desserts", emoji: "🍰"),
        FoodCategory(name: "Snacks", emoji: "🥨"),
        FoodCategory(name: "Beverages", emoji: "🥤"),
        FoodCategory(name: "Herbs and spices", emoji: "🌿"),
        FoodCategory(name: "Sauces and condiments", emoji: "🧂"),
        FoodCategory(name: "Soups and stews", emoji: "🥣"),
        FoodCategory(name: "Breads and baked goods", emoji: "🥖"),
        FoodCategory(name: "Pasta and noodles", emoji: "🍝"),
        FoodCategory(name: "Rice dishes", emoji: "🍚"),
        FoodCategory(name: "Fermented foods", emoji: "🥒"),
        FoodCategory(name: "Processed foods", emoji: "🥫"),
        FoodCategory(name: "Fast food", emoji: "🍔"),
        FoodCategory(name: "Prepared/ready-to-eat foods", emoji: "🍱")
    ]
}
