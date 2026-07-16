import SpriteKit

/// L1: one procedural mountain in ink wash — noise ridgeline, wash gradient
/// dissolving into mist, soft ragged edge with pooling. Density is live-tunable
/// (the future hook for day/night and weather).
enum MountainWash {
    static func makeNode() -> SKSpriteNode {
        let node = SKSpriteNode(texture: .flatWhite)
        let shader = SKShader(source: source)
        shader.uniforms = [
            SKUniform(name: "u_size", vectorFloat2: .zero),
            SKUniform(name: "u_density", float: 0.55),
            SKUniform(name: "u_bleed", float: 0),
        ]
        node.shader = shader
        return node
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

    float fbm(vec2 p) {
        return vnoise(p) * 0.55 + vnoise(p * 2.13) * 0.28 + vnoise(p * 4.31) * 0.17;
    }

    // Silhouette: main peak off-center left, lower shoulder right, fbm wiggle.
    float ridge(float x) {
        float peak = exp(-pow((x - 0.36) / 0.21, 2.0)) * 0.20;
        float shoulder = exp(-pow((x - 0.78) / 0.26, 2.0)) * 0.10;
        float wiggle = (fbm(vec2(x * 6.2, 3.7)) - 0.5) * 0.055;
        return 0.55 + peak + shoulder + wiggle;
    }

    // Dry-mountain ink density at uv — sampleable, so wet bleed can pull
    // ink from above.
    float inkAt(vec2 uv, vec2 sizePx) {
        vec2 px = uv * sizePx;

        float r = ridge(uv.x);

        // Ragged brushed edge: gentle low-freq sway + fine tremble.
        float ragged = (vnoise(vec2(px.x * 0.025, 7.3)) - 0.5) * 0.010
                     + (vnoise(vec2(px.x * 0.2, 2.1)) - 0.5) * 0.003;
        float d = r - uv.y + ragged;          // >0 inside the mountain

        // Soft edge band, then dry-brush breakup right at the rim.
        float body = smoothstep(0.0, 0.014, d);
        float rim = 1.0 - smoothstep(0.0, 0.022, d);
        float breakup = mix(1.0, smoothstep(0.25, 0.65, vnoise(px * 0.7)), rim * 0.45);

        // Wash gradient: dense at the ridgeline, fading as it descends.
        float fall = clamp(d / 0.26, 0.0, 1.0);
        float wash = mix(1.0, 0.16, smoothstep(0.0, 1.0, fall));

        // Edge pooling: ink gathers just inside the rim as the wash dries.
        float pool = smoothstep(0.014, 0.002, d) * body * 0.6;

        // Dissolve into the mist band below (fog fades the world to paper).
        float mist = smoothstep(0.30, 0.42, uv.y);

        // Brush-loading blotches + broad soft drag bands.
        float blotch = 0.85 + (fbm(px * 0.012) - 0.5) * 0.42;
        float streak = 1.0 + (vnoise(vec2(px.x * 0.008, px.y * 0.05)) - 0.5) * 0.22;

        return (wash + pool) * body * breakup * mist * blotch * streak;
    }

    void main() {
        float density = inkAt(v_tex_coord, u_size);

        // Wet paper: ink runs downward in uneven columns, more with heavier
        // rain. Each fragment looks up-column for ink that would reach it.
        if (u_bleed > 0.001) {
            float drip = vnoise(vec2(v_tex_coord.x * u_size.x * 0.06, 4.2));
            drip *= drip;
            float run = u_bleed * (0.04 + 0.30 * drip);
            float acc = 0.0;
            for (int i = 1; i <= 8; i++) {
                float t = float(i) / 8.0;
                vec2 above = vec2(v_tex_coord.x, v_tex_coord.y + t * run);
                acc = max(acc, inkAt(above, u_size) * (1.0 - t * 0.8));
            }
            density = max(density, acc * (0.3 + 0.5 * u_bleed));
        }

        density *= u_density;

        vec3 ink = vec3(0.16, 0.155, 0.148);
        gl_FragColor = vec4(ink * density, density);
    }
    """
}
