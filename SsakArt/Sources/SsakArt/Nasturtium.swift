import SwiftUI

/// A round peltate nasturtium leaf: a filled disk with fine veins radiating from
/// its center to the rim. `stroke` is a thin vein style.
func drawShieldLeaf(_ ctx: GraphicsContext, center: CGPoint, radius: CGFloat,
                    fill: Color, vein: Color, veinWidth: CGFloat) {
    ctx.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                    width: radius * 2, height: radius * 2)), with: .color(fill))
    var veins = Path()
    for i in 0..<8 {
        let t = Double(i) / 8 * 2 * .pi
        veins.move(to: center)
        veins.addLine(to: CGPoint(x: center.x + CGFloat(sin(t)) * radius * 0.92,
                                  y: center.y - CGFloat(cos(t)) * radius * 0.92))
    }
    ctx.stroke(veins, with: .color(vein), style: StrokeStyle(lineWidth: veinWidth, lineCap: .round))
}

enum NasturtiumArt {

    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.66), bow: w * 0.012),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))
            drawShieldLeaf(ctx, center: CGPoint(x: w * 0.40, y: h * 0.66), radius: w * 0.07,
                           fill: p.foliage, vein: p.foliageDeep, veinWidth: w * 0.006)
            drawShieldLeaf(ctx, center: CGPoint(x: w * 0.60, y: h * 0.66), radius: w * 0.07,
                           fill: p.foliageDeep, vein: p.foliage, veinWidth: w * 0.006)
        }
    }

    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.44), bow: w * 0.03),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
            // round shield leaves on short stalks at varied heights
            let spots: [(x: CGFloat, y: CGFloat, r: CGFloat, front: Bool)] = [
                (0.34, 0.72, 0.11, true), (0.66, 0.62, 0.115, false),
                (0.42, 0.50, 0.10, false), (0.60, 0.42, 0.095, true)]
            for sp in spots {
                let c = CGPoint(x: w * sp.x, y: h * sp.y)
                ctx.stroke(stemPath(base: CGPoint(x: w * 0.5, y: h * (sp.y + 0.06)), tip: c, bow: 0),
                           with: .color(p.foliageDeep), style: StrokeStyle(lineWidth: w * 0.012, lineCap: .round))
                drawShieldLeaf(ctx, center: c, radius: w * sp.r,
                               fill: sp.front ? p.foliage : p.foliageDeep,
                               vein: sp.front ? p.foliageDeep : p.foliage, veinWidth: w * 0.006)
            }
        }
    }

    @ViewBuilder static func bud(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.42), bow: w * 0.02),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
            drawShieldLeaf(ctx, center: CGPoint(x: w * 0.36, y: h * 0.66), radius: w * 0.115,
                           fill: p.foliage, vein: p.foliageDeep, veinWidth: w * 0.006)
            drawShieldLeaf(ctx, center: CGPoint(x: w * 0.64, y: h * 0.54), radius: w * 0.10,
                           fill: p.foliageDeep, vein: p.foliage, veinWidth: w * 0.006)
            // a small pointed bud with a spur curling behind
            ctx.stroke(Path { pth in
                pth.move(to: CGPoint(x: w * 0.5, y: h * 0.42))
                pth.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.46), control: CGPoint(x: w * 0.60, y: h * 0.40))
            }, with: .color(p.bloomDeep), style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))  // spur
            ctx.fill(petalPath(base: CGPoint(x: w * 0.5, y: h * 0.44), angleDeg: 0, length: h * 0.11, width: w * 0.07),
                     with: .color(p.foliage))
            ctx.fill(petalPath(base: CGPoint(x: w * 0.5, y: h * 0.375), angleDeg: 0, length: h * 0.045, width: w * 0.05),
                     with: .color(p.bloom))
        }
    }

    @ViewBuilder static func bloom(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let center = CGPoint(x: w * 0.5, y: h * 0.36)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.50), bow: w * 0.03),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
            drawShieldLeaf(ctx, center: CGPoint(x: w * 0.30, y: h * 0.66), radius: w * 0.12,
                           fill: p.foliage, vein: p.foliageDeep, veinWidth: w * 0.006)
            drawShieldLeaf(ctx, center: CGPoint(x: w * 0.70, y: h * 0.60), radius: w * 0.105,
                           fill: p.foliageDeep, vein: p.foliage, veinWidth: w * 0.006)
            // open trumpet: 5 broad rounded petals in a shallow funnel
            petalRing(ctx, center: center, count: 5, baseRadius: w * 0.05, length: h * 0.155, width: w * 0.15, color: p.bloomDeep, phaseDeg: 4)
            petalRing(ctx, center: center, count: 5, baseRadius: w * 0.04, length: h * 0.145, width: w * 0.145, color: p.bloom, phaseDeg: 0)
            // nectar guide lines radiating from the throat
            var guides = Path()
            for i in 0..<5 {
                let t = Double(i) / 5 * 2 * .pi
                guides.move(to: center)
                guides.addLine(to: CGPoint(x: center.x + CGFloat(sin(t)) * w * 0.075,
                                           y: center.y - CGFloat(cos(t)) * w * 0.075))
            }
            ctx.stroke(guides, with: .color(p.bloomDeep), style: StrokeStyle(lineWidth: w * 0.012, lineCap: .round))
            // throat
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - w * 0.045, y: center.y - w * 0.045, width: w * 0.09, height: w * 0.09)),
                     with: .color(p.bloomHighlight))
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - w * 0.02, y: center.y - w * 0.02, width: w * 0.04, height: w * 0.04)),
                     with: .color(p.center))
        }
    }
}
