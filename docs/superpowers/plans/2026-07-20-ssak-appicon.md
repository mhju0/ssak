# Ssak App Icon — Bloom-Point (Plan B) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`). This is an **asset-delivery** plan, not code. **One task is fully headless** (author + proof the SVG here); the rest are **user-on-Mac** (Icon Composer is a GUI tool; `xcodegen` + a real device confirm the wiring) — flagged per task. No Swift, no gameplay, no logic.

**Goal:** Deliver the **Bloom-Point** app icon (spec [`2026-07-20-ssak-redesign.md`](../specs/2026-07-20-ssak-redesign.md) §2.6, Appendix A) as an **iOS 26 layered `.icon`** (Light / Dark / Tinted / Clear) **plus a single 1024 PNG fallback**, wired into the build via an `Assets.xcassets/AppIcon` set — **retaining the iOS 16 deployment floor.**

**Why a separate plan:** the icon's work — SVG source, Icon Composer assembly, asset-catalog + build-setting wiring — is orthogonal to Plan A's SwiftUI screens (spec §0). Plan B changes **no Swift code and no package**; it touches only design assets, `App/Assets.xcassets`, and `project.yml`.

**Mark (Appendix A):** two green cotyledons framing a **furled gold bud** — bloom implied, never opened. Canvas 220×220, squircle `rx≈49`, mark centered, ~53% frame height. Full path data (stem, leaves, bud furl, contact shadow) and the four variant recipes are in the spec's Appendix A — the SVG is reconstructed deterministically from there.

## Global Constraints

