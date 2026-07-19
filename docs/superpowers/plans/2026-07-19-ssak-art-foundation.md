# Ssak Art Foundation & Marigold — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. **Note on execution model:** the *infrastructure* tasks (1–7) are deterministic and suit fresh-subagent transcription. The *art* tasks (8–12) are visual and iterative — they are authored against a render→inspect loop, not transcribed from fixed coordinates. See "Art tasks are authored, not transcribed" below and the Execution Handoff.

**Goal:** Stand up the `SsakArt` SwiftUI package with a headless render-to-PNG verification harness, the shared art scaffolding (palette, pot, sill, shared seed frame, droop effect, `PlantView` dispatcher), and the complete five-stage Marigold lifecycle — the reference set that proves the whole hand-authored-vector pipeline and fixes the aesthetic bar for the remaining five species.

**Architecture:** A new SwiftPM package `SsakArt/` (sibling to `SsakCore/`), depending on `SsakCore` by local path for its `GrowthStage` and `Species`/`SpeciesCatalog` types. Art is authored as SwiftUI `Shape`/`Path`/`View` values — no procedural runtime engine, no AI raster (spec §5.1). A library target `SsakArt` holds cross-platform (iOS 16 / macOS 13) art views plus a `pngData(...)` helper built on `ImageRenderer`. A macOS executable target `SsakArtRender` writes every art view to a PNG under `SsakArt/rendered/` so the drawings can be inspected and iterated without Xcode or a device. A test target asserts the cheap invariants (renders, correct size, stages are mutually distinct, droop changes the output).

**Tech Stack:** Swift 6.3, SwiftUI, `ImageRenderer` (iOS 16 / macOS 13), ImageIO/CoreGraphics for PNG encoding, SwiftPM (`swift build` / `swift run` / `swift test` — no Xcode).

## Global Constraints

- Package name `SsakArt`; sibling directory `SsakArt/` next to `SsakCore/`; depends on SsakCore via `.package(path: "../SsakCore")`. — verbatim.
- Library target `SsakArt` platforms: `.iOS(.v16), .macOS(.v13)` (both — the app is iOS, the harness is macOS). Executable target `SsakArtRender` is macOS-only. — verbatim.
- **Hand-authored static vector art only.** SwiftUI `Path`/`Shape`/`View`. No procedural plant-drawing engine at runtime; no AI raster pipeline. (Spec §5.1.) — verbatim.
- **Six species × five stages** = `GrowthStage` cases `seed, sprout, leaves, bud, bloom` (from SsakCore). Every stage is unique per species; the sole shared frame is **seed-in-soil** (soil mound + subtle species tint). (Spec §5.2.) — verbatim.
- **Detail ramps to the bloom:** sprout/leaves refined but restrained; **bud and bloom are lavish hero art** — the screenshot moment; detail bar = the dense-tonal-petal marigold sample from the design session. (Spec §5.1.) — verbatim.
- **Droop/overwater is one reusable effect** (sag transform + yellow/desaturate tint) layered over any stage — never drawn per stage. (Spec §5.2.) — verbatim.
- Reuse SsakCore types; do **not** redefine `GrowthStage` or species identity/data in SsakArt.
- MIT license, Copyright (c) 2026 Michael Ju (github.com/mhju0). Swift 6 concurrency: `ImageRenderer` is main-actor; render entry points are `@MainActor`, and the executable uses an `@main struct` with `@MainActor static func main()` (a top-level `main.swift` calling main-actor code fails to compile under Swift 6).

---

## Art tasks are authored, not transcribed

The infrastructure tasks (1–7) give exact code. The five Marigold stage tasks (8–12) cannot: the drawing *is* the deliverable, and good vector art is found by rendering and looking, not by transcribing bezier coordinates from a plan. So each art task specifies:

1. **Composition** — what elements appear and how they sit in the frame.
2. **The detail bar** — how refined this stage must be (restrained early → lavish at bud/bloom).
3. **A starting scaffold** — real code that compiles and renders *something* in the right place, so the loop is primed.
4. **The verification** — an automated guard (renders, right size, distinct from the neighbouring stage, droop alters it) **and** a visual gate (render the PNG, open it, judge it against the composition + detail bar; iterate until it holds).

"Passing" an art task means the automated guard is green **and** the rendered PNG has been visually confirmed to meet the composition and detail bar. Iterate the paths in-loop until it does; commit the code that produced the confirmed image.

---

## File Structure

