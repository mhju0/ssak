import SwiftUI

/// The time-of-day band, derived **purely** from an injected `now` + `calendar`
/// (never stored — spec §3.4). Public so chrome layered over `RoomScene` can flip
/// to dark ink when the room itself goes dark at night, independent of system dark mode.
public enum TimeBand: Sendable {
    case dawn, day, dusk, night

    public init(now: Date, calendar: Calendar = .current) {
        self = Daylight.band(atHour: Daylight.hour(of: now, in: calendar))
    }
}

/// Shared hour→band machinery for `SkyBackdrop` and `RoomScene`.
enum Daylight {
    typealias RGB = (Double, Double, Double)

    /// Continuous hour-of-day (0…24) in the injected calendar — the sole input to the band.
    static func hour(of now: Date, in calendar: Calendar) -> Double {
        let c = calendar.dateComponents([.hour, .minute], from: now)
        return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
    }

    static func band(atHour h: Double) -> TimeBand {
        switch h {
        case 5..<8:   return .dawn
        case 8..<17:  return .day
        case 17..<20: return .dusk
        default:      return .night        // 20…24 and 0…5
        }
    }

    /// A band-keyed value at the hour, cross-fading over the ±0.5h window around each boundary.
    static func blend(atHour h: Double, _ value: (TimeBand) -> RGB) -> RGB {
        var v = value(band(atHour: h))
        let w = 0.5
        for b in [5.0, 8.0, 17.0, 20.0] where abs(h - b) < w {   // boundaries are >1h apart → at most one matches
            let t = (h - (b - w)) / (2 * w)                      // 0 at b-w … 1 at b+w
            v = lerp(value(band(atHour: b - 0.01)), value(band(atHour: b + 0.01)), t)
        }
        return v
    }

    static func lerp(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
        (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t)
    }
    static func color(_ c: RGB) -> Color { Color(red: c.0, green: c.1, blue: c.2) }

    /// Warm-dark ground, hue nudged ~10% toward the band color so bands still read
    /// in dark mode without lifting the low luminance (spec §1.2, §3.4).
    static func dark(nudgedBy band: RGB, deep: Bool = false) -> Color {
        let base: RGB = deep ? (0.090, 0.075, 0.059) : (0.165, 0.141, 0.110)   // #17130F / #2A241C
        return color(lerp(base, band, 0.10))
    }
}

