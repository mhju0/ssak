import SpriteKit
import GameKernel
import StrokeEngine

/// The canvas: the chosen composition laid out as faint ghost strokes the
/// player traces one at a time (spec §2 — guided brushstrokes; authorship
/// without the ability to ruin it). Each traced stroke inks in, its darkness
/// varying subtly with how deliberately it was drawn. The live sky is baked in
/// via RenderStyle. At mastery, the red seal — the game's only colour — stamps.
final class PaintingScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var ghosts: [SKNode] = []
    private var revealed = 0
    private var dragStart: CGPoint?
    private var dragLength: CGFloat = 0

    /// Fires as each stroke is inked (revealed, total), and when all are done.
    var onProgress: ((Int, Int) -> Void)?
    var onComplete: (() -> Void)?

    private let ghostAlpha: CGFloat = 0.16

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
        // Lay the ghosts out once the size is known — but never re-lay after
        // tracing has begun (would revert inked strokes to ghost).
        if ghosts.isEmpty, let pending { setComposition(pending.recipe, wetness: pending.wetness) }
    }

    private var pending: (recipe: StrokeRecipe, wetness: CGFloat)?

    /// Lay the composition out as ghost strokes on a large canvas.
    func setComposition(_ recipe: StrokeRecipe, wetness: CGFloat) {
        pending = (recipe, wetness)
        guard size.width > 0, size.height > 0 else { return }
        ghosts.forEach { $0.removeFromParent() }
        ghosts = []
        revealed = 0

        let scale = size.width * 0.92
        let origin = CGPoint(x: size.width / 2 - scale / 2, y: size.height * 0.54 - scale / 2)
        for stroke in recipe.strokes {
            let node = RecipeNode(
                recipe: StrokeRecipe(strokes: [stroke]),
                style: RenderStyle(wetness: wetness), scale: scale)
            node.position = origin
            node.zPosition = 3
            node.showInstantly()
            node.alpha = ghostAlpha
            addChild(node)
            ghosts.append(node)
        }
        onProgress?(0, ghosts.count)
    }

    // MARK: Tracing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragStart = touches.first?.location(in: self)
        dragLength = 0
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let previous = dragStart else { return }
        let point = touch.location(in: self)
        dragLength += hypot(point.x - previous.x, point.y - previous.y)
        dragStart = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragLength > size.width * 0.05 else { return }  // a real stroke, not a tap
        // A more deliberate (longer) trace lays fuller ink — subtle character.
        let character = min(1, 0.72 + dragLength / (size.width * 0.9) * 0.28)
        inkNext(character: character)
        dragStart = nil
    }

    /// For the harness: ink the next stroke without a real drag.
    func autoTrace() { inkNext(character: 0.9) }

    private func inkNext(character: CGFloat) {
        guard revealed < ghosts.count else { return }
        ghosts[revealed].run(.fadeAlpha(to: character, duration: 0.3))
        revealed += 1
        onProgress?(revealed, ghosts.count)
        if revealed >= ghosts.count { onComplete?() }
    }

    // MARK: The seal

    /// The red seal (낙관) — the sanctioned exception to the monochrome pillar.
    func stampSeal() {
        let side = size.width * 0.07
        let seal = SKShapeNode(rect: CGRect(x: 0, y: 0, width: side, height: side), cornerRadius: side * 0.12)
        seal.position = CGPoint(x: size.width * 0.74, y: size.height * 0.20)
        seal.fillColor = UIColor(red: 0.72, green: 0.14, blue: 0.11, alpha: 0.92)
        seal.strokeColor = .clear
        seal.zPosition = 6
        seal.setScale(0.1)
        addChild(seal)
        seal.run(.sequence([.scale(to: 1, duration: 0.18)]))
        // A hint of a carved mark, in the paper colour.
        let mark = SKShapeNode(rectOf: CGSize(width: side * 0.42, height: side * 0.42))
        mark.position = CGPoint(x: seal.position.x + side / 2, y: seal.position.y + side / 2)
        mark.strokeColor = UIColor(white: 0.96, alpha: 0.8)
        mark.lineWidth = 1.4
        mark.zPosition = 7
        addChild(mark)
    }
}
