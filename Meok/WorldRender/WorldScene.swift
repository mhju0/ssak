import GameKernel
import SpriteKit
import StrokeEngine

/// The scroll: a vertical world five zones tall (pond at the bottom, peak
/// at the top), thumb-scrolled through an SKCameraNode. The paper (L0) is a
/// camera child — it is the sheet itself and never moves; the ink world
/// scrolls over it.
///
/// Procedural layers are baked to textures and re-baked only when a uniform
/// changes — per-pixel-per-frame shader noise was GPU-bound on device (#12).
final class WorldScene: SKScene {
    private let cam = SKCameraNode()
    private let paper = SKSpriteNode(texture: .flatWhite)
    private let mountain = SKSpriteNode(texture: .flatWhite)
    private var carp: RecipeNode?
    private var keeper: RecipeNode?
    private var carpWetness: CGFloat = 0
    private var bakePending = false
    private var needsBake = false
    private var lastZone: Zone?
    /// When the launch reveal finishes; wetness rebuilds before then must
    /// restart the reveal, not skip it (the paint-in is the signature moment,
    /// and real weather arrives ~1s after launch).
    private var revealUntil = Date.distantPast

    /// Camera altitude as a 0…1 fraction of the world (0 = pond, 1 = peak).
    /// Applied at layout; the harness seeds it for fixed-altitude captures.
    var cameraFraction: CGFloat = 1

    /// Debug overlay hook: fires when the camera crosses into another zone.
    var onZoneChange: ((Zone) -> Void)?

    var worldHeight: CGFloat { size.height * CGFloat(Zone.allCases.count) }

    /// Overall wash strength of the mountain layer (0 = bare paper).
    var inkDensity: Float = 0.55 {
        didSet { scheduleBake() }
    }

    /// How hard the rain runs the ink, 0…1 (WorldConditions.rainIntensity).
    var rainBleed: Float = 0 {
        didSet {
            scheduleBake()
            // The carp soaks with the rain. Stamps are baked per style, so
            // rebuild only when wetness actually moved — with a threshold
            // small enough that even drizzle (~0.07) registers.
            let wetness = CGFloat(rainBleed) * 0.7
            if abs(wetness - carpWetness) > 0.02 {
                layoutFigures(reveal: Date() < revealUntil)
            }
        }
    }

    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
        camera = cam
        addChild(cam)
        paper.zPosition = -100
        cam.addChild(paper)
        mountain.zPosition = 1
        addChild(mountain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if needsBake { bakeBackground() }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }

        paper.size = size
        paper.position = .zero

        // The mountain composition fills the top screen — the peak zone.
        mountain.size = size
        mountain.position = CGPoint(x: size.width / 2, y: worldHeight - size.height / 2)