/// The living room behind the windowsill (round-2 mockup, `docs/design/`): a band-tinted
/// room, a window onto the real-time sky, a sunbeam, blurred plant friends, and a sill
/// that fades up from the bottom — no hard edges. Dust motes drift on iOS when motion is
/// allowed; the macOS render path draws none, so headless PNGs stay deterministic.
public struct RoomScene: View {
    let now: Date
    let calendar: Calendar
    public init(now: Date, calendar: Calendar = .current) {
        self.now = now; self.calendar = calendar
    }

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                LinearGradient(stops: [.init(color: roomColor(\.roomA), location: 0),
                                       .init(color: roomColor(\.roomB), location: 0.68)],
                               startPoint: .top, endPoint: .bottom)
                window(w: w, h: h)
                sunbeam(w: w)
                glow(h: h)
                friends(w: w, h: h)
                sill(h: h)
                #if os(iOS)
                if !reduceMotion { MotesLayer().blendMode(.screen).opacity(0.8) }
                #endif
            }
            .clipped()
        }
        .accessibilityHidden(true)
    }

    // MARK: layers

    /// The window onto the sky: SkyBackdrop + soft bokeh greenery + muntin bars,
    /// hung slightly above the top edge (mockup: top −4%, 8% side insets).
    private func window(w: CGFloat, h: CGFloat) -> some View {
        let winW = w * 0.84, winH = h * 0.56
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
        return ZStack {
            SkyBackdrop(now: now, calendar: calendar).saturation(1.05)
            ForEach(Array(Self.bokeh.enumerated()), id: \.offset) { _, b in
                Circle().fill(accentColor(\.bokeh).opacity(0.55))
                    .frame(width: b.size, height: b.size)
                    .blur(radius: 7)
                    .position(x: winW * b.x, y: winH * b.y)
            }
            Rectangle().fill(.white.opacity(0.22)).frame(width: 5)
            Rectangle().fill(.white.opacity(0.22)).frame(height: 5)
                .position(x: winW / 2, y: winH * 0.52)
        }
        .frame(width: winW, height: winH)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.14), lineWidth: 6))
        .position(x: w / 2, y: winH / 2 - h * 0.04)
    }

    private func sunbeam(w: CGFloat) -> some View {
        RadialGradient(colors: [accentColor(\.beam).opacity(0.85), accentColor(\.beam).opacity(0)],
                       center: UnitPoint(x: 0.22, y: 0.08), startRadius: 0, endRadius: w * 0.5)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    private func glow(h: CGFloat) -> some View {
        // A squashed ellipse just under the window's bottom edge (0.52h): warms the plant
        // zone without washing the night sky grey — the round glow was the failure mode here.
        RadialGradient(colors: [accentColor(\.glow).opacity(0.42), accentColor(\.glow).opacity(0)],
                       center: UnitPoint(x: 0.5, y: 0.56), startRadius: 0, endRadius: h * 0.38)
            .scaleEffect(x: 1, y: 0.55, anchor: UnitPoint(x: 0.5, y: 0.56))
            .allowsHitTesting(false)
    }

    /// Two out-of-focus plant friends for life: a leafy canopy peeking in top-right,
    /// a potted silhouette far left. Fixed muted greens; blur + low opacity carry the depth.
    private func friends(w: CGFloat, h: CGFloat) -> some View {
        let leaf = Color(red: 0.486, green: 0.635, blue: 0.294)      // #7CA24B
        let leafD = Color(red: 0.361, green: 0.502, blue: 0.212)     // #5C8036
        let pot = Color(red: 0.620, green: 0.306, blue: 0.200)
        return ZStack {
            ZStack {                                                  // canopy, top-right
                Ellipse().fill(leaf).frame(width: 52, height: 24).rotationEffect(.degrees(30)).offset(x: -30, y: -25)
                Ellipse().fill(leaf).frame(width: 60, height: 24).rotationEffect(.degrees(-14)).offset(x: 10, y: -31)
                Ellipse().fill(leaf).frame(width: 44, height: 20).rotationEffect(.degrees(24)).offset(x: 38, y: -11)
            }
            .blur(radius: 3.5).opacity(0.6)
            .position(x: w * 0.86, y: h * 0.07)

            ZStack {                                                  // potted friend, far left
                RoundedRectangle(cornerRadius: 8).fill(pot).frame(width: 40, height: 46).offset(y: 33)
                Ellipse().fill(leafD).frame(width: 24, height: 60).rotationEffect(.degrees(-24)).offset(x: -13, y: -8)
                Ellipse().fill(leafD).frame(width: 24, height: 64).rotationEffect(.degrees(20)).offset(x: 13, y: -10)
                Ellipse().fill(leafD).frame(width: 22, height: 68).offset(y: -20)
            }
            .blur(radius: 5).opacity(0.36)
            .position(x: w * 0.02, y: h * 0.72)
        }
        .allowsHitTesting(false)
    }

    /// Soft wooden ground fading up from the bottom — deliberately no hard edge.
    private func sill(h: CGFloat) -> some View {
        LinearGradient(stops: [.init(color: roomColor(\.sill).opacity(0), location: 0),
                               .init(color: roomColor(\.sill), location: 0.46),
                               .init(color: roomColor(\.sillEdge), location: 1)],
                       startPoint: .top, endPoint: .bottom)
            .frame(height: h * 0.36)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(0.9)
            .allowsHitTesting(false)
    }

    // MARK: palette

    private struct Palette {
        let roomA, roomB, sill, sillEdge, glow, beam, bokeh: Daylight.RGB
    }
    // From the mockup's per-band CSS ramps. Dawn borrows dusk's warm room — the sky
    // in the window (SkyBackdrop) is what tells dawn and dusk apart.
    private static let dayP = Palette(
        roomA: (0.988, 0.965, 0.914), roomB: (0.941, 0.882, 0.769),          // #FCF6E9 → #F0E1C4
        sill: (0.906, 0.780, 0.612), sillEdge: (0.780, 0.620, 0.439),        // #E7C79C / #C79E70
        glow: (1, 0.945, 0.808), beam: (1, 0.969, 0.878), bokeh: (0.588, 0.745, 0.471))
    private static let duskP = Palette(
        roomA: (0.969, 0.906, 0.816), roomB: (0.902, 0.769, 0.663),          // #F7E7D0 → #E6C4A9
        sill: (0.859, 0.671, 0.494), sillEdge: (0.710, 0.522, 0.353),        // #DBAB7E / #B5855A
        glow: (1, 0.839, 0.588), beam: (1, 0.788, 0.557), bokeh: (0.745, 0.588, 0.392))
    private static let nightP = Palette(
        roomA: (0.141, 0.110, 0.086), roomB: (0.082, 0.063, 0.043),          // #241C16 → #15100B
        sill: (0.231, 0.180, 0.133), sillEdge: (0.137, 0.102, 0.075),        // #3B2E22 / #231A13
        glow: (1, 0.808, 0.588), beam: (1, 0.800, 0.588), bokeh: (0.471, 0.647, 0.804))

    private static func palette(_ b: TimeBand) -> Palette {
        switch b {
        case .day:          return dayP
        case .dawn, .dusk:  return duskP
        case .night:        return nightP
        }
    }

    private func banded(_ kp: KeyPath<Palette, Daylight.RGB>) -> Daylight.RGB {
        let h = Daylight.hour(of: now, in: calendar)
        return Daylight.blend(atHour: h) { Self.palette($0)[keyPath: kp] }
    }

    /// Room surfaces: in system dark mode, sit on the night ramp and nudge ~10% toward
    /// the band (same rule as SkyBackdrop's dark grounds) so bands still read.
    private func roomColor(_ kp: KeyPath<Palette, Daylight.RGB>) -> Color {
        let v = banded(kp)
        guard scheme == .dark else { return Daylight.color(v) }
        return Daylight.color(Daylight.lerp(Self.nightP[keyPath: kp], v, 0.10))
    }

    /// Light accents (glow, beam, bokeh) keep their band color in both schemes.
    private func accentColor(_ kp: KeyPath<Palette, Daylight.RGB>) -> Color {
        Daylight.color(banded(kp))
    }

    /// Window bokeh (x, y as fractions of the window; size in points) — fixed, from the mockup.
    private static let bokeh: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.18, 0.20, 34), (0.64, 0.14, 26), (0.40, 0.44, 40),
        (0.82, 0.40, 24), (0.10, 0.52, 20), (0.70, 0.64, 30),
    ]
}

