import Foundation

public struct GrowthTuning {
    public var waterAmount: Double     // moisture added per watering
    public var drainPerDay: Double     // moisture lost per real day
    public var dryThreshold: Double    // below this: too dry, growth pauses
    public var tooWetThreshold: Double // above this: waterlogged, growth pauses
    public var moistureMax: Double     // watering cap (can exceed tooWet → stress)
    public var wiltAfterDryDays: Double
    public var glowStreak: Int

    public init(waterAmount: Double = 0.6, drainPerDay: Double = 0.55,
                dryThreshold: Double = 0.2, tooWetThreshold: Double = 1.0,
                moistureMax: Double = 1.3, wiltAfterDryDays: Double = 4,
                glowStreak: Int = 3) {
        self.waterAmount = waterAmount; self.drainPerDay = drainPerDay
        self.dryThreshold = dryThreshold; self.tooWetThreshold = tooWetThreshold
        self.moistureMax = moistureMax; self.wiltAfterDryDays = wiltAfterDryDays
        self.glowStreak = glowStreak
    }

    public static let `default` = GrowthTuning()
}
