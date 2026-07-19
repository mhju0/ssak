import SwiftUI

/// A soft feathery cosmos frond: a slightly curved rachis with many fine,
/// upswept, gently curved leaflets — a delicate plume. One strokable Path.
func featheryFrondPath(base: CGPoint, angleDeg: Double, length: CGFloat, spread: CGFloat) -> Path {
    let a = angleDeg * .pi / 180
    let dir = CGVector(dx: sin(a), dy: -cos(a))
    let perp = CGVector(dx: cos(a), dy: sin(a))
    let tip = CGPoint(x: base.x + dir.dx * length, y: base.y + dir.dy * length)
    var p = Path()
    // gently bowed rachis
    p.move(to: base)
    p.addQuadCurve(to: tip, control: CGPoint(x: (base.x + tip.x) / 2 + perp.dx * spread * 0.15,
                                             y: (base.y + tip.y) / 2 + perp.dy * spread * 0.15))
    let n = 9
    for i in 1...n {
        let t = CGFloat(i) / CGFloat(n + 1)
        let pt = CGPoint(x: base.x + dir.dx * length * t, y: base.y + dir.dy * length * t)
        let llen = spread * (1.0 - t * 0.45)
        for side in [CGFloat(-1), 1] {
            // upswept direction: mostly along the rachis, a little to the side
            var ux = perp.dx * side * 0.55 + dir.dx
            var uy = perp.dy * side * 0.55 + dir.dy
            let m = (ux * ux + uy * uy).squareRoot(); ux /= m; uy /= m
            let end = CGPoint(x: pt.x + ux * llen, y: pt.y + uy * llen)
            // slight curve — fine thread, not a leaf edge
            let ctrl = CGPoint(x: (pt.x + end.x) / 2 + perp.dx * side * llen * 0.12,
                               y: (pt.y + end.y) / 2 + perp.dy * side * llen * 0.12)
            p.move(to: pt)
            p.addQuadCurve(to: end, control: ctrl)
        }
    }
    return p
}

enum CosmosArt {

    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.64), bow: w * 0.012),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.016, lineCap: .round))
            // narrow cotyledons
            let lb = CGPoint(x: w * 0.5, y: h * 0.74)
            ctx.fill(leafPath(base: lb, angleDeg: -50, length: h * 0.13, width: w * 0.055), with: .color(p.foliage))
            ctx.fill(leafPath(base: lb, angleDeg: 50, length: h * 0.13, width: w * 0.055), with: .color(p.foliageDeep))
        }
    }

    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let tip = CGPoint(x: w * 0.5, y: h * 0.30)
            ctx.stroke(stemPath(base: base, tip: tip, bow: w * 0.03),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.018, lineCap: .round))
            let stroke = StrokeStyle(lineWidth: w * 0.0075, lineCap: .round)
            for (i, y) in [CGFloat(0.84), 0.70, 0.56, 0.43].enumerated() {
                let s = CGPoint(x: w * 0.5, y: h * y)
                ctx.stroke(featheryFrondPath(base: s, angleDeg: -66 + Double(i) * 4, length: h * (0.19 - CGFloat(i) * 0.025), spread: w * 0.135),
                           with: .color(i.isMultiple(of: 2) ? p.foliage : p.foliageDeep), style: stroke)
                ctx.stroke(featheryFrondPath(base: s, angleDeg: 66 - Double(i) * 4, length: h * (0.19 - CGFloat(i) * 0.025), spread: w * 0.135),
                           with: .color(i.isMultiple(of: 2) ? p.foliageDeep : p.foliage), style: stroke)
            }
        }
    }

    @ViewBuilder static func bud(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let neck = CGPoint(x: w * 0.5, y: h * 0.40)
            ctx.stroke(stemPath(base: base, tip: neck, bow: w * 0.02),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.018, lineCap: .round))
            let stroke = StrokeStyle(lineWidth: w * 0.010, lineCap: .round)
            for y in [CGFloat(0.82), 0.64] {
                let s = CGPoint(x: w * 0.5, y: h * y)
                ctx.stroke(featheryFrondPath(base: s, angleDeg: -60, length: h * 0.16, spread: w * 0.10), with: .color(p.foliage), style: stroke)
                ctx.stroke(featheryFrondPath(base: s, angleDeg: 60, length: h * 0.16, spread: w * 0.10), with: .color(p.foliageDeep), style: stroke)
            }
            // slim spindle bud with a faint pink tip
            ctx.fill(petalPath(base: CGPoint(x: w * 0.5, y: h * 0.42), angleDeg: 0, length: h * 0.12, width: w * 0.07),
                     with: .color(p.foliage))
            for ang in [-24.0, -8.0, 8.0, 24.0] {
                ctx.fill(leafPath(base: CGPoint(x: w * 0.5, y: h * 0.42), angleDeg: ang, length: h * 0.11, width: w * 0.03),
                         with: .color(p.foliageDeep))
            }
            ctx.fill(petalPath(base: CGPoint(x: w * 0.5, y: h * 0.335), angleDeg: 0, length: h * 0.035, width: w * 0.045),
                     with: .color(p.bloom))
        }
    }

    @ViewBuilder static func bloom(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let center = CGPoint(x: w * 0.5, y: h * 0.34)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.46), bow: w * 0.02),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.018, lineCap: .round))
            let stroke = StrokeStyle(lineWidth: w * 0.010, lineCap: .round)
            ctx.stroke(featheryFrondPath(base: CGPoint(x: w * 0.5, y: h * 0.80), angleDeg: -60, length: h * 0.15, spread: w * 0.10), with: .color(p.foliage), style: stroke)
            ctx.stroke(featheryFrondPath(base: CGPoint(x: w * 0.5, y: h * 0.80), angleDeg: 60, length: h * 0.15, spread: w * 0.10), with: .color(p.foliageDeep), style: stroke)
            // single daisy: a back ring for depth, then 8 broad rays, then disk
            petalRing(ctx, center: center, count: 8, baseRadius: w * 0.05, length: h * 0.20, width: w * 0.11, color: p.bloomDeep, phaseDeg: 22)
            petalRing(ctx, center: center, count: 8, baseRadius: w * 0.045, length: h * 0.19, width: w * 0.105, color: p.bloom, phaseDeg: 0)
            // pale streaks toward the throat
            petalRing(ctx, center: center, count: 8, baseRadius: w * 0.03, length: h * 0.085, width: w * 0.03, color: p.bloomHighlight, phaseDeg: 0)
            // yellow disk
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - w * 0.052, y: center.y - w * 0.052, width: w * 0.104, height: w * 0.104)),
                     with: .color(p.center))
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - w * 0.026, y: center.y - w * 0.026, width: w * 0.052, height: w * 0.052)),
                     with: .color(p.bloomDeep.opacity(0.5)))
        }
    }
}
