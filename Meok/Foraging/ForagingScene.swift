import SpriteKit
import GameKernel
import StrokeEngine

/// The foraging clearing: paper, a low grass hint, and a few faint spots
/// where finds wait. Tapping a spot paints the forageable in (its recipe)
/// with an ink ripple — the same stroke idiom as the pond.
final class ForagingScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    /// Rain soaks the finds' washes (set from live conditions before layout).
    var wetness: CGFloat = 0
    /// The view routes a tapped spot's id back to the session.
    var onGather: ((UUID) -> Void)?

    private var markers: [UUID: SKNode] = [:]
    private var scenePositions: [UUID: CGPoint] = [:]
    private var gathered: Set<UUID> = []
    private var pending: [ForagingSession.Spot] = []
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
        // A wander requested before the first layout lands once we know the size.
        if !pending.isEmpty, markers.isEmpty { place(pending) }
    }

    // MARK: Spots

    func layoutSpots(_ spots: [ForagingSession.Spot]) {
        pending = spots
        guard size.width > 0, size.height > 0 else { return }
        place(spots)
    }

    private func place(_ spots: [ForagingSession.Spot]) {
        markers.values.forEach { $0.removeFromParent() }
        children.filter { $0.name == "find" }.forEach { $0.removeFromParent() }
        markers = [:]
        scenePositions = [:]
        gathered = []

        for spot in spots {
            let point = CGPoint(x: spot.position.x * size.width, y: spot.position.y * size.height)
            scenePositions[spot.id] = point

            // A faint smudge — something waits here, tap to find it.
            let marker = SKSpriteNode(texture: StrokeTextures.soft)
            marker.size = CGSize(width: size.width * 0.09, height: size.width * 0.09)
            marker.position = point
            marker.color = ink
            marker.colorBlendFactor = 1
            marker.alpha = 0.22
            marker.zPosition = 2
            addChild(marker)
            markers[spot.id] = marker
            marker.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.34, duration: 1.1),
                .fadeAlpha(to: 0.2, duration: 1.1),
            ])))
        }
    }

    func revealForageable(_ forageable: Forageable, at id: UUID) {
        guard let point = scenePositions[id], let recipe = Recipes.forage[forageable.id] else { return }
        markers[id]?.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        markers[id] = nil
        gathered.insert(id)
        ripple(at: point)

        let scale = size.width * 0.34
        let node = RecipeNode(
            recipe: recipe, style: RenderStyle(wetness: wetness), scale: scale)
        node.name = "find"
        node.position = CGPoint(x: point.x - scale / 2, y: point.y - scale / 2)
        node.zPosition = 3
        addChild(node)
        node.reveal()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nearest = scenePositions
            .filter { !gathered.contains($0.key) }
            .min { hypot($0.value.x - location.x, $0.value.y - location.y)
                 < hypot($1.value.x - location.x, $1.value.y - location.y) }
        guard let nearest,
              hypot(nearest.value.x - location.x, nearest.value.y - location.y) < size.width * 0.24
        else { return }
        onGather?(nearest.key)
    }

    /// An ink ring blooming where a find is gathered — the puddle idiom.
    private func ripple(at point: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 8)
        ring.position = point
        ring.strokeColor = ink.withAlphaComponent(0.4)
        ring.lineWidth = 1.4
        ring.zPosition = 2
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 4, duration: 0.8), .fadeOut(withDuration: 0.8)]),
            .removeFromParent(),
        ]))
    }
}
