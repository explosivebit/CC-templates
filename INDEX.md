# INDEX — map of every artifact

This file is the repository's "table of contents". When you add a new artifact,
add one line here in this format:
`- [name](path) — one line about the gist and when to reach for it`

Keep lines under ~150 characters; lists are alphabetised.

---

## Guides (`guides/`)

- [CLAUDE-MD-GUIDE](guides/CLAUDE-MD-GUIDE.ru.md) — how to write `CLAUDE.md` accounting for LLM weaknesses (U-curve, cry-wolf, dilution).
- [GIT-FLOW-GUIDE](guides/GIT-FLOW-GUIDE.ru.md) — Git Flow + Conventional Commits + PR + SemVer + safety rules against AI destructiveness.

## Skills (`skills/`)

Every skill automatically exposes a slash command `/<folder-name>`.

- [audit](skills/audit/SKILL.md) — multi-expert review of code/architecture (≥4 agents: logic, SOLID, types, security; synthesis + verdict). `/audit`.
- [autorun](skills/autorun/SKILL.md) — autopilot orchestrator: one prompt → research → sprint → audit → report with no approval checkpoints; ADI on dead-ends, stops only on red-lines (push main, secrets, deploy, deletes). For overnight / bypass-permissions sessions. `/autorun`.
- [bootstrap](skills/bootstrap/SKILL.md) — drops the author's starter scaffold (CLAUDE.md + guides/) into a new or existing project. `/bootstrap`.
- [briefing](skills/briefing/SKILL.md) — morning briefing of tasks/messages from a task tracker (Orchestra/Linear/Jira/GitHub) or local TODO files. `/briefing`.
- [build](skills/build/SKILL.md) — runs the implementation command from a finished research report (IMPLEMENTATION-PLAN.md → wave-by-wave). `/build`.
- [diagnose](skills/diagnose/SKILL.md) — disciplined 6-phase debug loop for hard bugs and perf regressions: build feedback loop → reproduce → hypothesise (3-5 ranked) → instrument → fix + regression test → cleanup. Phase 1 ("build a feedback loop") is the skill itself; the rest is mechanics. Adapted from mattpocock/skills. `/diagnose`.
- [do](skills/do/SKILL.md) — meta-orchestrator: parses the task, builds a pipeline of other skills (research → write-doc → sprint → audit), executes it with approval checkpoints. `/do`.
- [refine](skills/refine/SKILL.md) — interview-driven refinement of a plan/design/RFC: relentless walk through the decision tree (one Q at a time), sharpen fuzzy terminology, surface contradictions against CONTEXT.md and the code, lazy-create CONTEXT.md/ADR on the fly. Adaptation of mattpocock grill-with-docs. `/refine`.
- [research](skills/research/SKILL.md) — deep research with 5 parallel agents (code, docs, status, reference, knowledge). `/research`.
- [restore](skills/restore/SKILL.md) — restores session context: git + working copy + (opt.) persistent memory. `/restore`.
- [rfc](skills/rfc/SKILL.md) — create/read/update RFCs and ADRs: meta header, phase progress, implementation log, ADR. `/rfc`.
- [setup](skills/setup/SKILL.md) — interactive wizard for project configuration: issue tracker / build commands / paths / domain glossary → writes into `docs/agents/*.md` (+ creates `CONTEXT.md`). The backbone of de-genericification. `/setup`.
- [sprint](skills/sprint/SKILL.md) — wave-based feature execution (full sprint with research / lightweight wave from chat context) with TeamCreate, file ownership, insights extraction. `/sprint`.
- [team](skills/team/SKILL.md) — foundation for multi-agent teams: TeamCreate vs sub-agents, file ownership, recipes, cleanup. The base for other multi-agent skills. `/team`.

## Agents (`agents/`)

_Empty for now. Template and rules — `agents/README.md`._

## Slash commands (`commands/`)

In Claude Code 2026 skills and commands are unified — every skill in `skills/` automatically exposes a `/<name>` slash command. So there are no separate files in `commands/`: everything has been moved into `skills/`.

`commands/README.md` is kept as a guide for the case where you ever need to add a thin wrapper with arguments/prefixes around an existing skill.

## Prompts (`prompts/`)

- [forgeplan-phase-5/](prompts/forgeplan-phase-5/README.md) — bundle of briefs to close ForgePlan Phase 5: engine-brief (Rust), marketplace-brief (content), daily-usage.

## Templates (`templates/`)

_Empty for now. Template and rules — `templates/README.md`._

## Snippets (`snippets/`)

_Empty for now. Template and rules — `snippets/README.md`._

## Scripts (`scripts/`)

- [install-skill.sh](scripts/install-skill.sh) — installs a skill into `~/.claude/skills/` (symlink by default; flags `--copy`, `--force`, `--dry-run`).
