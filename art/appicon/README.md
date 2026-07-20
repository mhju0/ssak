# Bloom-Point app icon

Design source for the Ssak app icon (spec `docs/superpowers/specs/2026-07-20-ssak-redesign.md`
§2.6 + Appendix A). Two green cotyledons framing a **furled gold bud** — bloom implied, never open.

## Files

| File | Role |
|---|---|
| `bloom-point.svg` | **Light** — full-bleed opaque cream→sage field + mark. The Icon Composer light layer **and** the flat-fallback source. |
| `bloom-point-dark.svg` | **Dark** — warm-dark field + glow, brighter leaves/bud. |
| `bloom-point-tinted.svg` | **Tinted** — single-tint grayscale, bud lightest (`#DCE7C8`), for iOS monochrome recolor. |
| `bloom-point-mono.svg` | **Mono** silhouette — small-size / tinted legibility check. |
| `appicon-1024.png` | **The flat fallback**: 1024², **opaque, no alpha, no baked corners** (iOS applies its own superellipse mask). Rendered from `bloom-point.svg`. |
| `proof.html` | Sizing wrapper: `?src=<svg>&preview=1` (preview adds the iOS corner mask). |

**Why full-bleed, not a pre-rounded squircle:** iOS masks the icon itself, so a flat source must be an
opaque, corner-to-corner square with no alpha — a pre-rounded transparent-corner PNG double-masks and
the asset catalog rejects alpha. Appendix A's "squircle rx≈49" describes the *masked* result, honored by
letting iOS round a full-bleed source.

## Regenerate the proofs (headless Chrome, on a Mac)

Chrome must be given `--virtual-time-budget` or it hangs. Run one at a time:

```sh
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
D="$(pwd)"   # this folder
# flat fallback (opaque, full-bleed):
"$CHROME" --headless=new --disable-gpu --no-sandbox --user-data-dir=/tmp/cr \
  --no-first-run --virtual-time-budget=3000 --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1024,1024 --screenshot="$D/appicon-1024.png" "file://$D/proof.html?src=bloom-point.svg"
# masked on-device preview (transparent corners):
"$CHROME" --headless=new --disable-gpu --no-sandbox --user-data-dir=/tmp/cr2 --no-first-run \
  --virtual-time-budget=3000 --default-background-color=00000000 --window-size=512,512 \
  --screenshot="$D/proofs/light-masked.png" "file://$D/proof.html?src=bloom-point.svg&preview=1"
```
Verify the fallback is opaque: `sips -g hasAlpha appicon-1024.png` → `hasAlpha: no`.
(The in-app SwiftUI port of this same geometry — `SsakArt/SsakMark` — is proofed at
`SsakApp/rendered/ssakmark_variants.png`, covering the tinted/mono legibility read.)

## Deliver the icon (Icon Composer, Xcode 26 — Plan B Task 2, on a Mac)

1. Open **Icon Composer**; import the mark layers from these SVGs.
2. Build the four appearances — **Light**, **Dark**, **Tinted** (grayscale source, bud lightest),
   **Clear/Glass** (OS-composited frosted; not statically previewable — check on device).
3. Export the `.icon`; place it + `appicon-1024.png` into `App/Assets.xcassets/AppIcon`.
   Do **not** add the full legacy size set.
4. `project.yml` (Task 3): add `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` under `settings.base`;
   the `App` glob already covers `App/Assets.xcassets`. Keep `deploymentTarget iOS: "16.0"`.
5. `xcodegen generate` → build → icon shows. Verify on device: light/dark/tinted home screen,
   tinted @40px, iOS-16 fallback path, Clear/Glass on iOS 26.
