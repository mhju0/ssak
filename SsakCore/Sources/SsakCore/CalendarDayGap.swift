import Foundation

public extension Calendar {
    /// Whole calendar days from `from` to `to`, measured start-of-day to start-of-day — so
    /// 11pm → 1am the next morning is a gap of **1**, not 0. `nil` only if the calendar can't
    /// compute the difference.
    ///
    /// The single source for "how many days apart," shared by the streak counter
    /// (`GrowthEngine.water`) and the streak-alive check (`GardenModel.isStreakAlive`), which
    /// must agree — they previously each inlined this same computation.
    func dayGap(from: Date, to: Date) -> Int? {
        dateComponents([.day], from: startOfDay(for: from), to: startOfDay(for: to)).day
    }
}
