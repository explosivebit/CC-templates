# CC-templates — archived

> **This repo is archived.** It used to be the authoring lab for the
> `fpl-skills` plugin. As of 2026-05-07 the plugin lives in
> [`ForgePlan/marketplace`](https://github.com/ForgePlan/marketplace) under
> `plugins/fpl-skills/`. Continue work there.

## What used to be here

Over 14 commits, this repo iterated on the skill set that became the
fpl-skills plugin:

- 14 skills (research, refine, sprint, audit, diagnose, autorun, do,
  build, briefing, restore, rfc, setup, bootstrap, team)
- A universal CLAUDE.md template with stack detection
- A SessionStart hook
- The plugin manifest and a build/snapshot script

The full history of those edits is in this repo's git log. Useful to
read if you want to understand _why_ a particular skill is shaped the
way it is — most decisions were made in PRs and chat in this lab, not
in marketplace commit messages.

## What's still here

Personal notes that don't ship in the plugin:

- `guides/` — author's Russian-language guides (kept here, not
  republished). Two of these are also bundled inside the plugin
  (`bootstrap/resources/guides/CLAUDE-MD-GUIDE.ru.md`,
  `GIT-FLOW-GUIDE.ru.md`).
- `prompts/` — gitignored; personal one-off prompt drafts.
- `research/` — gitignored; reference materials I gathered while
  authoring the skills.
- `commands/README.md` — historical note about the unification of skills
  and slash commands in Claude Code 2026.

## Where to go for everything else

- **Source of truth for skills**: https://github.com/ForgePlan/marketplace/tree/main/plugins/fpl-skills
- **forgeplan CLI**: https://github.com/ForgePlan/forgeplan
- **Marketplace catalog**: https://github.com/ForgePlan/marketplace
- **Install the plugin**: in Claude Code →
  ```
  /plugin marketplace add ForgePlan/marketplace
  /plugin install fpl-skills@ForgePlan-marketplace
  /reload-plugins
  ```

## License

MIT — same as the published plugin.
