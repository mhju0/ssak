import Foundation

public struct GameState: Codable, Equatable {
    public var plant: PlantState
    public var collected: [String]   // species ids pressed to the shelf

    public init(plant: PlantState, collected: [String]) {
        self.plant = plant; self.collected = collected
    }
}
