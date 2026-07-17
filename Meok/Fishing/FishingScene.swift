import SpriteKit
import GameKernel
import StrokeEngine

/// The focused fishing view's canvas: paper, a few water washes, the line
/// and bobber, and the catch painting itself in. All stroke-drawn; ripples
/// are ink rings (the rain-puddle idiom).
final class FishingScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var water: RecipeNode?
    private var bobber: RecipeNode?
    private var line: SKShapeNode?
    private var fishNode: RecipeNode?
    /// Rain soaks the water washes (set from live conditions before cast).
    var wetness: CGFloat = 0

    private let ink = UIColor.meokInk
    private var bobberRest: CGPoint { CGPoint(x: size.width * 0.44, y: size.height * 0.40) }

    /// Three light washes and two reeds — the pond in six strokes.
    private static let waterRecipe = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.02, 0.30, pressure: 0.35),
            StrokePoint(0.55, 0.315, pressure: 0.6),
            StrokePoint(0.98, 0.295, pressure: 0.3),
        ], width: 0.05, ink: 0.30, dryness: 0.35, pooling: 0.2, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.05, 0.21, pressure: 0.4),
            StrokePoint(0.50, 0.22, pressure: 0.55),
            StrokePoint(0.95, 0.205, pressure: 0.25),
        ], width: 0.045, ink: 0.26, dryness: 0.4, pooling: 0.2, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.10, 0.125, pressure: 0.35),
            StrokePoint(0.60, 0.135, pressure: 0.5),
            StrokePoint(0.92, 0.12, pressure: 0.2),
        ], width: 0.04, ink: 0.22, dryness: 0.45, pooling: 0.15, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.88, 0.31, pressure: 0.4),
            StrokePoint(0.86, 0.55, pressure: 0.1),
        ], width: 0.012, ink: 0.6, dryness: 0.3, pooling: 0.15, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.92, 0.30, pressure: 0.4),
            StrokePoint(0.93, 0.50, pressure: 0.08),
        ], width: 0.012, ink: 0.55, dryness: 0.3, pooling: 0.15, duration: 0.25),
    ])

    /// A quill float: knob and stem.
    private static let bobberRecipe = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.5, 0.95, pressure: 0.45),
            StrokePoint(0.5, 0.55, pressure: 0.6),
        ], width: 0.11, ink: 0.85, dryness: 0.1, pooling: 0.2, duration: 0.15),
        Stroke(points: [
            StrokePoint(0.5, 0.55, pressure: 0.95),
            StrokePoint(0.5, 0.35, pressure: 1.0),
        ], width: 0.30, ink: 0.92, dryness: 0.05, pooling: 0.5, duration: 0.15),
    ])

    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
        backgroundColor = .white
        paper.shader = PaperShader.make()
        addChild(paper)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }
        paper.position = CGPoint(x: size.width / 2, y: size.height / 2)
        paper.size = size
        paper.shader?.uniformNamed("u_size")?.vectorFloat2Value =
            vector_float2(Float(size.width), Float(size.height))
        layoutWater()
        // A cast requested before the first layout (autopilot fires from
        // onAppear) lands once the scene knows its size.
        if castShown, bobber == nil { layoutCast() }
    }

    private func layoutWater() {
        water?.removeFromParent()
        let node = RecipeNode(
            recipe: Self.waterRecipe,
            style: RenderStyle(wetness: wetness),
            scale: size.width)
        node.position = .zero
        node.zPosition = 1
        node.showInstantly()
        addChild(node)
        water = node
    }

    // MARK: Cast

    private var castShown = false

    func showCast() {
        clear()
        castShown = true
        layoutCast()
    }

    private func layoutCast() {
        guard size.width > 0, size.height > 0 else { return }
        let node = RecipeNode(recipe: Self.bobberRecipe, scale: 46)
        node.position = CGPoint(
            x: bobberRest.x - 23, y: bobberRest.y - 23 + 30)
        node.zPosition = 3
        node.showInstantly()
        node.alpha = 0
        addChild(node)
        node.run(.group([
            .fadeIn(withDuration: 0.12),
            .moveBy(x: 0, y: -30, duration: 0.18),
        ]))
        run(.sequence([.wait(forDuration: 0.18), .run { [weak self] in
            self?.ripple(strength: 0.8)
        }]))
        bobber = node

        let path = UIBezierPath()
        path.move(to: CGPoint(x: size.width + 4, y: size.height * 0.62))
        path.addQuadCurve(
            to: CGPoint(x: bobberRest.x, y: bobberRest.y + 20),
            controlPoint: CGPoint(x: size.width * 0.72, y: size.height * 0.54))
        let lineNode = SKShapeNode(path: path.cgPath)
        lineNode.strokeColor = ink.withAlphaComponent(0.4)
        lineNode.lineWidth = 1.2
        lineNode.zPosition = 2
        addChild(lineNode)
        line = lineNode
    }

    // MARK: The visual mirror

    /// The bobber trembles in the species' bite pattern — same envelope as
    /// the haptics and audio.
    func playTremble(_ taps: [BiteTap]) {
        guard let bobber else { return }
        for tap in taps {
            bobber.run(.sequence([.wait(forDuration: tap.offset), shake(tap)]))
            if tap.intensity >= 0.6 {
                run(.sequence([.wait(forDuration: tap.offset), .run { [weak self] in
                    self?.ripple(strength: CGFloat(tap.intensity) * 0.6)
                }]))
            }
        }
    }

    private func shake(_ tap: BiteTap) -> SKAction {
        let steps = max(2, Int(tap.duration / 0.05))
        var actions: [SKAction] = []
        for _ in 0..<steps {
            let dx = CGFloat.random(in: -1...1) * 3 * tap.intensity
            let dy = CGFloat.random(in: -1...0.3) * 5 * tap.intensity
            actions.append(.moveBy(x: dx, y: dy, duration: 0.045))
            actions.append(.moveBy(x: -dx, y: -dy, duration: 0.045))
        }
        return .sequence(actions)
    }

    func strikeFlourish() {
        bobber?.run(.sequence([
            .moveBy(x: 0, y: -16, duration: 0.1),
            .moveBy(x: 0, y: 16, duration: 0.25),
        ]))
        ripple(strength: 1)
    }

    /// The line "sings" — visual mirror of the sharp fight haptic.
    func singShiver() {
        line?.run(.repeat(.sequence([
            .moveBy(x: 2, y: 0, duration: 0.04),
            .moveBy(x: -2, y: 0, duration: 0.04),
        ]), count: 6))
        bobber?.run(shake(BiteTap(offset: 0, intensity: 0.9, sharpness: 1, duration: 0.4)))
    }

    func showSlip() {
        ripple(strength: 0.5)
        bobber?.run(.sequence([.fadeOut(withDuration: 0.4), .removeFromParent()]))
        line?.run(.sequence([.fadeOut(withDuration: 0.4), .removeFromParent()]))
        bobber = nil
        line = nil
    }

    // MARK: Catch

    func showCatch(recipe: StrokeRecipe) {
        ripple(strength: 1)
        bobber?.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
        line?.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
        bobber = nil
        line = nil

        let scale = size.width * 0.72
        let node = RecipeNode(recipe: recipe, scale: scale)
        node.position = CGPoint(
            x: size.width / 2 - scale / 2,
            y: size.height * 0.56 - scale / 2)
        node.zPosition = 5
        addChild(node)
        node.reveal(after: 0.25)
        fishNode = node
    }

    func clear() {
        castShown = false
        for node in [bobber, fishNode] as [SKNode?] {
            node?.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
        }
        line?.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
        bobber = nil
        fishNode = nil
        line = nil
    }

    /// An ink ring blooming on the water — the puddle idiom.
    private func ripple(strength: CGFloat) {
        let ring = SKShapeNode(circleOfRadius: 7)
        ring.position = bobberRest
        ring.strokeColor = ink.withAlphaComponent(0.35 * strength + 0.1)
        ring.lineWidth = 1.4
        ring.zPosition = 2
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 4.5, duration: 0.9), .fadeOut(withDuration: 0.9)]),
            .removeFromParent(),
        ]))
    }
}