        setCameraY(size.height / 2 + cameraFraction * (worldHeight - size.height))
        bakeBackground()
        layoutDressing()
        layoutFigures(reveal: true)
    }

    // MARK: Zone dressing

    private var dressing: [SKNode] = []

    /// Places each zone's props. Props are static, so each is flattened to
    /// a single sprite at layout — dressing costs one node per prop instead
    /// of hundreds of dab sprites (device perf lesson, #12).
    private func layoutDressing() {
        dressing.forEach { $0.removeFromParent() }
        dressing = []
        guard let view else { return }

        for zone in Zone.allCases {
            let zoneBottom = size.height * CGFloat(zone.rawValue)
            for prop in ZoneDressing.props(for: zone) {
                let inkScale = size.width * prop.scale
                let node = RecipeNode(recipe: prop.recipe, scale: inkScale)
                node.showInstantly()

                let frame = node.calculateAccumulatedFrame()
                let sprite = SKSpriteNode(texture: view.texture(from: node))
                sprite.size = frame.size
                sprite.position = CGPoint(
                    x: size.width * prop.x + frame.midX,
                    y: zoneBottom + size.height * prop.y + frame.midY)
                sprite.zPosition = 1.5
                addChild(sprite)
                dressing.append(sprite)
            }
        }
    }

    // MARK: Scrolling

    /// Jumps the camera to an altitude fraction (harness + future wayfinding).
    func parkCamera(atFraction fraction: CGFloat) {
        cameraFraction = fraction
        guard size.height > 0 else { return }
        cam.removeAction(forKey: "flick")
        setCameraY(size.height / 2 + fraction * (worldHeight - size.height))
    }

    /// Drag: positive delta pulls the scroll down (camera climbs).
    func scrollBy(_ deltaY: CGFloat) {
        cam.removeAction(forKey: "flick")
        setCameraY(cam.position.y + deltaY)
    }

    /// Release: decelerate toward where the flick carries (tested kernel math).
    func endScroll(velocity velocityY: CGFloat) {
        let target = ScrollGeometry.flickTarget(
            from: cam.position.y, velocity: velocityY,
            screenHeight: size.height, worldHeight: worldHeight)
        guard abs(target - cam.position.y) > 1 else { return }
        let glide = SKAction.moveTo(y: target, duration: 0.6)
        glide.timingMode = .easeOut
        cam.run(glide, withKey: "flick")
    }

    private func setCameraY(_ y: CGFloat) {
        let clamped = ScrollGeometry.clampedCameraY(
            y, screenHeight: size.height, worldHeight: worldHeight)
        cam.position = CGPoint(x: size.width / 2, y: clamped)
    }

    override func update(_ currentTime: TimeInterval) {
        guard size.height > 0 else { return }
        let zone = Zone.at(cameraY: cam.position.y, screenHeight: size.height)
        if zone != lastZone {
            lastZone = zone
            onZoneChange?(zone)
        }
    }

    // MARK: Baking

    /// Coalesces bursts of uniform changes (slider drags) into one re-bake.
    private func scheduleBake() {
        guard !bakePending else { return }
        bakePending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.bakePending = false
            self?.bakeBackground()
        }
    }

    /// Renders the paper and mountain offscreen into their textures.
    /// Shader nodes are created fresh per bake so every uniform is set
    /// before first render (SKView.texture(from:) can render stale values
    /// for uniforms updated after presentation — issue #9).
    private func bakeBackground() {
        guard let view, size.width > 0, size.height > 0 else {
            needsBake = true
            return
        }
        needsBake = false

        let sizeUniform = vector_float2(Float(size.width), Float(size.height))

        let paperSource = SKSpriteNode(texture: .flatWhite)
        paperSource.size = size
        paperSource.shader = PaperShader.make()
        paperSource.shader?.uniformNamed("u_size")?.vectorFloat2Value = sizeUniform
        paper.texture = view.texture(from: paperSource)

        let mountainSource = MountainWash.makeNode()
        mountainSource.size = size
        mountainSource.shader?.uniformNamed("u_size")?.vectorFloat2Value = sizeUniform
        mountainSource.shader?.uniformNamed("u_density")?.floatValue = inkDensity
        mountainSource.shader?.uniformNamed("u_bleed")?.floatValue = rainBleed
        mountain.texture = view.texture(from: mountainSource)
    }

    // MARK: Figures

    /// The M1 cast in world space: carp in the valley pond, keeper on the
    /// hermitage path at staffage scale.
    private func layoutFigures(reveal: Bool) {
        carp?.removeFromParent()
        keeper?.removeFromParent()
        carpWetness = CGFloat(rainBleed) * 0.7

        let zoneHeight = size.height

        let carpNode = RecipeNode(
            recipe: Recipes.carp,
            style: RenderStyle(wetness: carpWetness),
            scale: size.width * 0.42
        )
        carpNode.position = CGPoint(
            x: size.width * 0.07,
            y: zoneHeight * CGFloat(Zone.valleyPond.rawValue) + zoneHeight * 0.06)
        carpNode.zPosition = 2
        addChild(carpNode)
        carp = carpNode

        let keeperNode = RecipeNode(
            recipe: Recipes.keeperStanding,
            scale: size.height * 0.055
        )
        keeperNode.position = CGPoint(
            x: size.width * 0.62,
            y: zoneHeight * CGFloat(Zone.hermitage.rawValue) + zoneHeight * 0.42)
        keeperNode.zPosition = 2
        addChild(keeperNode)
        keeper = keeperNode

        if reveal {
            let carpEnd = carpNode.reveal(after: 0.5)
            let keeperEnd = keeperNode.reveal(after: carpEnd + 0.3)
            revealUntil = Date().addingTimeInterval(keeperEnd)
        } else {
            carpNode.showInstantly()
            keeperNode.showInstantly()
        }
    }
}
