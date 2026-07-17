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
    /// Vertical scroll rates per depth layer: L1 far drifts slowest, L2 mid
    /// carries the mist, L3 playfield is the world (rate 1), L4 foreground
    /// slides past fastest.
    private enum Parallax {
        static let far: CGFloat = 0.3
        static let mid: CGFloat = 0.55
        // Barely faster than the playfield: enough to read as nearer in
        // motion without tufts drifting far from their ground band.
        static let fore: CGFloat = 1.15
    }

    private let cam = SKCameraNode()
    private let paper = SKSpriteNode(texture: .flatWhite)
    private let farLayer = SKNode()
    private let midLayer = SKNode()
    private let foreLayer = SKNode()
    private let mountain = SKSpriteNode(texture: .flatWhite)
    private let midRidge = SKSpriteNode(texture: .flatWhite)
    private let mist = SKSpriteNode(texture: .flatWhite)
    private var carp: RecipeNode?
    private var keeper: RecipeNode?
    private var keeperMount: SKNode?
    /// Keeper's walk position survives figure rebuilds (rain re-styling).
    private var keeperX: CGFloat?
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

    /// Real night deepens the world to charcoal: 0…1 from the sun
    /// (WorldConditions.darkness). Densifies the wash bakes; the paper
    /// itself stays warm.
    var darkness: Float = 0 {
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

        farLayer.zPosition = 0.5
        farLayer.addChild(mountain)
        addChild(farLayer)

        midLayer.zPosition = 0.8
        midRidge.xScale = -1     // the far ridge, mirrored: a second range
        midLayer.addChild(midRidge)
        mist.zPosition = 0.1
        midLayer.addChild(mist)
        addChild(midLayer)

        foreLayer.zPosition = 3
        addChild(foreLayer)
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

        setCameraY(size.height / 2 + cameraFraction * (worldHeight - size.height))
        layoutParallax()
        bakeBackground()
        layoutDressing()
        layoutFigures(reveal: true)
    }

    /// Anchors each parallax element. A sprite at layer-local y₀ appears at
    /// screen offset (y₀ − rate·cameraY), so anchors are solved from "be at
    /// screen offset s when the camera is at c": y₀ = s + rate·c.
    private func layoutParallax() {
        let zoneHeight = size.height
        let cameraTop = worldHeight - zoneHeight / 2

        // L1: the far mountain fills the screen at the peak and sinks slowly
        // as the keeper descends toward the valley.
        mountain.size = size
        mountain.position = CGPoint(x: size.width / 2, y: Parallax.far * cameraTop)

        // L2: a mirrored, lighter second range behind the forest slopes…
        midRidge.size = CGSize(width: size.width, height: zoneHeight * 0.8)
        midRidge.position = CGPoint(
            x: size.width / 2,
            y: -0.15 * zoneHeight + Parallax.mid * 3.5 * zoneHeight)
        // …dissolving into a paper-tone mist band below it.
        mist.size = CGSize(width: size.width, height: zoneHeight * 0.55)
        mist.position = CGPoint(
            x: size.width / 2,
            y: Parallax.mid * 3.0 * zoneHeight)
        mist.texture = Self.mistTexture

        // L4: grass tufts that slide past in the foreground.
        foreLayer.removeAllChildren()
        guard let view else { return }
        let tufts: [(camera: CGFloat, x: CGFloat, screenOffset: CGFloat)] = [
            (0.5, 0.12, -0.38), (1.5, 0.82, -0.40), (2.5, 0.08, -0.42), (3.5, 0.86, -0.38),
        ]
        for tuft in tufts {
            let node = RecipeNode(recipe: Recipes.grassTuft, scale: size.width * 0.14)
            node.showInstantly()
            let frame = node.calculateAccumulatedFrame()
            let sprite = SKSpriteNode(texture: view.texture(from: node))
            sprite.size = frame.size
            sprite.position = CGPoint(
                x: size.width * tuft.x + frame.midX,
                y: tuft.screenOffset * zoneHeight
                    + Parallax.fore * tuft.camera * zoneHeight + frame.midY)
            foreLayer.addChild(sprite)
        }
    }

    /// Paper-tone gradient band — ink-wash mist is paper showing through.
    private static let mistTexture: SKTexture = {
        let size = CGSize(width: 8, height: 128)
        let paperTone = UIColor(red: 0.937, green: 0.912, blue: 0.852, alpha: 1)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colors = [
                paperTone.withAlphaComponent(0).cgColor,
                paperTone.withAlphaComponent(0.85).cgColor,
                paperTone.withAlphaComponent(0).cgColor,
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray, locations: [0, 0.5, 1])!
            context.cgContext.drawLinearGradient(
                gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        return SKTexture(image: image)
    }()

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

    // MARK: The keeper walks

    /// Tap: the keeper walks along the path corridor toward the tapped
    /// x at a calm pace. Mid-walk taps retarget; arrival settles back to
    /// the standing pose.
    func walkKeeper(towardSceneX x: CGFloat) {
        guard let mount = keeperMount, let keeper else { return }
        let margin = size.width * 0.08
        let target = min(max(x, margin), size.width - margin)
        let distance = abs(target - mount.position.x)
        guard distance > 4 else { return }

        // Face the direction of travel (mirror in place).
        mount.xScale = target < mount.position.x ? -1 : 1

        // Gentle walk-bob on the figure while the mount travels.
        if keeper.action(forKey: "bob") == nil {
            let rise = SKAction.moveBy(x: 0, y: 2.5, duration: 0.32)
            rise.timingMode = .easeInEaseOut
            keeper.run(.repeatForever(.sequence([rise, rise.reversed()])), withKey: "bob")
        }

        mount.removeAction(forKey: "walk")
        let pace = size.width * 0.12   // calm: ~8s across the screen
        let walk = SKAction.moveTo(x: target, duration: distance / pace)
        walk.timingMode = .easeInEaseOut
        mount.run(.sequence([
            walk,
            .run { [weak self] in self?.settleKeeper() },
        ]), withKey: "walk")
        keeperX = target
    }

    private func settleKeeper() {
        guard let keeper else { return }
        keeper.removeAction(forKey: "bob")
        let settle = SKAction.moveTo(y: 0, duration: 0.2)
        settle.timingMode = .easeOut
        keeper.run(settle)
    }

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

        // Layers offset by (1 − rate)·cameraY scroll at rate× camera speed.
        let cameraY = cam.position.y
        farLayer.position.y = cameraY * (1 - Parallax.far)
        midLayer.position.y = cameraY * (1 - Parallax.mid)
        foreLayer.position.y = cameraY * (1 - Parallax.fore)

        let zone = Zone.at(cameraY: cameraY, screenHeight: size.height)
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

        // The continuous ink-density curve: night thickens the washes
        // toward charcoal.
        let nightDensity = inkDensity * (1 + 0.8 * darkness)

        let mountainSource = MountainWash.makeNode()
        mountainSource.size = size
        mountainSource.shader?.uniformNamed("u_size")?.vectorFloat2Value = sizeUniform
        mountainSource.shader?.uniformNamed("u_density")?.floatValue = nightDensity
        mountainSource.shader?.uniformNamed("u_bleed")?.floatValue = rainBleed
        mountain.texture = view.texture(from: mountainSource)

        // L2 re-bakes the same composition much lighter — depth by wash
        // density, per the art-direction hierarchy. Fresh node again: a
        // once-rendered node's uniform edits can bake stale (#9).
        let ridgeSource = MountainWash.makeNode()
        ridgeSource.size = size
        ridgeSource.shader?.uniformNamed("u_size")?.vectorFloat2Value = sizeUniform
        ridgeSource.shader?.uniformNamed("u_density")?.floatValue = nightDensity * 0.4
        ridgeSource.shader?.uniformNamed("u_bleed")?.floatValue = rainBleed * 0.5
        midRidge.texture = view.texture(from: ridgeSource)
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

        // The keeper rides a mount node anchored at his feet-center, so
        // facing flips mirror in place and the walk-bob moves only the
        // figure, not the mount.
        let keeperNode = RecipeNode(
            recipe: Recipes.keeperStanding,
            scale: size.height * 0.055
        )
        let keeperFrame = keeperNode.calculateAccumulatedFrame()
        keeperNode.position = CGPoint(x: -keeperFrame.midX, y: 0)
        let mount = SKNode()
        mount.position = CGPoint(
            x: keeperX ?? size.width * 0.62,
            y: zoneHeight * CGFloat(Zone.hermitage.rawValue) + zoneHeight * 0.42)
        mount.zPosition = 2
        mount.addChild(keeperNode)
        addChild(mount)
        keeper = keeperNode
        keeperMount = mount

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