```
SsakArt/
  Package.swift                              # library SsakArt (iOS16/macOS13) + exe SsakArtRender (macOS) + test target
  Sources/
    SsakArt/
      SpeciesPalette.swift                   # per-species color sets, keyed by SsakCore species id
      Backdrop.swift                         # Sill + Pot shapes (shared across all species/stages)
      SeedSoil.swift                         # shared seed-in-soil frame + species tint
      Droop.swift                            # Droop ViewModifier + .droop(_:) extension (the one reusable effect)
      PlantView.swift                        # dispatcher: (species, stage, droop) -> composed scene
      PNGRenderer.swift                      # pngData(for:size:scale:) via ImageRenderer (macOS/iOS 16+)
      Marigold.swift                         # MarigoldArt: sprout/leaves/bud/bloom stage views
    SsakArtRender/
      Render.swift                           # @main; writes every (species,stage) + droop variants to rendered/*.png
  Tests/
    SsakArtTests/
      RenderInvariantsTests.swift            # renders, size, stage-distinctness, droop-changes-output
  rendered/                                  # PNG outputs for inspection (gitignored except a curated few)
  .gitignore
```

Responsibilities: **SpeciesPalette** owns color, since SsakCore's `Species` carries no color. **Backdrop** and **SeedSoil** are the shared frame every species reuses. **Droop** is the single stress effect. **PlantView** is the only thing the app (Plan 3+) needs to know about — everything else is an implementation detail behind it. **PNGRenderer** is the shared render helper used by both the executable and the tests, so the "it renders and is distinct" invariants are checked the same way they are produced.

---

### Task 1: Scaffold SsakArt package + prove the render loop

**Files:**
- Create: `SsakArt/Package.swift`
- Create: `SsakArt/Sources/SsakArt/PNGRenderer.swift`
- Create: `SsakArt/Sources/SsakArtRender/Render.swift`
- Create: `SsakArt/.gitignore`
- Test: `SsakArt/Tests/SsakArtTests/RenderInvariantsTests.swift`

**Interfaces:**
- Produces: `SsakArt.pngData(for view: some View, size: CGSize, scale: CGFloat = 3) -> Data?` (`@MainActor`). Encodes a SwiftUI view to PNG `Data` via `ImageRenderer` → `cgImage` → ImageIO. Returns nil if rendering fails.
- Produces: executable `SsakArtRender` that writes PNGs to `SsakArt/rendered/`.

