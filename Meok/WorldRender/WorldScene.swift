import SpriteKit
import StrokeEngine

/// The scroll: composited ink layers over living hanji paper —
/// L0 paper, L1 mountain wash, and the M0 cast (carp, keeper).
final class WorldScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private let mountain = MountainWash.makeNode()
    private var carp: RecipeNode?
    private var keeper: RecipeNode?
    private var carpWetness: CGFloat = 0
    /// When the launch reveal finishes; wetness rebuilds before then must
    /// restart the reveal, not skip it (the paint-in is the signature moment,
    /// and real weather arrives ~1s after launch).
    private var revealUntil = Date.distantPast

    /// Overall wash strength of the mountain layer (0 = bare paper).
    var inkDensity: Float = 0.55 {
        didSet { mountain.shader?.uniformNamed("u_density")?.floatValue = inkDensity }
    }

    /// How hard the rain runs the ink, 0…1 (WorldConditions.rainIntensity).
    var rainBleed: Float = 0 {
        didSet {
            mountain.shader?.uniformNamed("u_bleed")?.floatValue = rainBleed
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
        paper.shader = PaperShader.make()
        addChild(paper)
        mountain.zPosition = 1
        addChild(mountain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let sizeUniform = vector_float2(Float(size.width), Float(size.height))
        for node in [paper, mountain] {
            node.position = center
            node.size = size
            node.shader?.uniformNamed("u_size")?.vectorFloat2Value = sizeUniform
        }
        layoutFigures(reveal: true)
    }

    /// The M0 composite cast: carp in the valley pond, keeper on the path
    /// at staffage scale.
    private func layoutFigures(reveal: Bool) {
        carp?.removeFromParent()
        keeper?.removeFromParent()
        carpWetness = CGFloat(rainBleed) * 0.7

        let carpNode = RecipeNode(
            recipe: Recipes.carp,
            style: RenderStyle(wetness: carpWetness),
            scale: size.width * 0.42
        )
        carpNode.position = CGPoint(x: size.width * 0.07, y: size.height * 0.03)
        carpNode.zPosition = 2
        addChild(carpNode)
        carp = carpNode

        let keeperNode = RecipeNode(
            recipe: Recipes.keeperStanding,
            scale: size.height * 0.055
        )
        keeperNode.position = CGPoint(x: size.width * 0.66, y: size.height * 0.385)
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

extension SKTexture {
    /// Placeholder quad texture so color-only shader sprites get valid v_tex_coord.
    static let flatWhite: SKTexture = {
        let size = CGSize(width: 4, height: 4)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }()
}

/// L0: procedural hanji — fiber grain, flecks, soft vignette. No image assets.
enum PaperShader {
    static func make() -> SKShader {
        let shader = SKShader(source: source)
        shader.uniforms = [SKUniform(name: "u_size", vectorFloat2: .zero)]
        return shader
    }

    private static let source = ShaderLib.noise2D + """
    void main() {
        vec2 px = v_tex_coord * u_size;

        // Pulp clouds: large soft density variation, the "handmade" tell.
        float mottle = vnoise(px * 0.008) * 0.65 + vnoise(px * 0.021) * 0.35;

        // Long thin fibers: low frequency along the fiber, high across it.
        // Unequal weights so it reads as laid pulp, not woven cloth.
        float fiberH = vnoise(vec2(px.x * 0.012, px.y * 0.45));
        float fiberV = vnoise(vec2(px.x * 0.45, px.y * 0.012));
        float tooth = vnoise(px * 0.18);

        vec3 base = vec3(0.937, 0.912, 0.852);
        float grain = (mottle - 0.5) * 0.05
                    + (fiberH - 0.5) * 0.034
                    + (fiberV - 0.5) * 0.016
                    + (tooth - 0.5) * 0.024;
        vec3 col = base + grain;

        // Sparse darker strands, where a long fiber and local noise coincide.
        float strandH = smoothstep(0.7, 0.95, fiberH * vnoise(px * 0.9));
        float strandV = smoothstep(0.72, 0.95, fiberV * vnoise(px * 0.9 + 41.7));
        col -= (strandH + strandV) * 0.04;

        // Rare tiny fiber flecks.
        float fleck = smoothstep(0.9965, 1.0, hash(floor(px * 0.8)));
        col -= fleck * 0.07;

        // Soft vignette, aspect-corrected.
        vec2 c = v_tex_coord - 0.5;
        c.x *= u_size.x / u_size.y;
        col *= 1.0 - smoothstep(0.32, 0.85, length(c)) * 0.14;

        gl_FragColor = vec4(col, 1.0);
    }
    """
}
