import Foundation

public struct Species: Identifiable, Codable, Equatable {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let bloomDays: Double

    public init(id: String, nameEN: String, nameKO: String, bloomDays: Double) {
        self.id = id; self.nameEN = nameEN; self.nameKO = nameKO; self.bloomDays = bloomDays
    }
}

public enum SpeciesCatalog {
    public static let marigold     = Species(id: "marigold",      nameEN: "Marigold",      nameKO: "메리골드", bloomDays: 7)
    public static let nasturtium   = Species(id: "nasturtium",    nameEN: "Nasturtium",    nameKO: "한련화",   bloomDays: 8)
    public static let cosmos       = Species(id: "cosmos",        nameEN: "Cosmos",        nameKO: "코스모스", bloomDays: 9)
    public static let zinnia       = Species(id: "zinnia",        nameEN: "Zinnia",        nameKO: "백일홍",   bloomDays: 10)
    public static let sunflower    = Species(id: "sunflower",     nameEN: "Sunflower",     nameKO: "해바라기", bloomDays: 11)
    public static let morningGlory = Species(id: "morning_glory", nameEN: "Morning glory", nameKO: "나팔꽃",   bloomDays: 13)

    public static let all: [Species] = [marigold, nasturtium, cosmos, zinnia, sunflower, morningGlory]
    public static let starter: Species = marigold

    public static func species(id: String) -> Species? { all.first { $0.id == id } }
}
