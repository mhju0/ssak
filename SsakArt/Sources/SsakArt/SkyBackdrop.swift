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

    /// Continuous hour-of-day (0…24) in the injected calendar — the sole input to the band.
    private var hourOfDay: Double {
        let c = calendar.dateComponents([.hour, .minute], from: now)
        return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
    }

    /// (top, bottom) gradient stops, cross-fading over the ±0.5h window around each boundary.
    private var colors: (Color, Color) {
        let h = hourOfDay
        var top = Self.band(atHour: h).top
        var bottom = Self.band(atHour: h).bottom
        let w = 0.5
        for b in [5.0, 8.0, 17.0, 20.0] where abs(h - b) < w {      // boundaries are >1h apart → at most one matches
            let before = Self.band(atHour: b - 0.01), after = Self.band(atHour: b + 0.01)
            let t = (h - (b - w)) / (2 * w)                         // 0 at b-w … 1 at b+w
            top = Self.lerp(before.top, after.top, t)
            bottom = Self.lerp(before.bottom, after.bottom, t)
        }
        return scheme == .dark
            ? (Self.dark(nudgedBy: top), Self.dark(nudgedBy: bottom, deep: true))
            : (Self.color(top), Self.color(bottom))
    }

    // Bands (top, bottom) sRGB — spec §1.2. All light so ink clears its contrast bar.
    private typealias RGB = (Double, Double, Double)
    private static let dawn:  (top: RGB, bottom: RGB) = ((0.984, 0.914, 0.808), (0.957, 0.871, 0.776)) // #FBE9CE→#F4DEC6
    private static let day:   (top: RGB, bottom: RGB) = ((0.988, 0.973, 0.933), (0.906, 0.941, 0.855)) // #FCF8EE→#E7F0DA
    private static let dusk:  (top: RGB, bottom: RGB) = ((0.969, 0.875, 0.776), (0.918, 0.788, 0.682)) // #F7DFC6→#EAC9AE
    private static let night: (top: RGB, bottom: RGB) = ((0.906, 0.886, 0.925), (0.851, 0.827, 0.878)) // #E7E2EC→#D9D3E0

    private static func band(atHour h: Double) -> (top: RGB, bottom: RGB) {
        switch h {
        case 5..<8:   return dawn
        case 8..<17:  return day
        case 17..<20: return dusk
        default:      return night        // 20…24 and 0…5
        }
    }

    private static func lerp(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
        (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t)
    }
    private static func color(_ c: RGB) -> Color { Color(red: c.0, green: c.1, blue: c.2) }

    /// Warm-dark ground, hue nudged ~10% toward the day's band so night/dawn/dusk still
    /// read differently in dark mode without lifting the low luminance (spec §1.2, §3.4).
    private static func dark(nudgedBy band: RGB, deep: Bool = false) -> Color {
        let base: RGB = deep ? (0.090, 0.075, 0.059) : (0.165, 0.141, 0.110)   // #17130F / #2A241C
        return color(lerp(base, band, 0.10))
    }
}
