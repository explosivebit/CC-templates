# INDEX — archived

This repo is archived (see `README.md`). The catalog of skills now lives
in the published plugin at
[`ForgePlan/marketplace/plugins/fpl-skills/`](https://github.com/ForgePlan/marketplace/tree/main/plugins/fpl-skills).

## What was indexed here (historical)

- **Guides** (`guides/`) — still present in this repo, also bundled in the
  plugin's `skills/bootstrap/resources/guides/`:
  - [CLAUDE-MD-GUIDE](guides/CLAUDE-MD-GUIDE.ru.md) — how to write
    `CLAUDE.md` accounting for LLM weaknesses (U-curve, cry-wolf, dilution).
  - [GIT-FLOW-GUIDE](guides/GIT-FLOW-GUIDE.ru.md) — Git Flow + Conventional
    Commits + PR + SemVer + safety rules against AI destructiveness.

- **Skills** (was `skills/`) — migrated to
  `forgeplan-marketplace/plugins/fpl-skills/skills/`:
  audit, autorun, bootstrap, briefing, build, diagnose, do, refine,
  research, restore, rfc, setup, sprint, team.

- **Plugin manifest, hooks, build script** — migrated to
  `forgeplan-marketplace/plugins/fpl-skills/`.

- **Authored prompts** (`prompts/`) — gitignored; remained local.

- **External research** (`research/`) — gitignored; remained local.

- **Scripts** (`scripts/`) — `install-skill.sh` for the old per-skill
  install flow; obsolete now that everything ships as one plugin.
