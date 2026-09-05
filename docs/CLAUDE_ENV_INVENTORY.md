# Claude Environment Inventory — ARCHIVE

**Historical snapshot; captured 2026-09-04**, on the machine that built Ssak (`darwin 25.6`, user `michaelju`).

> ## What this document is — and is not
>
> This is an **archive**, not a migration target.
>
> Ssak was built by driving Claude Code. That harness — global instructions, plugins, skills,
> hooks, MCP servers, auto-memory — shaped *how* the work happened. Almost none of it is
> knowledge about the game.
>
> **Do not convert anything in this file into Codex configuration.** It exists so that if a
> capability is ever actually missed, it can be found here and rebuilt deliberately, rather
> than being cloned pre-emptively.
>
> Each entry is classified:
>
> | Class | Meaning |
> |---|---|
> | **PROJECT-CRITICAL** | Real knowledge about Ssak. Would be lost if not carried forward. |
> | **USEFUL-BUT-OPTIONAL** | A genuine capability, but rebuildable on demand and not needed to understand the project. |
> | **CLAUDE-SPECIFIC** | Exists to make Claude behave. Meaningless outside Claude Code. |
> | **LIKELY-OBSOLETE** | Stale, superseded, or referring to things that no longer exist. |
> | **UNKNOWN** | Purpose or relevance not determinable from what is on disk. |
>
> **No secret values appear in this document.** Where a config item carries a token, key, or
> credential, only its *name and location* are recorded. One file (`.superpowers/brainstorm/.last-token`)
> was deliberately **not opened**.

**Headline for the migration**: exactly **three** items are PROJECT-CRITICAL, and **all three
already live inside the repo** (`CONTEXT.md`, `docs/adr/`, `docs/superpowers/`). Everything
Claude-side that mattered has been extracted into `PROJECT_HANDOFF.md` / `DECISIONS.md` /
`ROADMAP.md`. The Claude environment can be left behind whole.

---

Later updates: a minimal `AGENTS.md` was adopted (see `DECISIONS.md` T-2), and the
GitHub profile pin was completed on 2026-09-05. Recommendations and open tasks below
describe the capture date; current state lives in `PROJECT_HANDOFF.md` and `ROADMAP.md`.

## 1. Instruction files

### 1.1 Global user instructions — `~/.claude/CLAUDE.md`

- **Scope**: global (every project on this machine).
- **Purpose**: the author's personal operating manual for agents. Sections: *Delivering work*
  (only what was asked; no speculative abstractions; touch only what the change requires),
  *Evidence & claims* (the `[Verified]` / `[Inferred]` / `[Unknown]` tagging convention),
  *Verification* (define the success check first; bug fix → failing test first; regression
  tests must genuinely discriminate), *Long tasks* (commit at each verified checkpoint),
  *Git* (a hard secrets rule; `git add .` 금지 — always explicit paths; Conventional Commits
  in English; never push to `main`/`master`; never force-push; never `reset --hard` unasked),
  and *Licensing* (no default license; never add/remove a `LICENSE` unasked; never raise
  licensing unprompted).
- **Does Ssak rely on it?** It shaped the repo's habits — the evidence tags used throughout
  these handoff docs, the Conventional Commit history, and the absence of a `LICENSE` file
  all trace to it. But the repo does not *need* it to be understood.
- **Class**: **CLAUDE-SPECIFIC**, with two exceptions worth knowing as *facts* rather than
  as instructions to copy:
  - the **licensing** rule explains why there is no `LICENSE` file (see `DECISIONS.md` L-1);
  - the **secrets** rule is why no credential ever entered this repo.
- **Recommendation**: do not port. A modern model handles "only what was asked", "explicit
  file paths", and "Conventional Commits" without being told. If any single rule is worth
  restating to a new agent, it is the **evidence-tagging convention**, and only because these
  handoff documents use it.
- Sibling files `CLAUDE.md.bak` and `CLAUDE.md.proposed` also exist. **LIKELY-OBSOLETE / UNKNOWN** —
  drafts, not in force.

### 1.2 Project instructions — `<repo>/CLAUDE.md` (tracked, 978 bytes)

