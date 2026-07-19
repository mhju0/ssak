import SwiftUI

enum ZinniaArt {

    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.64), bow: w * 0.01),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.026, lineCap: .round))
            let lb = CGPoint(x: w * 0.5, y: h * 0.72)
            ctx.fill(leafPath(base: lb, angleDeg: -52, length: h * 0.13, width: w * 0.10), with: .color(p.foliage))
            ctx.fill(leafPath(base: lb, angleDeg: 52, length: h * 0.13, width: w * 0.10), with: .color(p.foliageDeep))
        }
    }

    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let tip = CGPoint(x: w * 0.5, y: h * 0.38)
            ctx.stroke(stemPath(base: base, tip: tip, bow: w * 0.015),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
            // opposite lance-shaped leaves up the stem
            for (i, y) in [CGFloat(0.80), 0.64, 0.49].enumerated() {
                let s = CGPoint(x: w * 0.5, y: h * y)
                let len = h * (0.20 - CGFloat(i) * 0.03)
                ctx.fill(leafPath(base: s, angleDeg: -62, length: len, width: w * 0.075),
                         with: .color(i.isMultiple(of: 2) ? p.foliage : p.foliageDeep))
                ctx.fill(leafPath(base: s, angleDeg: 62, length: len, width: w * 0.075),
                         with: .color(i.isMultiple(of: 2) ? p.foliageDeep : p.foliage))
            }
            ctx.fill(leafPath(base: tip, angleDeg: 0, length: h * 0.10, width: w * 0.06), with: .color(p.foliage))
        }
    }

    @ViewBuilder static func bud(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let neck = CGPoint(x: w * 0.5, y: h * 0.42)
            ctx.stroke(stemPath(base: base, tip: neck, bow: w * 0.01),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
            for y in [CGFloat(0.80), 0.63] {
                let s = CGPoint(x: w * 0.5, y: h * y)
                ctx.fill(leafPath(base: s, angleDeg: -60, length: h * 0.17, width: w * 0.07), with: .color(p.foliage))
                ctx.fill(leafPath(base: s, angleDeg: 60, length: h * 0.17, width: w * 0.07), with: .color(p.foliageDeep))
            }
            // plump bud: red petal tips inside a green calyx
            for ang in [-16.0, 0.0, 16.0] {
                ctx.fill(petalPath(base: CGPoint(x: w * 0.5, y: h * 0.40), angleDeg: ang, length: h * 0.11, width: w * 0.085),
                         with: .color(p.bloom))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 - w * 0.10, y: h * 0.42, width: w * 0.20, height: h * 0.10)),
                     with: .color(p.foliageDeep))
            for ang in [-30.0, -10.0, 10.0, 30.0] {
                ctx.fill(leafPath(base: CGPoint(x: w * 0.5, y: h * 0.47), angleDeg: ang, length: h * 0.10, width: w * 0.05),
                         with: .color(ang < 0 ? p.foliage : p.foliageDeep))
            }
        }
    }

    @ViewBuilder static func bloom(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let center = CGPoint(x: w * 0.5, y: h * 0.35)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.47), bow: w * 0.01),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
            for y in [CGFloat(0.80), 0.65] {
                let s = CGPoint(x: w * 0.5, y: h * y)
                ctx.fill(leafPath(base: s, angleDeg: -60, length: h * 0.15, width: w * 0.07), with: .color(p.foliage))
                ctx.fill(leafPath(base: s, angleDeg: 60, length: h * 0.15, width: w * 0.07), with: .color(p.foliageDeep))
            }
            // layered head: broad petals in neat rows, dark outer → bright inner
            let R = w * 0.30
            petalRing(ctx, center: center, count: 13, baseRadius: R * 0.42, length: R * 0.56, width: w * 0.088, color: p.bloomDeep, phaseDeg: 0)
            petalRing(ctx, center: center, count: 12, baseRadius: R * 0.30, length: R * 0.48, width: w * 0.086, color: p.bloom, phaseDeg: 14)
            petalRing(ctx, center: center, count: 10, baseRadius: R * 0.19, length: R * 0.38, width: w * 0.080, color: p.bloom, phaseDeg: 6)
            petalRing(ctx, center: center, count: 8, baseRadius: R * 0.10, length: R * 0.27, width: w * 0.070, color: p.bloomHighlight, phaseDeg: 22)
            // zinnia's little star-floret center: a yellow button with tiny points
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - R * 0.13, y: center.y - R * 0.13, width: R * 0.26, height: R * 0.26)),
                     with: .color(p.bloomDeep))
            for i in 0..<8 {
                let t = Double(i) / 8 * 2 * .pi
                let pt = CGPoint(x: center.x + CGFloat(sin(t)) * R * 0.09, y: center.y - CGFloat(cos(t)) * R * 0.09)
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - R * 0.03, y: pt.y - R * 0.03, width: R * 0.06, height: R * 0.06)),
                         with: .color(p.center))
            }
        }
    }
}
