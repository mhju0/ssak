# Ssak — iOS app shell

The game's logic and art live in three SwiftPM packages (`SsakCore`, `SsakArt`,
`SsakApp`). This folder is only the thin iOS app entry point (`SsakApp.swift`,
`@main`). The Xcode project is **generated** from `project.yml` — it is not
committed.

## Build & run

```sh
brew install xcodegen        # one-time
xcodegen generate            # from the repo root → produces Ssak.xcodeproj
open Ssak.xcodeproj          # then pick a Simulator and Run
```

`xcodegen generate` reads `project.yml`, wires the three local packages, and
creates `Ssak.xcodeproj`. Re-run it whenever `project.yml` or the package set
changes.

## Fallback (no XcodeGen)

In Xcode: **File ▸ New ▸ Project ▸ iOS App** (SwiftUI, deployment 16.0). Then
**File ▸ Add Package Dependencies ▸ Add Local…** for each of `SsakCore`,
`SsakArt`, `SsakApp`, add `SsakApp` (+ `SsakCore`) to the app target's Frameworks,
delete the template `ContentView`/`App`, and drop in `App/SsakApp.swift`.

## What still needs a device/Simulator

Everything visual is verifiable headless via `cd SsakApp && swift run SsakAppRender`
(writes screen PNGs to `SsakApp/rendered/`). Only these need a running app:

- the share sheet (`RootView.presentShare` → `UIActivityViewController`)
- tap-to-water / swipe-between-tabs gestures
- `scenePhase`-driven reconcile-on-open (grow the plant after backgrounding)
