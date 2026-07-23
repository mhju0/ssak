import SwiftUI

/// Round 3 (spec `2026-07-23-ssak-round3-hanji.md`): the hanji album page the windowsill
/// lives on. The paper's tone follows the real clock through the shared `Daylight`
/// machinery — cream by day, rosy at dawn, lamplit tan at dusk, deep warm-dark at night
/// (chrome flips to light ink at night via the existing `TimeBand` rule; system dark
/// mode alone does not change the paper). Pure `now + calendar`, deterministic headless.
public struct HanjiBackdrop: View {
    let now: Date
    let calendar: Calendar
    public init(now: Date, calendar: Calendar = .current) {
        self.now = now; self.calendar = calendar
    }

    // Paper gradient per band (spec palette table).
    private static func top(_ b: TimeBand) -> Daylight.RGB {
        switch b {
        case .dawn:  return (0.949, 0.894, 0.831)   // #F2E4D4 rosy
        case .day:   return (0.961, 0.933, 0.871)   // #F5EEDE cream
        case .dusk:  return (0.894, 0.824, 0.675)   // #E4D2AC lamplit tan
        case .night: return (0.180, 0.157, 0.125)   // #2E2820 dark paper
        }
    }
    private static func bottom(_ b: TimeBand) -> Daylight.RGB {
        switch b {
        case .dawn:  return (0.910, 0.831, 0.737)   // #E8D4BC
        case .day:   return (0.922, 0.878, 0.784)   // #EBE0C8
        case .dusk:  return (0.780, 0.686, 0.510)   // #C7AF82
        case .night: return (0.118, 0.098, 0.075)   // #1E1913
        }
    }
    /// Dusk lamp-glow strength (packed through `blend` so it cross-fades too).
    private static func lamp(_ b: TimeBand) -> Daylight.RGB {
        b == .dusk ? (0.32, 0, 0) : (0, 0, 0)
    }

    /// Fixed fleck spots (unit coords) — hand-authored paper fibers, deterministic.
    private static let flecks: [(x: Double, y: Double, r: Double)] = [
        (0.16, 0.24, 1.6), (0.82, 0.11, 1.1), (0.38, 0.55, 1.2),
        (0.68, 0.42, 1.5), (0.24, 0.80, 1.1), (0.88, 0.68, 1.4), (0.55, 0.91, 1.0),
    ]

    public var body: some View {
        let h = Daylight.hour(of: now, in: calendar)
        let band = Daylight.band(atHour: h)
        let top = Daylight.color(Daylight.blend(atHour: h, Self.top))
        let bottom = Daylight.color(Daylight.blend(atHour: h, Self.bottom))
        let lamp = Daylight.blend(atHour: h, Self.lamp).0

        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [top, bottom],
                               startPoint: UnitPoint(x: 0.35, y: 0), endPoint: UnitPoint(x: 0.65, y: 1))
                // paper fibers — barely-there, fainter on dark paper
                Canvas { ctx, size in
                    let fleck = band == .night
                        ? Color(red: 0.86, green: 0.82, blue: 0.72).opacity(0.10)
                        : Color(red: 0.55, green: 0.48, blue: 0.36).opacity(0.16)
                    for f in Self.flecks {
                        let rect = CGRect(x: f.x * size.width, y: f.y * size.height,
                                          width: f.r, height: f.r)
                        ctx.fill(Path(ellipseIn: rect), with: .color(fleck))
                    }
                }
                if lamp > 0.01 {                       // dusk: warm lamp top-right + vignette
                    RadialGradient(colors: [Color(red: 0.941, green: 0.698, blue: 0.376).opacity(lamp),
                                            .clear],
                                   center: UnitPoint(x: 0.82, y: 0.12),
                                   startRadius: 0, endRadius: geo.size.width * 1.05)
                    RadialGradient(colors: [.clear, Color(red: 0.329, green: 0.235, blue: 0.133).opacity(lamp * 0.8)],
                                   center: UnitPoint(x: 0.5, y: 0.4),
                                   startRadius: geo.size.width * 0.55,
                                   endRadius: geo.size.width * 1.25)
                }
            }
        }
    }
}
