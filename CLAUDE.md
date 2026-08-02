# Ssak (싹)

Cozy, calm iOS game — raise one flower at a time from seed to bloom on your windowsill, on the real clock, and collect six species. 100% Swift/SwiftUI, no backend, hand-authored static vector art (no runtime art engine). Design spec: `docs/superpowers/specs/2026-07-19-ssak-design.md` (decision ledger in Appendix A). Implementation plans: `docs/superpowers/plans/`.

Restarted from **Meok (먹)**, a more ambitious ink-wash skilling RPG that was scrapped as over-scoped for a first game. Meok's final state is preserved under the git tag `meok-archive`.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (github.com/mhju0/ssak) via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `CONTEXT.md` + `docs/adr/`. See `docs/agents/domain.md`.
