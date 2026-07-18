import SpriteKit
import GameKernel
import StrokeEngine

/// The garden terrace: paper, a row of soil beds, and whatever grows in them
/// rendered at its stage (the session picks recipe + scale). Tapping a bed
/// selects it; watering beads a dew ripple. All stroke-drawn.
final class GardenScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    var wetness: CGFloat = 0
    var onSelectPlot: ((Int) -> Void)?

    private var positions: [Int: CGPoint] = [:]
    private var plantNodes: [Int: RecipeNode] = [:]
    private var bedNodes: [Int: SKNode] = [:]
    private var selection: SKShapeNode?
    private var pending: [GardenSession.PlotRender] = []
    private let ink = UIColor.meokInk

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
        if !pending.isEmpty { layout(pending) }
    }

    func layout(_ plots: [GardenSession.PlotRender]) {
        pending = plots
        guard size.width > 0, size.height > 0 else { return }
        plantNodes.values.forEach { $0.removeFromParent() }
        bedNodes.values.forEach { $0.removeFromParent() }
        plantNodes = [:]
        bedNodes = [:]
        positions = [:]

        for plot in plots {
            let point = CGPoint(x: plot.position.x * size.width, y: plot.position.y * size.height)
            positions[plot.index] = point

            // Soil bed — a low smudge the plant rises from.
            let bed = SKSpriteNode(texture: StrokeTextures.soft)
            bed.size = CGSize(width: size.width * 0.17, height: size.width * 0.035)
            bed.position = point
            bed.color = ink
            bed.colorBlendFactor = 1
            bed.alpha = 0.28
            bed.zPosition = 1
            addChild(bed)
            bedNodes[plot.index] = bed

            guard let recipe = plot.recipe else { continue }
            let drawScale = size.width * 0.30 * plot.scale
            let node = RecipeNode(
                recipe: recipe, style: RenderStyle(wetness: wetness), scale: drawScale)
            node.position = CGPoint(x: point.x - drawScale / 2, y: point.y - drawScale * 0.06)
            node.zPosition = 3
            node.showInstantly()
            addChild(node)
            plantNodes[plot.index] = node
        }
    }

    /// A ring under the selected bed.
    func highlight(_ index: Int?) {
        selection?.removeFromParent()
        selection = nil
        guard let index, let point = positions[index] else { return }
        let ring = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.22, height: size.width * 0.07))
        ring.position = CGPoint(x: point.x, y: point.y - 3)
        ring.strokeColor = ink.withAlphaComponent(0.4)
        ring.lineWidth = 1.2
        ring.zPosition = 2
        addChild(ring)
        selection = ring
    }

    /// Watering beads dew — a ripple and a few rising motes.
    func flourish(at index: Int) {
        guard let point = positions[index] else { return }
        let ring = SKShapeNode(circleOfRadius: 7)
        ring.position = point
        ring.strokeColor = ink.withAlphaComponent(0.35)
        ring.lineWidth = 1.2
        ring.zPosition = 2
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 3.4, duration: 0.7), .fadeOut(withDuration: 0.7)]),
            .removeFromParent(),
        ]))
        for _ in 0..<4 {
            let mote = SKSpriteNode(texture: StrokeTextures.soft)
            let radius = size.width * 0.02
            mote.size = CGSize(width: radius, height: radius)
            mote.color = ink
            mote.colorBlendFactor = 1
            mote.alpha = 0.5
            mote.zPosition = 4
            mote.position = CGPoint(
                x: point.x + CGFloat.random(in: -1...1) * size.width * 0.06, y: point.y)
            addChild(mote)
            mote.run(.sequence([
                .group([
                    .moveBy(x: 0, y: size.width * 0.09, duration: 0.6),
                    .fadeOut(withDuration: 0.6),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nearest = positions.min {
            hypot($0.value.x - location.x, $0.value.y - location.y)
                < hypot($1.value.x - location.x, $1.value.y - location.y)
        }
        guard let nearest,
              hypot(nearest.value.x - location.x, nearest.value.y - location.y) < size.width * 0.16
        else { return }
        onSelectPlot?(nearest.key)
    }
}
