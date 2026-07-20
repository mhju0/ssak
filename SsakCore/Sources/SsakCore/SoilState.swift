import Foundation

/// The soil's care category — **dry**, **moist** (healthy), or **over-full** — derived
/// from a plant's moisture against its `GrowthTuning` thresholds.
///
/// One home for a classification that was otherwise re-derived at every read-out (the drop
/// gauge's colour, the status label, the VoiceOver phrase). The growth engine's own pause
/// boundaries use these same thresholds — growth pauses below `dryThreshold` and above
/// `tooWetThreshold` — so this enum is behavior-equivalent to that inline math and could be
/// adopted there too (deferred: the redesign keeps existing engine logic untouched).
public enum SoilState {
    case dry, moist, overfull

    /// Classify raw moisture. Boundaries match the engine exactly: exactly `dryThreshold` is
    /// *moist* (growth gate is `>= dryThreshold`), exactly `tooWetThreshold` is *moist*
    /// (waterlog pause is `> tooWetThreshold`).
    public init(moisture: Double, tuning: GrowthTuning = .default) {
        if moisture < tuning.dryThreshold         { self = .dry }
        else if moisture > tuning.tooWetThreshold { self = .overfull }
        else                                      { self = .moist }
    }
}
