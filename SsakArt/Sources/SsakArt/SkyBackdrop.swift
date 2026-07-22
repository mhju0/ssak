import SwiftUI

/// The real-time wall behind the plant (spec §1.2). The `TimeBand` is derived
/// **purely** from the injected `now` + `calendar` (no internal clock read), so
/// the render harness gets reproducible PNGs by passing a fixed date + UTC calendar,
/// while the live app defaults to `.current` for the correct wall-clock band.
///
/// All light-mode bands stay *light* so ink text always reads. System Dark Mode is a
/// separate axis: in dark mode the wall is a warm-dark ground and the band only nudges hue.
public struct SkyBackdrop: View {
    let now: Date
    let calendar: Calendar
    public init(now: Date, calendar: Calendar = .current) {
        self.now = now; self.calendar = calendar
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        let (top, bottom) = colors
        ZStack {
            LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
            if scheme == .dark {                                    // faint warm glow near the top
                RadialGradient(colors: [Color(red: 0.55, green: 0.44, blue: 0.30).opacity(0.16), .clear],
                               center: .init(x: 0.5, y: 0.18), startRadius: 0, endRadius: 520)
            }
        }
    }

    /// (top, bottom) gradient stops via the shared `Daylight` band machinery —
    /// same math as ever, now also feeding `RoomScene`.
    private var colors: (Color, Color) {
        let h = Daylight.hour(of: now, in: calendar)
        let top = Daylight.blend(atHour: h) { Self.stops($0).top }
        let bottom = Daylight.blend(atHour: h) { Self.stops($0).bottom }
        return scheme == .dark
            ? (Daylight.dark(nudgedBy: top), Daylight.dark(nudgedBy: bottom, deep: true))
            : (Daylight.color(top), Daylight.color(bottom))
    }

    // Bands (top, bottom) sRGB — round-2 mockup sky ramps. Night is genuinely dark now:
    // since round 2 the sky lives inside RoomScene's window and chrome ink flips to cream
    // at night via TimeBand, so the "all bands light" round-1 compromise is retired.
    private typealias RGB = Daylight.RGB
    private static let dawn:  (top: RGB, bottom: RGB) = ((0.984, 0.914, 0.808), (0.957, 0.871, 0.776)) // #FBE9CE→#F4DEC6
    private static let day:   (top: RGB, bottom: RGB) = ((0.843, 0.910, 0.945), (0.957, 0.914, 0.812)) // #D7E8F1→#F4E9CF
    private static let dusk:  (top: RGB, bottom: RGB) = ((0.910, 0.812, 0.878), (0.949, 0.769, 0.537)) // #E8CFE0→#F2C489
    private static let night: (top: RGB, bottom: RGB) = ((0.141, 0.227, 0.329), (0.055, 0.086, 0.133)) // #243A54→#0E1622

    private static func stops(_ b: TimeBand) -> (top: RGB, bottom: RGB) {
        switch b {
        case .dawn:  return dawn
        case .day:   return day
        case .dusk:  return dusk
        case .night: return night
        }
    }
}
