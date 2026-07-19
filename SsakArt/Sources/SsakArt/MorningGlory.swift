import SwiftUI

/// A heart/spade leaf: petiole at `base` (a notch with two basal lobes), a point
/// at the tip `length` away along `angleDeg`.
func heartLeafPath(base: CGPoint, angleDeg: Double, length: CGFloat, width: CGFloat) -> Path {
    let a = angleDeg * .pi / 180
    let dir = CGVector(dx: sin(a), dy: -cos(a))
    let perp = CGVector(dx: cos(a), dy: sin(a))
    func pt(_ along: CGFloat, _ across: CGFloat) -> CGPoint {
        CGPoint(x: base.x + dir.dx * length * along + perp.dx * width * across,
                y: base.y + dir.dy * length * along + perp.dy * width * across)
    }
    let tip = pt(1.0, 0)
    var p = Path()
    p.move(to: base)                                   // notch
    p.addQuadCurve(to: pt(0.18, -0.5), control: pt(-0.05, -0.42))   // left lobe
    p.addQuadCurve(to: tip, control: pt(0.75, -0.5))               // up to tip
    p.addQuadCurve(to: pt(0.18, 0.5), control: pt(0.75, 0.5))      // down right
    p.addQuadCurve(to: base, control: pt(-0.05, 0.42))            // right lobe to notch
    return p
}

/// A twining vine from `base` up to `top`, snaking by `amp`.
func vinePath(base: CGPoint, top: CGPoint, amp: CGFloat, segments: Int = 4) -> Path {
    var p = Path()
    p.move(to: base)
    var prev = base
    for i in 1...segments {
        let t = CGFloat(i) / CGFloat(segments)
        let pt = CGPoint(x: base.x + (top.x - base.x) * t, y: base.y + (top.y - base.y) * t)
        let side: CGFloat = (i % 2 == 0) ? amp : -amp
        let ctrl = CGPoint(x: (prev.x + pt.x) / 2 + side, y: (prev.y + pt.y) / 2)
        p.addQuadCurve(to: pt, control: ctrl)
        prev = pt
    }
    return p
}

/// A `points`-pointed star centered at `center`.
func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int = 5, rotation: Double = 0) -> Path {
    var p = Path()
    for i in 0..<(points * 2) {
        let r = i % 2 == 0 ? outer : inner
        let t = rotation + Double(i) / Double(points * 2) * 2 * .pi
        let pt = CGPoint(x: center.x + CGFloat(sin(t)) * r, y: center.y - CGFloat(cos(t)) * r)
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath()
    return p
}

enum MorningGloryArt {

    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            ctx.stroke(vinePath(base: base, top: CGPoint(x: w * 0.5, y: h * 0.66), amp: w * 0.02),
                       with: .color(p.foliageDeep), style: StrokeStyle(lineWidth: w * 0.016, lineCap: .round))
            ctx.fill(heartLeafPath(base: CGPoint(x: w * 0.47, y: h * 0.70), angleDeg: -46, length: h * 0.11, width: w * 0.10), with: .color(p.foliage))
            ctx.fill(heartLeafPath(base: CGPoint(x: w * 0.53, y: h * 0.70), angleDeg: 46, length: h * 0.11, width: w * 0.10), with: .color(p.foliageDeep))
        }
    }

    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let top = CGPoint(x: w * 0.52, y: h * 0.34)
            ctx.stroke(vinePath(base: base, top: top, amp: w * 0.06),
                       with: .color(p.foliageDeep), style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))
            // heart leaves alternating along the twining vine
            let spots: [(x: CGFloat, y: CGFloat, ang: Double, front: Bool)] = [
                (0.40, 0.74, -50, true), (0.60, 0.62, 50, false),
                (0.44, 0.50, -46, false), (0.58, 0.40, 44, true)]
            for sp in spots {
                ctx.fill(heartLeafPath(base: CGPoint(x: w * sp.x, y: h * sp.y), angleDeg: sp.ang,
                                       length: h * 0.15, width: w * 0.13),
                         with: .color(sp.front ? p.foliage : p.foliageDeep))
            }
        }
    }

    @ViewBuilder static func bud(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let top = CGPoint(x: w * 0.5, y: h * 0.42)
            ctx.stroke(vinePath(base: base, top: top, amp: w * 0.05),
                       with: .color(p.foliageDeep), style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))
            ctx.fill(heartLeafPath(base: CGPoint(x: w * 0.38, y: h * 0.68), angleDeg: -52, length: h * 0.15, width: w * 0.13), with: .color(p.foliage))
            ctx.fill(heartLeafPath(base: CGPoint(x: w * 0.62, y: h * 0.56), angleDeg: 50, length: h * 0.14, width: w * 0.12), with: .color(p.foliageDeep))
            // furled spiral bud: a twisted cone with a violet tip
            let bud = CGPoint(x: w * 0.5, y: h * 0.40)
            ctx.fill(petalPath(base: CGPoint(x: w * 0.5, y: h * 0.47), angleDeg: 6, length: h * 0.14, width: w * 0.07),
                     with: .color(p.foliage))
            ctx.fill(petalPath(base: CGPoint(x: w * 0.5, y: h * 0.47), angleDeg: 6, length: h * 0.10, width: w * 0.045),
                     with: .color(p.bloom))
            // a furl line spiralling up the bud
            ctx.stroke(Path { pth in
                pth.move(to: CGPoint(x: w * 0.5, y: h * 0.46))
                pth.addQuadCurve(to: bud, control: CGPoint(x: w * 0.55, y: h * 0.43))
            }, with: .color(p.bloomHighlight.opacity(0.8)), style: StrokeStyle(lineWidth: w * 0.008, lineCap: .round))
        }
    }

    @ViewBuilder static func bloom(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let center = CGPoint(x: w * 0.5, y: h * 0.36)
            ctx.stroke(vinePath(base: base, top: CGPoint(x: w * 0.5, y: h * 0.50), amp: w * 0.05),
                       with: .color(p.foliageDeep), style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))
            ctx.fill(heartLeafPath(base: CGPoint(x: w * 0.34, y: h * 0.66), angleDeg: -54, length: h * 0.15, width: w * 0.13), with: .color(p.foliage))
            ctx.fill(heartLeafPath(base: CGPoint(x: w * 0.66, y: h * 0.58), angleDeg: 52, length: h * 0.14, width: w * 0.12), with: .color(p.foliageDeep))
            // funnel face: rounded pentagon, pale center → violet rim
            let R = w * 0.24
            let face = starPath(center: center, outer: R, inner: R * 0.86, points: 5, rotation: .pi / 5)
            ctx.fill(face, with: .radialGradient(
                Gradient(colors: [p.bloomHighlight, p.bloom, p.bloomDeep]),
                center: center, startRadius: 0, endRadius: R))
            // five faint seams
            var seams = Path()
            for i in 0..<5 {
                let t = Double(i) / 5 * 2 * .pi
                seams.move(to: center)
                seams.addLine(to: CGPoint(x: center.x + CGFloat(sin(t)) * R * 0.92,
                                          y: center.y - CGFloat(cos(t)) * R * 0.92))
            }
            ctx.stroke(seams, with: .color(p.bloomDeep.opacity(0.5)), style: StrokeStyle(lineWidth: w * 0.008))
            // pale star throat
            ctx.fill(starPath(center: center, outer: R * 0.42, inner: R * 0.17, points: 5, rotation: 0),
                     with: .color(p.bloomHighlight))
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - R * 0.10, y: center.y - R * 0.10, width: R * 0.20, height: R * 0.20)),
                     with: .color(p.center))
        }
    }
}
