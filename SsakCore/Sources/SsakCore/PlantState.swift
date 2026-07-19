import Foundation

public struct PlantState: Codable, Equatable {
    public var speciesID: String
    public var progress: Double        // 0...1 healthy growth
    public var moisture: Double        // 0...moistureMax
    public var lastUpdate: Date        // last engine reconciliation
    public var lastWateredAt: Date?    // for streak / watered-today / neglect
    public var streak: Int
    public var isNursing: Bool         // wilt-setback state
    public var plantedAt: Date

    public init(speciesID: String, progress: Double, moisture: Double, lastUpdate: Date,
                lastWateredAt: Date?, streak: Int, isNursing: Bool, plantedAt: Date) {
        self.speciesID = speciesID; self.progress = progress; self.moisture = moisture
        self.lastUpdate = lastUpdate; self.lastWateredAt = lastWateredAt; self.streak = streak
        self.isNursing = isNursing; self.plantedAt = plantedAt
    }
}