- **Scope**: this project. Checked into git.
- **Contents**: (a) a one-paragraph description of Ssak; (b) the Meok lineage and the
  `meok-archive` tag; (c) an "Agent skills" section pointing at `docs/agents/{issue-tracker,
  triage-labels,domain}.md`.
- **Class**: **split**.
  - (a) and (b) are **PROJECT-CRITICAL** — and are now restated in `PROJECT_HANDOFF.md` §1.
  - (c) is **CLAUDE-SPECIFIC**.
- **History worth keeping** [Verified]: a ~50-line "Working standard" baseline was inlined into
  this file on 2026-07-27 (`2bc6db5`) and **removed six days later** (`9fa6a5d`, "Remove
  inlined global baseline from CLAUDE.md"). The author has already once concluded that
  agent-behavior rules should not be duplicated into a project repo — the same conclusion
  this migration is acting on. See `DECISIONS.md` H-2.
- **Recommendation**: the file is tracked; leave it in the archived repo as history. Do not
  create an `AGENTS.md` counterpart.

### 1.3 `docs/agents/*.md` (tracked) — issue-tracker, triage-labels, domain

- **Purpose**: tells an agent how to use `gh` for issues, maps five canonical triage labels to
  this repo's labels, and specifies reading `CONTEXT.md` + `docs/adr/` before exploring.
  Written 2026-07-16 (Meok era) against the `mattpocock-skills` plugin's conventions.
- **Does Ssak rely on it?** No. It was used for real during Meok (32 issues triaged, 10 closed
  `wontfix`), and **zero Ssak issues were ever filed** — the Ssak era ran on specs and plans
  instead, so this scaffolding was already dormant before the project closed.
- **Class**: **CLAUDE-SPECIFIC** (the triage-label vocabulary itself is generic, but the
  documents are addressed to a specific skill pack).
- **Recommendation**: do not port. The one durable fact — *ten Meok features were closed as
  `wontfix`, issues #9/#10/#11/#19/#20/#28/#29/#30/#31/#32* — is captured in `ROADMAP.md`.

---

## 2. Settings

### 2.1 `~/.claude/settings.json` (global)

| Key | Value / purpose | Class |
|---|---|---|
| `model` | `opus[1m]` | CLAUDE-SPECIFIC |
| `effortLevel`, `modelSettings` | per-model reasoning-effort defaults | CLAUDE-SPECIFIC |
| `includeCoAuthoredBy: false` | **why no Claude co-author trailers appear in this repo's git history** | CLAUDE-SPECIFIC, but explains a visible repo fact |
| `autoMemoryEnabled: true` | enables the file-based auto-memory in §6 | CLAUDE-SPECIFIC |
| `autoCompactWindow`, `tui`, `agentPushNotifEnabled`, `skipWorkflowUsageWarning` | UI/session ergonomics | CLAUDE-SPECIFIC |
| `skipDangerousModePermissionPrompt: true` | suppresses the bypass-permissions confirmation | CLAUDE-SPECIFIC — **note it exists**; it materially loosens the approval loop |
| `enabledPlugins` | `mattpocock-skills`, `github` → both `true` | see §4 |
| `extraKnownMarketplaces` | `karpathy-skills`, `ponytail`, `skill-usage-counter-marketplace`, `anthropic-agent-skills` — registered sources, mostly with nothing installed from them | LIKELY-OBSOLETE |
| `statusLine` | shells out to `~/.orca/agent-hooks/claude-statusline.sh` | CLAUDE-SPECIFIC (third-party, see §3) |
| `hooks` | 12 event bindings, all to the same Orca hook (see §3) | CLAUDE-SPECIFIC (third-party) |
| `autoMode.environment` | a prose "environment briefing" block (org, cloud, secrets management, protected branches, sensitive targets…). **Nearly every field reads "None configured", and its "Trusted repo" names `/Users/michaelju/Workspace/Projects/recruiting` — a different project entirely.** | **LIKELY-OBSOLETE** for Ssak. Stale cross-project residue; do not carry over. |

Four backup copies exist (`settings.json.bak`, `.bak2`, `.bak.prehookremove`) — **UNKNOWN**,
historical snapshots.

### 2.2 `~/.claude/settings.local.json` (global, machine-local)

- `permissions.allow`: five pre-approved Bash patterns (`rtk proxy *`, `mount`, `npx skills *`,
  `node *`, and an echo). **CLAUDE-SPECIFIC.** None relate to Ssak (no Node in this project).
- `skillOverrides`: five skills forced `off` — four `higgsfield-*` image-generation skills and
  `code-review`. **Worth noting**: the `higgsfield-*` skills being disabled aligns with the
  Ssak decision that **no AI raster art** would be used (spec §10). Circumstantial, not causal.
- `enabledPlugins`: `skill-usage-counter` → `false`.

### 2.3 `<repo>/.claude/settings.local.json` (project, **untracked**)

- Contents: three pre-approved permissions — a one-off `ls` of a sibling directory,
  `WebFetch(domain:github.com)`, and `Bash(gh issue *)`.
- **Class**: **CLAUDE-SPECIFIC**. Permission cache only; carries no project knowledge.
- The only signal in it is that **`gh issue` was used enough to be whitelisted** — consistent
  with the Meok-era issue workflow.

---

## 3. Hooks

- **`~/.claude/settings.json` → 12 hook events**: `UserPromptSubmit`, `Stop`, `StopFailure`,
  `SubagentStart`, `SubagentStop`, `TeammateIdle`, `PreToolUse`, `PostToolUse`,
  `PostToolUseFailure`, `PermissionRequest`, `SessionStart`, `PostCompact`.
- **All twelve invoke the same third-party shim**: `~/.orca/agent-hooks/claude-hook.sh`
  (with Windows `.cmd`/PowerShell branches, and a no-op fallback that prints `{}` when the
  script is absent). Plus `claude-statusline.sh` for the status line.
- **Purpose**: an external tool ("Orca") observing/annotating Claude Code sessions. It is
  **not** a Ssak build hook — it does not run tests, lint, or format.
- **Does Ssak rely on it?** No. Nothing in the repo's build or verification path touches it.
- **Class**: **CLAUDE-SPECIFIC** (and third-party). **Do not port.**
- **`~/.claude/hooks.disabled/`**: `rtk-rewrite.sh` and a dated `.bak`. Disabled, unrelated to
  Ssak. **LIKELY-OBSOLETE.**
- **Project-level hooks**: none. Ssak defined **zero** hooks of its own [Verified].

---

## 4. Plugins

| Plugin | Scope | Installed | Enabled | Relevance to Ssak | Class |
|---|---|---|---|---|---|
| `mattpocock-skills@claude-plugins-official` v1.2.3 | user | 2026-08-06 | ✅ | Source of the conventions `docs/agents/` was written against (`triage`, `wayfinder`, `domain-modeling`, `tdd`, `code-review`, `to-spec`, `to-tickets`, `grilling`, `handoff`…). Its `domain-modeling` skill is why the repo has `CONTEXT.md` + `docs/adr/` in that exact shape. | **CLAUDE-SPECIFIC** — but its *outputs* (`CONTEXT.md`, the ADRs) are PROJECT-CRITICAL and already in the repo. |
| `github@claude-plugins-official` | user | 2026-08-06 | ✅ | Provides GitHub MCP tooling. **Failed to connect in this session** (`400: Authorization header is badly formatted`); the `gh` CLI was used instead and worked fine. | **USEFUL-BUT-OPTIONAL** — `gh` covers everything it was used for. |
| `skill-usage-counter@skill-usage-counter-marketplace` v1.0.1 | local | 2026-08-06 | ❌ disabled | Telemetry on skill usage. | **LIKELY-OBSOLETE** |
| **`superpowers`** | — | **NOT INSTALLED** | — | **This is the important one.** The plugin that actually drove the Ssak build — brainstorming → spec → plan → subagent-driven implementation. It produced the entire `docs/superpowers/` tree (specs, plans) and the untracked `.superpowers/` working directory. Only residual data folders remain (`~/.claude/plugins/data/superpowers-inline`, `…/superpowers-claude-plugins-official`); no plugin in `plugins/cache`. | **LIKELY-OBSOLETE as tooling · PROJECT-CRITICAL as output.** The *artifacts* are tracked in git and are among the most valuable documents in the repo. |

**Known marketplaces with nothing installed**: `karpathy-skills`, `ponytail`,
`anthropic-agent-skills`. *(“ponytail” appears in a source comment in `GrowthEngine.swift:40`
— it was a laziest-viable-solution mode used during the build. The note it left in the code is
real; the tooling behind it is gone.)* **LIKELY-OBSOLETE.**

---

## 5. Skills (personal, `~/.claude/skills/`)

| Skill | Contents | Relevance to Ssak | Class |
|---|---|---|---|
| `ui-ux-pro-max` | A local design database — 67 styles, 161 palettes, 57 font pairings, 99 UX guidelines, 25 chart types, 21+ stacks **including SwiftUI**. Has `SKILL.md`, `scripts/`, `data/`. | Installed on the machine that fought three UI redesign rounds. No evidence it was used for Ssak. | **USEFUL-BUT-OPTIONAL** — and the single most plausibly *useful* item in this entire inventory, given the author's stated design gap. Worth rebuilding **only if** a future project needs it. |
| `computer-use`, `orca-cli`, `orchestration` | Directories present but **no `SKILL.md`** — non-functional or partial installs. | None. | **UNKNOWN / LIKELY-OBSOLETE** |

**Project-level skills**: none. Ssak defined **zero** custom skills [Verified].

---

## 6. Slash commands, subagents, MCP servers, scheduled tasks

| Category | State | Class |
|---|---|---|
| **Custom slash commands** (`~/.claude/commands/`) | **None.** Directory does not exist. | — |
| **Custom subagents** (`~/.claude/agents/`) | Directory exists but is **empty**. Every subagent used during the Ssak build was a built-in type (`Explore`, `general-purpose`, `Plan`) or a plugin's. | — |
| **MCP servers — global** | **None** configured in `~/.claude.json`. | — |
| **MCP servers — project** | **None.** No `.mcp.json` in the repo; `mcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers` all empty for this project [Verified]. | — |
| **MCP servers — via plugin** | Only the `github` plugin's (`.mcp.json` inside the plugin cache). Failed to connect this session. | USEFUL-BUT-OPTIONAL |
| **Scheduled tasks / crons** | `~/.claude/scheduled-tasks/` is **empty**. Nothing recurring touches Ssak. | — |
| **Workflows** | No saved workflows (`.claude/workflows/` does not exist). Multi-agent adversarial reviews during the build were ad-hoc inline scripts, not saved definitions. | LIKELY-OBSOLETE |

**Net**: the project itself declared **no** Claude-specific configuration beyond `CLAUDE.md`,
`docs/agents/`, and an untracked permissions cache. There is very little to migrate because
very little was ever project-scoped.

---

## 7. Persistent memory (auto-memory)

Location: `~/.claude/projects/-Users-michaelju-Workspace-Projects-ssak/memory/`

| File | Type | Content | Class |
|---|---|---|---|
| `MEMORY.md` | index | Two pointer lines. | CLAUDE-SPECIFIC |
| `ssak-closed.md` | project | "Ssak is over. Do not resume it." Records the close date, the framing (goals met, not failure), the tags, **and two device findings that exist in no repo file**: the iOS 26.0 simulator chrome-invisibility (use 26.5) and the 압화집 tab's ~14pt hit-area offset. Also the open manual task (pin the repo on the GitHub profile — no API exists for it). | **PROJECT-CRITICAL in part** — those three facts are conversation-only. **All three are now preserved** in `PROJECT_HANDOFF.md` §9/§13 and `DECISIONS.md` C-5/C-6. |
| `michael-backend-design-gap.md` | user | The author is mostly a backend developer; visual design is his self-identified weak point. Front-load references and concrete screen/button maps before code. Under time pressure he becomes the review bottleneck and drops review wholesale — his own fix is a short never-skip list (core loop, and every new test's assertion). | **USEFUL-BUT-OPTIONAL** — a *working-preference* fact about a person, not about Ssak. It is also stated publicly by the author himself in `RETROSPECTIVE.md` §4 and §6, so nothing is lost by not migrating it. |

**Also on disk**: a memory directory for the pre-rename path,
`~/.claude/projects/-Users-michaelju-Workspace-Projects-meok/memory/`, containing
`ssak-restart.md` — a 2026-07-19 snapshot of the moment Meok was scrapped, including the
locked restart decisions and the fact that the six species and the "no procedural runtime
engine = the specific Meok trap" rule were settled *before* any Ssak code existed.
**PROJECT-CRITICAL as history** — now folded into `DECISIONS.md` Era 0/Era 1.

**Known stale values in `ssak-closed.md`** (recorded here so they are not trusted later):
"186 commits", "63 Swift files / 5,720 LOC", "`POSTMORTEM.md`", and a Korean-draft path
`~/Workspace/Projects/ssak-retro.md` that **no longer exists**. Corrected figures are in
`PROJECT_HANDOFF.md` §15.

---

## 8. Session transcripts

- `~/.claude/projects/-Users-michaelju-Workspace-Projects-ssak/` — **4 `.jsonl` transcripts, 42 MB**.
- `~/.claude/projects/-Users-michaelju-Workspace-Projects-meok/` — memory only, no transcripts (8 KB).
- **Class**: **UNKNOWN / archival.** These are the raw record of how the project was built and
  the only source for several facts in `DECISIONS.md` (the one-off "push to main" approval,
  the multi-agent review findings, the ponytail mode). They are *evidence*, not configuration.
- **Recommendation**: **keep the directory; do not migrate it.** Everything durable has been
  extracted into the three companion documents. If they are ever deleted, the extracted facts
  survive; the raw sessions do not.

---

## 9. Untracked in-repo agent residue — `<repo>/.superpowers/`

Gitignored (`.gitignore:5` "Brainstorming companion sessions"), present locally:

- `.superpowers/sdd/` — the subagent-driven-development working set: `task-1..10-brief.md`,
  matching `task-N-report.md`, `progress.md`, and several `review-<sha>..<sha>.diff` files.
  A genuinely interesting record of how the build was decomposed, and **the only place the
  per-task briefs survive** (the tracked `docs/superpowers/plans/` holds the plans, not the
  per-task agent briefs).
- `.superpowers/brainstorm/` — session scratch, plus `.last-port` and **`.last-token`**.
- **`.last-token` was deliberately not opened.** It is a local session handle; whatever it
  contains must not be copied anywhere. Treat it as a credential-shaped file.
- **Class**: **USEFUL-BUT-OPTIONAL** (`sdd/`) · **CLAUDE-SPECIFIC** (`brainstorm/`).
- **Recommendation**: leave in place, gitignored. Do not commit, do not migrate, do not read
  `.last-token`.

---

## 10. Summary: what — if anything — is worth rebuilding

**Carry forward (already in the repo, nothing to rebuild):**

1. `CONTEXT.md` — the domain glossary. Pure project knowledge.
2. `docs/adr/` — the two architectural decision records.
3. `docs/superpowers/specs/` + `plans/` — the specs, the D1–D14 / R1–R9 / D1–D12 decision
   ledgers, and the plan documents that record deliberate deviations and hard-won gotchas
   (notably the environment-sensitivity of reference PNGs).

Plus the three documents written alongside this one: `PROJECT_HANDOFF.md`, `DECISIONS.md`,
`ROADMAP.md`.

**Consider rebuilding later, only if actually missed:**

- `ui-ux-pro-max`-style design reference data — the one capability that maps directly onto the
  author's stated bottleneck. Not needed for Ssak; possibly valuable for the next project.
- A GitHub integration — but `gh` on the CLI already covered every use in this project, and
  the MCP plugin failed to connect anyway.

**Do not rebuild:**

- The 12 Orca hooks and the custom status line (third-party session observability).
- The `autoMode.environment` briefing block — it is stale and points at a different project.
- Pre-approved permission caches (they encode past clicks, not decisions).
- The triage/issue-tracker skill scaffolding — the tracker was already dormant in the Ssak era.
- Any of the global `CLAUDE.md` behavioral rules. They describe how to make *Claude* behave;
  the two that produced visible artifacts (no `LICENSE`, no secrets) are recorded as **facts**
  in `DECISIONS.md` and `PROJECT_HANDOFF.md`, which is the durable form.
