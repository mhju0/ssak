import SpriteKit
import GameKernel

/// The path ritual: the sky's litter strewn on paper, cleared by dragging a
/// finger across it — ink leaves scatter and fade (no XP, spec §2). When the
/// last piece is gone, `onCleared` fires so the view can persist the swept sky.
final class SweepScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    var kind: Litter = .leaves
    var onCleared: (() -> Void)?

    private var remaining = 0
    private var cleared = false
    private var pendingSpawn = false
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
        if pendingSpawn { spawn() }
    }

    func spawnLitter() {
        pendingSpawn = true
        guard size.width > 0, size.height > 0 else { return }
        spawn()
    }

    private func spawn() {
        pendingSpawn = false
        cleared = false
        children.filter { $0.name == "litter" }.forEach { $0.removeFromParent() }

        var rng = SeededRandom(seed: 0xC0FFEE)
        let count = 22
        for _ in 0..<count {
            let piece = kind == .snow ? snowFleck(&rng) : leaf(&rng)
            piece.name = "litter"
            piece.position = CGPoint(
                x: (0.12 + 0.76 * frac(&rng)) * size.width,
                y: (0.22 + 0.52 * frac(&rng)) * size.height)
            piece.zPosition = 2
            addChild(piece)
        }
        remaining = count
    }

    private func leaf(_ rng: inout SeededRandom) -> SKSpriteNode {
        let node = SKSpriteNode(texture: StrokeTextures.soft)
        let w = size.width * (0.035 + 0.02 * frac(&rng))
        node.size = CGSize(width: w * 1.7, height: w)
        node.color = ink
        node.colorBlendFactor = 1
        node.alpha = 0.45 + 0.25 * frac(&rng)
        node.zRotation = frac(&rng) * .pi
        return node
    }

    private func snowFleck(_ rng: inout SeededRandom) -> SKSpriteNode {
        let node = SKSpriteNode(texture: StrokeTextures.soft)
        let w = size.width * (0.02 + 0.015 * frac(&rng))
        node.size = CGSize(width: w, height: w)
        node.color = ink
        node.colorBlendFactor = 1
        node.alpha = 0.2 + 0.12 * frac(&rng)
        return node
    }

    // MARK: Sweep

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first { sweep(at: touch.location(in: self)) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first { sweep(at: touch.location(in: self)) }
    }

    private func sweep(at point: CGPoint) {
        var rng = SeededRandom(seed: UInt64(abs(Int(point.x * 131 + point.y)) + 1))
        for node in children where node.name == "litter" {
            guard hypot(node.position.x - point.x, node.position.y - point.y) < size.width * 0.11
            else { continue }
            node.name = nil
            remaining -= 1
            let fling = CGVector(
                dx: (frac(&rng) - 0.5) * size.width * 0.4,
                dy: (frac(&rng) - 0.3) * size.width * 0.4)
            node.run(.sequence([
                .group([
                    .move(by: fling, duration: 0.5),
                    .rotate(byAngle: (frac(&rng) - 0.5) * 4, duration: 0.5),
                    .fadeOut(withDuration: 0.5),
                ]),
                .removeFromParent(),
            ]))
        }
        if remaining <= 0, !cleared {
            cleared = true
            onCleared?()
        }
    }

    private func frac(_ rng: inout SeededRandom) -> CGFloat {
        CGFloat(rng.next() % 10_000) / 10_000
    }
}