- [ ] **Step 1: Write `Package.swift`**

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SsakArt",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "SsakArt", targets: ["SsakArt"]),
    ],
    dependencies: [
        .package(path: "../SsakCore"),
    ],
    targets: [
        .target(name: "SsakArt", dependencies: [.product(name: "SsakCore", package: "SsakCore")]),
        .executableTarget(name: "SsakArtRender", dependencies: ["SsakArt",
            .product(name: "SsakCore", package: "SsakCore")]),
        .testTarget(name: "SsakArtTests", dependencies: ["SsakArt",
            .product(name: "SsakCore", package: "SsakCore")]),
    ]
)
```

- [ ] **Step 2: Write `PNGRenderer.swift`**

```swift
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// Render any SwiftUI view to PNG bytes. Main-actor because ImageRenderer is.
@MainActor
public func pngData(for view: some View, size: CGSize, scale: CGFloat = 3) -> Data? {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = scale
    guard let cg = renderer.cgImage else { return nil }
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(
        data as CFMutableData, UTType.png.identifier as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(dest, cg, nil)
    guard CGImageDestinationFinalize(dest) else { return nil }
    return data as Data
}
```

- [ ] **Step 3: Write `Render.swift` (placeholder scene proves the loop)**

```swift
import SwiftUI
import SsakArt
import SsakCore

@main
struct Render {
    @MainActor static func main() {
        let out = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("rendered", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let placeholder = ZStack {
            Color(red: 0.98, green: 0.95, blue: 0.88)
            Circle().fill(.orange).frame(width: 80, height: 80)
        }
        if let data = pngData(for: placeholder, size: CGSize(width: 120, height: 140)) {
            try? data.write(to: out.appendingPathComponent("_loop_check.png"))
            print("wrote \(out.appendingPathComponent("_loop_check.png").path)")
        } else {
            print("RENDER FAILED"); exit(1)
        }
    }
}
```

- [ ] **Step 4: Write `.gitignore`**

```
rendered/*.png
!rendered/.gitkeep
.build/
```

- [ ] **Step 5: Write the failing invariant test**

`SsakArt/Tests/SsakArtTests/RenderInvariantsTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import SsakArt

final class RenderInvariantsTests: XCTestCase {
    @MainActor
    func testRendersNonEmptyPNGOfExpectedSize() {
        let view = ZStack { Color.orange; Circle().fill(.white).frame(width: 40, height: 40) }
        let data = pngData(for: view, size: CGSize(width: 100, height: 120), scale: 2)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 100)          // real image, not empty
        XCTAssertEqual(pngPixelSize(data!), CGSize(width: 200, height: 240))  // size * scale
    }
}

/// Read width/height back out of PNG bytes to confirm the render honoured size*scale.
func pngPixelSize(_ data: Data) -> CGSize {
    guard let src = CGImageSourceCreateWithData(data as CFData, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return .zero }
    return CGSize(width: img.width, height: img.height)
}
```
(`CGImageSourceCreateWithData` needs `import ImageIO` — add it to the test file.)

- [ ] **Step 6: Run test — expect FAIL first, then pass once code compiles**

Run: `cd SsakArt && swift test 2>&1 | tail -5`
Expected: initially fails to build until `pngData` exists; once Steps 1–2 are in, the test passes (non-nil, >100 bytes, 200×240).

- [ ] **Step 7: Run the harness end to end and inspect**

Run: `cd SsakArt && swift run SsakArtRender && ls -la rendered/`
Expected: `rendered/_loop_check.png` exists. **Open it and confirm** an orange circle on cream — the loop works. Add `rendered/.gitkeep` so the dir is tracked.

- [ ] **Step 8: Commit**

```bash
git checkout -b ssak-art-foundation
git add SsakArt && git commit -m "feat(art): scaffold SsakArt package + headless render-to-PNG loop"
```

---

### Task 2: SpeciesPalette

**Files:**
- Create: `SsakArt/Sources/SsakArt/SpeciesPalette.swift`
- Test: extend `RenderInvariantsTests.swift`

**Interfaces:**
- Consumes: `SsakCore.SpeciesCatalog` (species `id` strings: `marigold, nasturtium, cosmos, zinnia, sunflower, morning_glory`).
- Produces: `struct SpeciesPalette { let bloom: Color; let bloomDeep: Color; let bloomHighlight: Color; let foliage: Color; let foliageDeep: Color; let seedTint: Color }` and `static func palette(for speciesID: String) -> SpeciesPalette` returning a defined palette for every catalog id (marigold fully tuned now; others get sensible provisional values, finalized in the remaining-species follow-up).

- [ ] **Step 1: Write the failing test**

```swift
func testPaletteExistsForEveryCatalogSpecies() {
    for s in SpeciesCatalog.all {
        // must not trap / must return a distinct-ish bloom color per species
        _ = SpeciesPalette.palette(for: s.id)
    }
    XCTAssertNotEqual(SpeciesPalette.palette(for: "marigold").bloom,
                      SpeciesPalette.palette(for: "cosmos").bloom)
}
```
(Add `import SsakCore` to the test file.)

- [ ] **Step 2: Run — expect FAIL** (`SpeciesPalette` undefined). `cd SsakArt && swift test --filter testPaletteExistsForEveryCatalogSpecies`

- [ ] **Step 3: Implement `SpeciesPalette.swift`**

```swift
import SwiftUI

public struct SpeciesPalette {
    public let bloom: Color         // primary petal
    public let bloomDeep: Color     // shadowed petal / throat
    public let bloomHighlight: Color// petal tip / catch-light
    public let foliage: Color       // leaf/stem
    public let foliageDeep: Color   // leaf shadow
    public let seedTint: Color      // subtle tint on the shared seed-soil frame

    public static func palette(for speciesID: String) -> SpeciesPalette {
        switch speciesID {
        case "marigold":
            return .init(bloom: Color(red: 0.98, green: 0.60, blue: 0.10),
                         bloomDeep: Color(red: 0.80, green: 0.32, blue: 0.05),
                         bloomHighlight: Color(red: 1.00, green: 0.82, blue: 0.30),
                         foliage: Color(red: 0.30, green: 0.52, blue: 0.28),
                         foliageDeep: Color(red: 0.18, green: 0.36, blue: 0.20),
                         seedTint: Color(red: 0.86, green: 0.55, blue: 0.20))
        // Provisional until the remaining-species follow-up tunes each against its render.
        case "nasturtium":    return marigoldLike(hueBloom: Color(red: 0.96, green: 0.44, blue: 0.12))
        case "cosmos":        return marigoldLike(hueBloom: Color(red: 0.90, green: 0.45, blue: 0.66))
        case "zinnia":        return marigoldLike(hueBloom: Color(red: 0.86, green: 0.20, blue: 0.30))
        case "sunflower":     return marigoldLike(hueBloom: Color(red: 0.98, green: 0.78, blue: 0.12))
        case "morning_glory": return marigoldLike(hueBloom: Color(red: 0.42, green: 0.40, blue: 0.82))
        default:              return marigoldLike(hueBloom: Color(red: 0.98, green: 0.60, blue: 0.10))
        }
    }

    private static func marigoldLike(hueBloom: Color) -> SpeciesPalette {
        .init(bloom: hueBloom,
              bloomDeep: hueBloom.opacity(0.75),
              bloomHighlight: hueBloom.opacity(0.55),
              foliage: Color(red: 0.30, green: 0.52, blue: 0.28),
              foliageDeep: Color(red: 0.18, green: 0.36, blue: 0.20),
              seedTint: Color(red: 0.80, green: 0.62, blue: 0.34))
    }
}
```

- [ ] **Step 4: Run — expect PASS.** `cd SsakArt && swift test --filter testPaletteExistsForEveryCatalogSpecies`

- [ ] **Step 5: Commit**
```bash
git add SsakArt && git commit -m "feat(art): per-species palette keyed by SsakCore species id"
```

---

### Task 3: Backdrop — Sill + Pot

**Files:**
- Create: `SsakArt/Sources/SsakArt/Backdrop.swift`
- Modify: `SsakArt/Sources/SsakArtRender/Render.swift` (render a Backdrop sample)

**Interfaces:**
- Produces: `struct Sill: View` (a warm windowsill band + soft wall behind, chrome-light per spec §6 so it's screenshot-ready). `struct Pot: View` (a simple terracotta pot the plant sits in). Both size to their container.

- [ ] **Step 1: Implement `Backdrop.swift`**

```swift
import SwiftUI

public struct Sill: View {
    public init() {}
    public var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                Color(red: 0.98, green: 0.95, blue: 0.88)                 // warm wall
                Rectangle()                                              // sill board
                    .fill(Color(red: 0.90, green: 0.84, blue: 0.72))
                    .frame(height: h * 0.16)
            }
        }
    }
}

public struct Pot: View {
    public init() {}
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in                                                  // tapered pot
                p.move(to: CGPoint(x: w * 0.22, y: h * 0.02))
                p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.02))
                p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.98))
                p.addLine(to: CGPoint(x: w * 0.30, y: h * 0.98))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(red: 0.82, green: 0.45, blue: 0.32),
                                          Color(red: 0.66, green: 0.34, blue: 0.24)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                Capsule().fill(Color(red: 0.74, green: 0.40, blue: 0.29))
                    .frame(height: h * 0.14)                              // rim
            }
        }
    }
}
```

- [ ] **Step 2: Render a Backdrop sample and inspect**

Add to `Render.swift` a call writing `rendered/_backdrop.png` for `ZStack { Sill(); Pot().frame(width: 90, height: 70).offset(y: 40) }` at 160×200.
Run: `cd SsakArt && swift run SsakArtRender`
**Open `rendered/_backdrop.png`:** confirm a warm sill with a terracotta pot resting on it — calm, chrome-light.

- [ ] **Step 3: Commit**
```bash
git add SsakArt && git commit -m "feat(art): shared Sill + Pot backdrop"
```

---

### Task 4: SeedSoil — the one shared stage

**Files:**
- Create: `SsakArt/Sources/SsakArt/SeedSoil.swift`
- Test: extend `RenderInvariantsTests.swift`

**Interfaces:**
- Consumes: `SpeciesPalette` (`seedTint`).
- Produces: `struct SeedSoil: View { init(tint: Color) }` — a soil mound in the pot with a subtle species-tinted seed nub. The only near-shared frame across species (spec §5.2).

- [ ] **Step 1: Implement `SeedSoil.swift`**

```swift
import SwiftUI

public struct SeedSoil: View {
    let tint: Color
    public init(tint: Color) { self.tint = tint }
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Ellipse()                                                // soil mound
                    .fill(Color(red: 0.36, green: 0.26, blue: 0.18))
                    .frame(width: w * 0.6, height: h * 0.16)
                    .position(x: w * 0.5, y: h * 0.72)
                Circle()                                                 // tinted seed nub
                    .fill(tint)
                    .frame(width: w * 0.06, height: w * 0.06)
                    .position(x: w * 0.5, y: h * 0.70)
            }
        }
    }
}
```

- [ ] **Step 2: Render and inspect** — add a `_seed_marigold.png` render (`SeedSoil(tint: SpeciesPalette.palette(for: "marigold").seedTint)` composed over `Pot`), run the harness, **open it**: a soil mound with a faint warm seed. Restrained, correct.

- [ ] **Step 3: Commit**
```bash
git add SsakArt && git commit -m "feat(art): shared seed-in-soil frame with species tint"
```

---

### Task 5: Droop — the one reusable stress effect

**Files:**
- Create: `SsakArt/Sources/SsakArt/Droop.swift`
- Test: extend `RenderInvariantsTests.swift`

**Interfaces:**
- Produces: `struct Droop: ViewModifier { var amount: Double /* 0...1 */ }` and `extension View { func droop(_ amount: Double) -> some View }`. At `amount == 0` the view is untouched; as amount rises it sags (small rotation + downward skew) and gains a yellow/desaturate tint overlay. One effect, applied over any stage (spec §5.2).

- [ ] **Step 1: Write the failing test (droop changes the output)**

```swift
@MainActor
func testDroopAltersRenderedImage() {
    let base = ZStack { Color.green; Circle().fill(.orange).frame(width: 30, height: 30) }
    let a = pngData(for: base.droop(0), size: CGSize(width: 80, height: 80))
    let b = pngData(for: base.droop(0.9), size: CGSize(width: 80, height: 80))
    XCTAssertNotNil(a); XCTAssertNotNil(b)
    XCTAssertNotEqual(a, b)   // the effect must visibly change the image
}
```

- [ ] **Step 2: Run — expect FAIL** (`droop` undefined). `cd SsakArt && swift test --filter testDroopAltersRenderedImage`

- [ ] **Step 3: Implement `Droop.swift`**

```swift
import SwiftUI

public struct Droop: ViewModifier {
    public var amount: Double
    public init(amount: Double) { self.amount = amount }
    public func body(content: Content) -> some View {
        let a = max(0, min(1, amount))
        content
            .rotationEffect(.degrees(6 * a), anchor: .bottom)            // gentle sag
            .scaleEffect(x: 1, y: 1 - 0.08 * a, anchor: .bottom)        // slight wilt-down
            .overlay(
                Color(red: 0.85, green: 0.80, blue: 0.30)               // yellowing
                    .opacity(0.35 * a)
                    .blendMode(.multiply)
            )
            .saturation(1 - 0.5 * a)                                    // desaturate
    }
}

public extension View {
    func droop(_ amount: Double) -> some View { modifier(Droop(amount: amount)) }
}
```

- [ ] **Step 4: Run — expect PASS.** `cd SsakArt && swift test --filter testDroopAltersRenderedImage`

- [ ] **Step 5: Commit**
```bash
git add SsakArt && git commit -m "feat(art): reusable droop/overwater stress effect"
```

---

### Task 6: PlantView dispatcher

**Files:**
- Create: `SsakArt/Sources/SsakArt/PlantView.swift`
- Create (stub): `SsakArt/Sources/SsakArt/Marigold.swift` (empty stage funcs returning a placeholder, filled in Tasks 8–11)

**Interfaces:**
- Consumes: `SsakCore.Species`, `SsakCore.GrowthStage`, `SpeciesPalette`, `Sill`, `Pot`, `SeedSoil`, `.droop(_:)`.
- Produces: `struct PlantView: View { init(species: Species, stage: GrowthStage, droop: Double = 0) }` — the **only** art entry point the app needs. Composes `Sill` + `Pot` + the correct stage art (dispatched by species id and stage) + `.droop(droop)`. Unknown/undrawn stages fall back to a visible placeholder so the app never crashes on a missing drawing.

- [ ] **Step 1: Implement `Marigold.swift` stub**

```swift
import SwiftUI

enum MarigoldArt {
    // Filled in Tasks 8–11. Until then each returns a labelled placeholder.
    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View { Placeholder(text: "sprout") }
    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View { Placeholder(text: "leaves") }
    @ViewBuilder static func bud(_ p: SpeciesPalette)    -> some View { Placeholder(text: "bud") }
    @ViewBuilder static func bloom(_ p: SpeciesPalette)  -> some View { Placeholder(text: "bloom") }
}

struct Placeholder: View {
    let text: String
    var body: some View {
        Text(text).font(.caption2).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.15))
    }
}
```

- [ ] **Step 2: Implement `PlantView.swift`**

```swift
import SwiftUI
import SsakCore

