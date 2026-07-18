import Foundation

/// What a restored room unlocks (spec §2 The hermitage).
public enum RoomFunction: String, Sendable {
    case kitchen   // cooking
    case toolShed  // tool storage / upgrades
    case studio    // larger paintings (M5)
    case gallery   // display space (M5)
}

/// A hermitage room, ruined at start, restored with crafted goods (spec §2).
public struct Room: Identifiable, Equatable, Sendable {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    /// Crafted goods consumed to restore it (repair kits, from Crafting).
    public let cost: [Ingredient]
    public let unlocks: RoomFunction

    public init(
        id: String, nameEN: String, nameKO: String,
        cost: [Ingredient], unlocks: RoomFunction
    ) {
        self.id = id
        self.nameEN = nameEN
        self.nameKO = nameKO
        self.cost = cost
        self.unlocks = unlocks
    }
}

/// The four v1 rooms. Restoration consumes repair kits (crafted at Crafting 30),
/// so the loop is: fish/forage → craft repair kits → restore the kitchen → cook.
public enum Hermitage {
    public static let rooms: [Room] = [
        Room(
            id: "kitchen", nameEN: "Kitchen", nameKO: "부엌",
            cost: [Ingredient("repair-kit", 1)], unlocks: .kitchen),
        Room(
            id: "tool-shed", nameEN: "Tool shed", nameKO: "연장간",
            cost: [Ingredient("repair-kit", 1)], unlocks: .toolShed),
        Room(
            id: "studio", nameEN: "Studio", nameKO: "화실",
            cost: [Ingredient("repair-kit", 2)], unlocks: .studio),
        Room(
            id: "gallery", nameEN: "Gallery wing", nameKO: "전시관",
            cost: [Ingredient("repair-kit", 2)], unlocks: .gallery),
    ]

    public static func room(id: String) -> Room? {
        rooms.first { $0.id == id }
    }
}
