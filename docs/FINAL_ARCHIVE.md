# Final archive — 2026-09-05

Ssak is finished. The author authorized one final unarchive → PR → merge → local sync →
archive cycle to preserve the recent work and correct the public presentation. Product
development remains closed; there is no remaining roadmap or planned App Store release.

This archival pass preserves `AGENTS.md`, the decision ledger, roadmap, project handoff,
historical Claude environment inventory, and the Korean retrospective draft. It corrects
stale UI descriptions, ADR numbering and profile-pin status, replaces the obsolete hero
and social card, and includes the final app's reference states. Only the render executable
changes; game logic and runtime UI remain unchanged.

Verification performed on 2026-09-05 with Xcode 26.6 (17F113) / Swift 6.3.3:

- All three package test suites pass: **58 tests, zero failures** (39 core, 4 art, 15 app).
- A freshly generated Xcode project builds for the generic iOS Simulator destination.
- Both SwiftUI render executables run successfully. The final hero, social preview,
  collection screen, and walkthrough frames were inspected visually.
- GitHub’s uploaded social preview now displays the final card; the repository description
  states that the project is finished and archived.
- Current documentation links and committed image files are checked before merge.

The complete asset provenance and regeneration commands live in [art/README.md](../art/README.md).
The known device-coverage and long-term gameplay limitations remain documented in the
[handoff](PROJECT_HANDOFF.md); this pass does not claim new device or multi-week playtesting.

The pre-archive baseline was `a46f851`. Historical tags remain unchanged:
`meok-archive` points to `8c88a63`; `v1.0-final` points to `b69e754` (the original product
closure, before later documentation). Use the final `main` for the complete archive.

Generated Xcode projects, build caches, macOS metadata, local permissions, private agent
session scratch and tokens remain ignored and local. Reproducible uncurated renders also
remain ignored. The Korean retrospective is preserved in git as a draft, not posted to a blog.

[Final PR #37](https://github.com/mhju0/ssak/pull/37) records the merge and verification. GitHub's archived flag and the matching
local/remote `main` refs are verified after merge, before this session concludes.