#if os(iOS)
/// Ambient dust motes drifting up through the light. Fixed seed table — no runtime
/// randomness, so the ambience is reproducible. iOS-only and Reduce-Motion-gated;
/// position is a pure function of wall-clock time.
private struct MotesLayer: View {
    // (x, startY, radius pt, speed screens/s, opacity, sway phase)
    static let motes: [(x: Double, y: Double, r: Double, s: Double, o: Double, p: Double)] = [
        (0.08, 0.15, 1.4, 0.011, 0.42, 0.0), (0.16, 0.62, 0.9, 0.006, 0.28, 1.1),
        (0.22, 0.34, 1.8, 0.014, 0.55, 2.3), (0.28, 0.81, 1.1, 0.008, 0.33, 3.4),
        (0.33, 0.05, 1.5, 0.012, 0.47, 4.6), (0.38, 0.48, 0.8, 0.005, 0.24, 5.7),
        (0.44, 0.72, 1.9, 0.016, 0.60, 0.8), (0.49, 0.27, 1.2, 0.009, 0.36, 1.9),
        (0.54, 0.90, 1.6, 0.013, 0.50, 3.0), (0.59, 0.11, 0.9, 0.006, 0.26, 4.2),
        (0.63, 0.55, 1.4, 0.011, 0.44, 5.3), (0.68, 0.38, 1.0, 0.007, 0.31, 0.4),
        (0.73, 0.68, 1.7, 0.015, 0.57, 1.5), (0.78, 0.21, 1.2, 0.009, 0.38, 2.7),
        (0.82, 0.84, 0.8, 0.005, 0.22, 3.8), (0.87, 0.44, 1.5, 0.012, 0.48, 4.9),
        (0.91, 0.09, 1.1, 0.008, 0.34, 0.2), (0.13, 0.95, 1.3, 0.010, 0.40, 1.3),
        (0.47, 0.58, 0.9, 0.006, 0.27, 2.5), (0.70, 0.02, 1.6, 0.013, 0.52, 3.6),
        (0.25, 0.17, 1.0, 0.007, 0.30, 4.7), (0.85, 0.75, 1.3, 0.010, 0.41, 5.9),
    ]

    var body: some View {
        // ponytail: 20fps cap — ambience, not gameplay; raise only if it visibly stutters.
        TimelineView(.animation(minimumInterval: 1 / 20)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let tint = Color(red: 1, green: 0.957, blue: 0.824)
                for m in Self.motes {
                    let y = 1.04 - (m.y + t * m.s).truncatingRemainder(dividingBy: 1.08)
                    let x = m.x + 0.015 * sin(t * 0.25 + m.p)
                    let rect = CGRect(x: x * size.width - m.r, y: y * size.height - m.r,
                                      width: m.r * 2, height: m.r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(tint.opacity(m.o)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
#endif
