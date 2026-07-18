import Foundation

/// A required amount of one inventory item — a recipe input shared by cooking,
/// crafting, and restoration.
public struct Ingredient: Equatable, Sendable {
    public let item: String
    public let count: Int
    public init(_ item: String, _ count: Int) {
        self.item = item
        self.count = count
    }
}

/// A gentle buff a meal grants (spec §2: "meals give gentle buffs"). v1 has
/// one — a faster bite — applied to fishing; the roster grows post-launch.
public enum MealBuff: String, Sendable, Equatable {
    case biteRate
}

/// A dish cooked from catch + harvest (docs/design/unlock-tables.md §4).
public struct Dish: Identifiable, Equatable, Sendable {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let unlockLevel: Int
    public let ingredients: [Ingredient]
    public let xp: Int
    /// The buff this meal grants and for how long — nil for a plain dish.
    public let buff: MealBuff?
    public let buffMinutes: Double
    /// Stroke-recipe archetype (design metadata; recipes keyed by `id`).
    public let archetype: String

    public init(
        id: String, nameEN: String, nameKO: String, unlockLevel: Int,
        ingredients: [Ingredient], xp: Int,
        buff: MealBuff? = nil, buffMinutes: Double = 0, archetype: String
    ) {
        self.id = id
        self.nameEN = nameEN
        self.nameKO = nameKO
        self.unlockLevel = unlockLevel
        self.ingredients = ingredients
        self.xp = xp
        self.buff = buff
        self.buffMinutes = buffMinutes
        self.archetype = archetype
    }
}

/// The cooking skill: which dishes the player's level has unlocked (whether
/// they can afford the ingredients is an inventory question, answered by the
/// store — hours gate the recipe, the haul gates the meal).
public enum Cooking {
    public static func available(level: Int) -> [Dish] {
        CookingTable.all.filter { level >= $0.unlockLevel }
    }

    public static func dish(id: String) -> Dish? {
        CookingTable.all.first { $0.id == id }
    }
}

/// The 9 M4 dishes, from docs/design/unlock-tables.md §4. Ingredient lists are
/// drafted data (fish/forage/garden ids); the spicy stew and the two feasts
/// grant the bite-rate buff.
public enum CookingTable {
    public static let all: [Dish] = [
        Dish(
            id: "grilled-fish", nameEN: "Grilled fish", nameKO: "생선구이",
            unlockLevel: 1, ingredients: [Ingredient("crucian-carp", 1)],
            xp: 60, archetype: "skewer"),
        Dish(
            id: "herb-rice", nameEN: "Herb rice", nameKO: "나물밥",
            unlockLevel: 10, ingredients: [Ingredient("mugwort", 2)],
            xp: 80, archetype: "bowl"),
        Dish(
            id: "spicy-fish-stew", nameEN: "Spicy fish stew", nameKO: "매운탕",
            unlockLevel: 20, ingredients: [Ingredient("catfish", 1), Ingredient("mugwort", 1)],
            xp: 110, buff: .biteRate, buffMinutes: 30, archetype: "bowl"),
        Dish(
            id: "mushroom-soup", nameEN: "Mushroom soup", nameKO: "버섯국",
            unlockLevel: 30, ingredients: [Ingredient("oyster-mushroom", 2)],
            xp: 120, archetype: "bowl"),
        Dish(
            id: "kimchi", nameEN: "Kimchi", nameKO: "김장",
            unlockLevel: 40, ingredients: [Ingredient("cabbage", 2)],
            xp: 140, archetype: "bowl"),
        Dish(
            id: "persimmon-punch", nameEN: "Persimmon punch", nameKO: "수정과",
            unlockLevel: 50, ingredients: [Ingredient("persimmon", 2)],
            xp: 150, archetype: "bowl"),
        Dish(
            id: "pine-nut-porridge", nameEN: "Pine-nut porridge", nameKO: "잣죽",
            unlockLevel: 60, ingredients: [Ingredient("pine-nuts", 2)],
            xp: 160, archetype: "bowl"),
        Dish(
            id: "full-table", nameEN: "Full table", nameKO: "한상",
            unlockLevel: 70,
            ingredients: [Ingredient("crucian-carp", 1), Ingredient("mugwort", 1), Ingredient("oyster-mushroom", 1)],
            xp: 200, buff: .biteRate, buffMinutes: 45, archetype: "bowl"),
        Dish(
            id: "hermits-table", nameEN: "The hermit's table", nameKO: "은자의 밥상",
            unlockLevel: 90,
            ingredients: [Ingredient("ink-carp", 1), Ingredient("matsutake", 1), Ingredient("persimmon", 1)],
            xp: 260, buff: .biteRate, buffMinutes: 60, archetype: "bowl"),
    ]
}