- **iOS 16 min deployment retained.** The layered `.icon` is an iOS-26 enhancement; the single 1024 PNG is the iOS-16 fallback. `project.yml`'s `deploymentTarget iOS: "16.0"` is unchanged. — verbatim (spec §0, §2.6).
- **No full legacy size set.** Ship the iOS 26 layered `.icon` + one 1024×1024 PNG; iOS generates the rest. — verbatim (spec §2.6).
- **No Swift/package/gameplay changes.** Assets + `project.yml` only. — verbatim (spec §0).
- **`.icon` binary + `AppIcon.appiconset` + the SVG source are all committed** (mirroring `0e850b7`'s tracked-reference pattern: a `.gitignore` allowlist keeps the approved assets). — spec §2.6.

**Prerequisite (cross-plan):** none blocking. The icon's source of truth is the **committed SVG** (this plan), *not* Plan A's `SsakMark`. `SsakMark` (Plan A Task 4) is the same Appendix-A geometry ported to SwiftUI for **in-app reuse** (watermark + shelf glyph) — a parallel port, not a dependency. Plan B can run before, after, or alongside Plan A.

**Tooling note (no new dependencies):** proofs render through the **already-installed** `/Applications/Google Chrome.app` in headless mode (spec §2.6 "proofed via headless Chrome") — no npm/puppeteer/librsvg install. **Icon Composer** ships with Xcode 26 and is GUI-only → the layered-`.icon` assembly (Task 2) and `xcodegen`/device steps (Tasks 3–4) are **user-on-Mac**; they cannot be done in this headless env.

## Verification model (read before starting)

| Layer | How verified | Who |
|---|---|---|
| SVG geometry + variants; tinted legibility @40px; 1024 fallback | headless Chrome → proof PNGs → open & inspect | headless (this env) |
| Layered `.icon` (Light/Dark/Tinted/Clear) | Icon Composer preview | **user, on a Mac** |
| Build wiring (`project.yml` → `xcodegen` → icon shows) | `xcodegen generate` → build → home screen | **user, on a Mac** |
| Home-screen light/dark/tinted; iOS-16 render path | Simulator + device | **user, on a Mac** |

---

### Task 1: Author + proof the Bloom-Point SVG; export the 1024 fallback (headless)

**Files:** Create `art/appicon/bloom-point.svg` (+ `-dark.svg`, `-tinted.svg`, `-mono.svg`), `art/appicon/proof.html` (sizing wrapper; a `fill=1` param swaps the squircle for an opaque full-bleed square), `art/appicon/README.md` (Chrome invocations + Icon Composer steps), `art/appicon/proofs/*.png`, `art/appicon/appicon-1024.png` (the opaque flat fallback), `art/.gitignore` (track the SVGs + curated proofs + fallback).

**Interfaces:** `bloom-point.svg` = the Appendix A mark on a 220×220 squircle (`rx≈49`): stem `M110 146 C110 154 110 160 110 166` (8pt round `#4C8642`); left/right leaves + bud furl + highlight + contact shadow, **verbatim from Appendix A**. Variants per Appendix A: **Light** (cream→sage bg), **Dark** (`#2A241C→#17130F` bg + warm glow; leaves `#8AC86C→#4F9145`; bud `#FAD583→#E89B32`), **Tinted** (dark bg, single-tint grayscale, bud lightest `#DCE7C8`), **Mono** (flat silhouette). `proof.html` wraps an `<img>`/inline SVG sized to the shot dimensions so Chrome screenshots at exact pixels.

- [ ] Step 1: Write `bloom-point.svg` from Appendix A path data; derive the three variant SVGs per the Appendix A recipes.
- [ ] Step 2: `proof.html` + the headless-Chrome invocations in `README.md`. **Two distinct exports** — do not conflate them:
  - **Visual proofs** (transparent, rounded squircle — for inspection only): `… --default-background-color=00000000 --window-size=1024,1024 --screenshot=art/appicon/proofs/bloom-point-1024.png "file://$PWD/art/appicon/proof.html?src=bloom-point.svg"`; repeat at `--window-size=40,40` for the tinted @40px legibility proof, and once on the mono silhouette.
  - **AppIcon fallback PNG** (the real deliverable): export the mark on an **opaque, corner-to-corner square** field color — **no alpha channel, no squircle `rx` rounding** (iOS rejects alpha in a flat app icon and applies its *own* mask; a pre-rounded transparent-corner shot double-masks). Use a full-bleed square SVG/HTML (drop the `rx≈49`) with an opaque `--default-background-color=<field hex>`: `… --window-size=1024,1024 --screenshot=art/appicon/appicon-1024.png "file://$PWD/art/appicon/proof.html?src=bloom-point.svg&fill=1"`. `appicon-1024.png` is what Task 2 places in the `AppIcon` set.
- [ ] Step 3: Open the three proofs **and** `appicon-1024.png`. Confirm: bud reads furled (never open); tinted legible at 40px; silhouette reads as a sprout; **`appicon-1024.png` is opaque, full-bleed, square, no alpha** (`sips -g hasAlpha art/appicon/appicon-1024.png` → `hasAlpha: no`). `art/.gitignore` tracks the SVGs + these curated proofs + the fallback.
- [ ] Step 4: Commit `feat(icon): Bloom-Point SVG source + headless proofs + 1024 fallback (Plan B Task 1)`.

---

### Task 2: Assemble the iOS 26 layered `.icon` + the `AppIcon` set (user, Mac)

**Files:** Create `App/Assets.xcassets/` with an `AppIcon` set (the 1024 PNG fallback) and the Icon Composer layered `AppIcon.icon` (Light / Dark / Tinted / Clear).

**Interfaces:** In **Icon Composer** (Xcode 26), import the Bloom-Point layers (from the Task 1 SVGs) and produce the four appearances per Appendix A: Light, Dark, Tinted (single-tint grayscale source, bud lightest), Clear/Glass (OS-composited frosted — translucent white relief + specular edges over the layered art). Export the `.icon`; drop it + the 1024 PNG into `App/Assets.xcassets/AppIcon`. **Do not** add the full legacy size set.

- [ ] Step 1: **(User, Mac)** Icon Composer: build Light/Dark/Tinted/Clear from the Task 1 art; preview each appearance.
- [ ] Step 2: **(User, Mac)** Place the `.icon` + 1024 PNG into `App/Assets.xcassets/AppIcon`.
- [ ] Step 3: Commit `feat(icon): iOS 26 layered AppIcon + 1024 fallback asset (Plan B Task 2)`.
- [ ] **Mac note:** Clear/Glass is OS-composited and not statically previewable outside the device (spec §4) — checked on device in Task 4.

---

### Task 3: Wire `project.yml` (config; `xcodegen` = user)

**Files:** Modify `project.yml`.

**Interfaces (spec §2.6):** the catalog lives at `App/Assets.xcassets` (Task 2), and `App` is **already** a `sources` glob (`project.yml:17-18`) that XcodeGen recurses — so the catalog is already compiled in; **do not re-list it** (a duplicate `sources` entry can create a duplicate file reference). The only genuinely new line is the build setting — spec §2.6's "add Assets.xcassets to sources" is already satisfied by the existing `App` glob:
```yaml
targets:
  Ssak:
    sources:
      - App                        # unchanged — already globs App/Assets.xcassets
    settings:
      base:
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon   # the ONE new line
        # deploymentTarget iOS "16.0" and all existing settings unchanged
```
(Add an explicit `- Assets.xcassets` line **only** if Task 2 instead placed the catalog at the repo root, outside `App/`.)

- [ ] Step 1: Add `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` under `settings.base`; leave `sources` as `- App` (the catalog under `App/` is already globbed); confirm `deploymentTarget iOS: "16.0"` is untouched.
- [ ] Step 2: **(User, Mac)** `xcodegen generate` → build the `Ssak` target → the Bloom-Point icon appears on the target and Simulator home screen.
- [ ] Step 3: Commit `feat(icon): wire AppIcon into project.yml, retain iOS 16 (Plan B Task 3)`.

---

### Task 4: Verification & handoff (user, device)

**Manual (Simulator + device), spec §7:**
- [ ] Bloom-Point on the home screen in **light**, **dark**, and **tinted** — legible, calm, bud furled.
- [ ] **iOS-16 render path:** on an iOS 16 target the single 1024 PNG fallback is used (no layered `.icon`) and looks right.
- [ ] Tinted legibility @40px — confirmed against the Task 1 headless proof.
- [ ] Clear/Glass appearance on a real iOS 26 device (OS-composited; not previewable headless).
- [ ] Commit nothing new unless a proof/asset is revised; if the icon needs a tweak, iterate Task 1's SVG → re-proof → re-export.

---

## Self-Review (spec coverage)

- **Bloom-Point mark from Appendix A, SVG committed (§2.6):** Task 1 (SVG source of truth + headless proofs, mirroring `0e850b7`). ✓
- **iOS 26 layered `.icon` — Light/Dark/Tinted/Clear (§2.6, Appendix A):** Task 2 (Icon Composer, user-Mac). ✓
- **Single 1024 PNG fallback, no legacy size set (§2.6):** Task 1 exports it; Task 2 places it in the `AppIcon` set. ✓
- **`Assets.xcassets/AppIcon` + explicit `project.yml` wiring, iOS 16 retained (§2.6, §0):** Task 3. ✓
- **iOS-16 icon-render sanity added to the manual list (§2.6, §7):** Task 4. ✓
- **Tinted legibility @40px, Clear/Glass OS-composited caveat (§4):** Tasks 1 (headless proof) + 4 (device). ✓
- **No Swift/package/gameplay change (§0):** assets + `project.yml` only. ✓

**Cross-plan:** the in-app reuse of this mark (watermark + shelf glyph) is `SsakMark` in **Plan A** ([`2026-07-20-ssak-redesign-ui.md`](./2026-07-20-ssak-redesign-ui.md), Task 4) — the same Appendix-A geometry, ported to SwiftUI. Plan B owns only the icon delivery.

**Headless boundary:** only Task 1 runs in this env. Icon Composer, `xcodegen`, and every home-screen/appearance check are user-on-Mac handoffs — Icon Composer is GUI-only and the appearances (esp. Clear/Glass, tinted, iOS-16 fallback) must be seen on the device.
