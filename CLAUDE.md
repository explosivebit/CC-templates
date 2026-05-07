# CLAUDE.md — CC-templates (archived)

> **This repo is archived.** It used to be the authoring lab for the
> `fpl-skills` plugin. Active development continues in
> [`ForgePlan/marketplace`](https://github.com/ForgePlan/marketplace) under
> `plugins/fpl-skills/`. See `README.md` for the redirect.

If you're starting a new Claude Code session and the goal is the
fpl-skills plugin — `cd` to the marketplace repo instead, and read
`plugins/fpl-skills/HANDOFF.md` for the current state and next steps:

```
cd ~/Work/Skills/forgeplan-marketplace
git checkout feat/fpl-skills-plugin
cat plugins/fpl-skills/HANDOFF.md
```

---

## What's still here (don't touch unless intentional)

- `guides/` — Russian-language authored guides (CLAUDE-MD, GIT-FLOW). The
  plugin bundles copies of these under
  `plugins/fpl-skills/skills/bootstrap/resources/guides/` — so edits here
  don't auto-propagate; if you want to update them, edit in both places
  or sync.
- `prompts/forgeplan-phase-5/`, `research/` — gitignored, personal
  reference materials. Not republished.
- `agents/`, `commands/`, `snippets/`, `templates/` — empty placeholder
  folders (with READMEs documenting historical convention). Safe to
  delete if you ever want to clean up.

## Why this repo still exists

- `git log` here is the authoring history of the plugin (14 commits).
  The marketplace import is one squash commit on top of that history; if
  you want to understand why a skill is shaped a certain way, this log
  is where the answer is.
- `guides/*.ru.md` aren't redistributable as plugin content (not in the
  English plugin convention) but are useful personal references.

## Red lines (still apply if you do edit)

- Don't recreate `skills/`, `.claude-plugin/`, `hooks/` here. Edit in
  the marketplace.
- Don't delete `guides/*.ru.md` — they're referenced from the plugin.
- Don't rewrite git history pre-archive — the lineage is the point.
