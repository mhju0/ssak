import SpriteKit

/// The scroll: composited ink layers over living hanji paper. L0 (paper) only for now.
final class WorldScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)

    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
        paper.shader = PaperShader.make()
        addChild(paper)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let sizeUniform = vector_float2(Float(size.width), Float(size.height))
        paper.position = center
        paper.size = size
        paper.shader?.uniformNamed("u_size")?.vectorFloat2Value = sizeUniform
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

    private static let source = """
    float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
    }

    float vnoise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        vec2 u = f * f * (3.0 - 2.0 * f);
        return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
                   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
    }

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