public struct PlantView: View {
    let species: Species
    let stage: GrowthStage
    let droop: Double

    public init(species: Species, stage: GrowthStage, droop: Double = 0) {
        self.species = species; self.stage = stage; self.droop = droop
    }

    public var body: some View {
        let palette = SpeciesPalette.palette(for: species.id)
        ZStack {
            Sill()
            plant(palette)
                .droop(droop)
            Pot()
                .frame(width: 92, height: 72)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private func plant(_ palette: SpeciesPalette) -> some View {
        switch (species.id, stage) {
        case (_, .seed):
            SeedSoil(tint: palette.seedTint)
        case ("marigold", .sprout): MarigoldArt.sprout(palette)
        case ("marigold", .leaves): MarigoldArt.leaves(palette)
        case ("marigold", .bud):    MarigoldArt.bud(palette)
        case ("marigold", .bloom):  MarigoldArt.bloom(palette)
        default:
            Placeholder(text: "\(species.id)/\(stage.rawValue)")   // undrawn species (follow-up plan)
        }
    }
}
```

- [ ] **Step 3: Render the marigold row (all placeholders except seed) and inspect**

Add to `Render.swift` a helper that, for a species, renders a horizontal strip of all five `GrowthStage.allCases` via `PlantView`, writing `rendered/marigold_row.png`. Run the harness. **Open it:** seed is real; sprout→bloom are labelled placeholders in the pot on the sill. The dispatcher, composition, and strip layout are correct — the art tasks now just replace placeholders.

- [ ] **Step 4: Commit**
```bash
git add SsakArt && git commit -m "feat(art): PlantView dispatcher + marigold placeholders + row render"
```

---

### Task 7: Render-invariants for the five-stage strip + distinctness

**Files:**
- Modify: `SsakArt/Sources/SsakArtRender/Render.swift` (finalize the per-species strip + droop-variant output)
- Test: extend `RenderInvariantsTests.swift`

**Interfaces:**
- Produces: `SsakArtRender` writes, for marigold: `rendered/marigold_<stage>.png` (each stage, 180×220), `rendered/marigold_row.png` (all five, for at-a-glance distinctness), and `rendered/marigold_bloom_droop.png` (bloom at droop 0.8).
- Test guarantees stages render and are mutually distinct.

- [ ] **Step 1: Write the failing distinctness test**

```swift
@MainActor
func testMarigoldStagesRenderDistinctly() {
    let m = SpeciesCatalog.marigold
    let size = CGSize(width: 180, height: 220)
    var seen: [Data] = []
    for stage in GrowthStage.allCases {
        let data = pngData(for: PlantView(species: m, stage: stage, droop: 0), size: size)
        XCTAssertNotNil(data, "\(stage) failed to render")
        for prior in seen { XCTAssertNotEqual(prior, data, "\(stage) is identical to an earlier stage") }
        seen.append(data!)
    }
}
```

- [ ] **Step 2: Run — with placeholders this may FAIL** (sprout/leaves/bud/bloom placeholders differ only by text label, which *does* differ, so it likely passes; if any two placeholders render identically it fails). Either way this test is the guard that keeps every real stage visually distinct as Tasks 8–11 land. `cd SsakArt && swift test --filter testMarigoldStagesRenderDistinctly`

- [ ] **Step 3: Finalize the strip + droop output in `Render.swift`** (write the per-stage PNGs, the row, and the bloom-droop variant as specified in Interfaces).

- [ ] **Step 4: Run harness + full test suite**

Run: `cd SsakArt && swift run SsakArtRender && swift test 2>&1 | tail -5`
Expected: PNGs written; all tests pass.

- [ ] **Step 5: Commit**
```bash
git add SsakArt && git commit -m "test(art): stage-distinctness guard + per-stage/row/droop renders"
```

---

### Task 8: Marigold — sprout

**Files:** Modify `SsakArt/Sources/SsakArt/Marigold.swift` (`sprout`).

**Composition:** a single slender stem rising from the soil with one pair of small, softly serrated marigold leaflets; cotyledon-simple. Sits centered in the pot.
**Detail bar:** *restrained.* Two-tone foliage (`foliage`/`foliageDeep`), clean curves, no flower. This is the quiet opening beat.
**Starting scaffold** (replace the placeholder; then iterate paths against the render):

```swift
@ViewBuilder static func sprout(_ p: SsakArt.SpeciesPalette) -> some View {
    GeometryReader { geo in
        let w = geo.size.width, h = geo.size.height
        ZStack {
            Capsule().fill(p.foliage)                                    // stem
                .frame(width: w * 0.03, height: h * 0.28)
                .position(x: w * 0.5, y: h * 0.66)
            Leaf().fill(p.foliage).frame(width: w * 0.16, height: h * 0.10)
                .rotationEffect(.degrees(-32)).position(x: w * 0.42, y: h * 0.60)
            Leaf().fill(p.foliageDeep).frame(width: w * 0.16, height: h * 0.10)
                .rotationEffect(.degrees(32)).position(x: w * 0.58, y: h * 0.60)
        }
    }
}
// Add a small reusable `Leaf: Shape` (teardrop) in Marigold.swift or a Shapes.swift.
```

**Verification:**
- Automated: `testMarigoldStagesRenderDistinctly` stays green (sprout ≠ seed, ≠ later stages).
- Visual: render `rendered/marigold_sprout.png`, **open it**, confirm a clean two-leaf sprout in the pot, restrained, distinct from seed. Iterate until it reads as "just sprouted."

- [ ] Step 1: Add the `Leaf` shape + implement `sprout`.
- [ ] Step 2: `swift run SsakArtRender` → open `rendered/marigold_sprout.png` → iterate paths until it meets the composition + bar.
- [ ] Step 3: `swift test` green.
- [ ] Step 4: Commit `feat(art): marigold sprout stage`.

---

### Task 9: Marigold — leaves

**Files:** Modify `SsakArt/Sources/SsakArt/Marigold.swift` (`leaves`).

**Composition:** a fuller young plant — taller stem, 2–3 pairs of the pinnate, fern-like leaflets marigolds are known for, still no bud. A recognizably *marigold* foliage silhouette.
**Detail bar:** *refined but restrained* — more leaflets and depth than sprout (use `foliage` + `foliageDeep` for layering), but the flower is still withheld.
**Starting scaffold:** build on the sprout's `Leaf`/stem, add more leaflet pairs up the stem at decreasing size; introduce slight left/right stem curve for life.
**Verification:** automated distinctness stays green (leaves ≠ sprout); visual — **open `rendered/marigold_leaves.png`**, confirm a bushier marigold-foliage plant clearly past the sprout, still budless. Iterate.

- [ ] Step 1: Implement `leaves`.
- [ ] Step 2: Render → open → iterate to the bar.
- [ ] Step 3: `swift test` green.
- [ ] Step 4: Commit `feat(art): marigold leaves stage`.

---

### Task 10: Marigold — bud

**Files:** Modify `SsakArt/Sources/SsakArt/Marigold.swift` (`bud`).

**Composition:** the leaves plant now crowned with a closed/half-open marigold bud — a tight calyx of green sepals with the first hint of orange petal tips peeking. The turn toward the hero moment.
**Detail bar:** *lavish begins here.* Layered sepals, a believable calyx, a slit of `bloom`/`bloomHighlight` petal showing. Noticeably more detailed than leaves.
**Starting scaffold:** reuse the leaves foliage; add a bud group at the stem top — overlapping sepal `Path`s (`foliage`/`foliageDeep`) enclosing 2–3 small petal tips (`bloom`/`bloomHighlight`).
**Verification:** distinctness green (bud ≠ leaves); visual — **open `rendered/marigold_bud.png`**, confirm a convincing about-to-open marigold bud with a peek of orange. Iterate toward "lavish."

- [ ] Step 1: Implement `bud`.
- [ ] Step 2: Render → open → iterate to the (rising) bar.
- [ ] Step 3: `swift test` green.
- [ ] Step 4: Commit `feat(art): marigold bud stage`.

---

### Task 11: Marigold — bloom (hero)

**Files:** Modify `SsakArt/Sources/SsakArt/Marigold.swift` (`bloom`).

**Composition:** the full marigold flower open above its foliage — a dense, rounded pompom of many ruffled petals in concentric rings, tonal depth from `bloomDeep` (throat/shadow) through `bloom` to `bloomHighlight` (ruffled tips), seated on the calyx, foliage below. The screenshot moment (spec §5.1, §7).
**Detail bar:** **the highest — this is the reference.** Match the design session's detailed marigold sample: dense tonal petals, ruffled tips, believable radial layering. This stage sets the aesthetic every other species' bloom will be held to, so it must be genuinely pretty, not schematic.
**Approach:** author the pompom as concentric rings of petal `Path`s. A helper that lays N petals around a ring at radius r with per-ring color/scale keeps it tractable:

```swift
// Sketch — iterate in-loop:
static func petalRing(count: Int, radius: CGFloat, petal: CGSize, color: Color,
                      center: CGPoint, rotationOffset: Double) -> some View { /* ForEach angle → Petal().fill(color) positioned/rotated around center */ }
```
Build outer→inner rings (larger, darker outer; smaller, lighter inner) + a central boss. Iterate ring count/size/color against the render until it reads lush.
**Verification:**
- Automated: distinctness green (bloom ≠ bud); the droop variant differs from the upright bloom (`rendered/marigold_bloom_droop.png` ≠ `rendered/marigold_bloom.png`).
- Visual: **open `rendered/marigold_bloom.png`** — it must clear the detail bar and look share-worthy. This is the gate for the whole art direction; iterate until it genuinely does.

- [ ] Step 1: Implement `petalRing` + `bloom`.
- [ ] Step 2: Render → open → iterate hard until it clears the reference bar.
- [ ] Step 3: `swift test` green (distinctness + droop-changes-output).
- [ ] Step 4: Commit `feat(art): marigold bloom (hero) stage`.

---

### Task 12: Marigold lifecycle assembly + portrait render + review gate

**Files:**
- Modify: `SsakArt/Sources/SsakArtRender/Render.swift` (add a framed bloom "portrait" render — the share-card preview of spec §7).
- Modify: `SsakArt/.gitignore` (un-ignore a curated few reference PNGs so the approved look is tracked).

**Interfaces:**
- Produces: `rendered/marigold_row.png` (all five real stages), `rendered/marigold_bloom_portrait.png` (bloom + "Marigold / 메리골드" + a date/streak line, no chrome — the ImageRenderer share card preview), both committed as reference images.

- [ ] **Step 1: Add the portrait render** (bloom centered on a clean card with EN+KO name and a sample streak/date, per spec §7 — this is a *preview* of the share export; the real share sheet is Plan 3+).
- [ ] **Step 2: Regenerate everything** — `cd SsakArt && swift run SsakArtRender && swift test 2>&1 | tail -5`. All tests green.
- [ ] **Step 3: Visual review gate** — **open `rendered/marigold_row.png`**: five *visibly distinct*, increasingly detailed stages (spec §11), calm and cohesive; **open `rendered/marigold_bloom_portrait.png`**: a clean, pretty, shareable card. This is the aesthetic sign-off point for the whole game's art.
- [ ] **Step 4: Track the reference images**
```bash
git add -f SsakArt/rendered/marigold_row.png SsakArt/rendered/marigold_bloom_portrait.png
git add SsakArt && git commit -m "feat(art): marigold lifecycle assembly + shareable portrait preview"
```

---

## Self-Review (spec coverage)

- **Hand-authored static vector, no runtime engine, no AI raster (§5.1):** all art is SwiftUI `Path`/`Shape`; no procedural engine; render harness is a *design-time* tool, not shipped. ✓
- **Detail ramps to bloom; bud/bloom lavish; marigold sample as the bar (§5.1):** Tasks 8→11 explicitly ramp restraint→lavish; Task 11 pins the reference bar. ✓
- **6×5 stages, seed near-shared with tint, sprout+ unique (§5.2):** SeedSoil (Task 4) is the shared seed; PlantView dispatches unique per-species stages; this plan delivers marigold's four unique stages, framework ready for the other five. ✓ *(Scope note below.)*
- **Droop = one reusable effect, not per-stage (§5.2):** Droop modifier (Task 5), applied once in PlantView. ✓
- **Gentle animation in scope (§5.2):** the art is animatable (static `View`s compose with SwiftUI transitions); idle sway/bloom-open/glow are wired at the app layer (Plan 3+), not here — this plan delivers the drawings those animations move. ✓ (No gap: animation belongs with the app.)
- **Screenshot-ready, chrome-light sill (§6); shareable portrait (§7):** Sill (Task 3) is chrome-light; Task 12 renders the framed portrait preview. ✓ (Real `ImageRenderer` share *sheet* is Plan 3+.)
- **Reuse SsakCore types (§8):** GrowthStage/Species/SpeciesCatalog consumed, not redefined. ✓
- **Testing genuinely discriminates:** logic-style asserts here are the render invariants (renders / correct size / **stage distinctness** / **droop changes output**) — each fails if the thing it guards breaks; visual gates cover the subjective quality tests can't. ✓

**Scope note (deliberate):** this plan covers the **art foundation + Marigold only**, not all six species. Rationale: (1) 30 drawings is too large for one review-gated plan; (2) the marigold bloom sets the aesthetic bar — getting a human eye on it *before* authoring five more flowers in that style avoids 6× rework. The remaining five species (nasturtium, cosmos, zinnia, sunflower, morning glory) are a short **follow-up plan** that reuses this exact framework (palette entry + four stage views + render + distinctness, per species) and finalizes each provisional palette. After that: the app-UI plan (windowsill, shelf, watering, real share sheet, onboarding, engine reconcile-on-open).

**Placeholder scan:** infra tasks (1–7) contain complete, compiling code. Art tasks (8–12) intentionally carry *scaffold + composition + detail bar + verification* rather than final bezier coordinates — this is the documented "authored, not transcribed" model for visual work, not a TODO. No "add error handling"/"similar to Task N"/"TBD" placeholders remain.

**Type consistency:** `pngData(for:size:scale:)`, `SpeciesPalette.palette(for:)`, `Sill`, `Pot`, `SeedSoil(tint:)`, `Droop(amount:)`/`.droop(_:)`, `PlantView(species:stage:droop:)`, `MarigoldArt.{sprout,leaves,bud,bloom}(_:)` are used consistently across tasks. ✓
