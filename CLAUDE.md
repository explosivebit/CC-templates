# CLAUDE.md — CC-templates

A personal library repository of artifacts for Claude Code: guides, skills, agents,
slash commands, prompt templates, settings snippets. The goal — quickly plug
proven artifacts into new projects.

---

## 🔴 Red lines

- **Don't overwrite other people's guides** without an explicit request — files in `guides/`
  are considered a stable knowledge base; edits go through a commit with a stated reason.
- **Don't duplicate content** between artifacts: one source of truth, the rest link to it.
  Duplicates go stale at different rates and become misleading.
- **Don't commit secrets here** (`.env`, tokens, keys) — the repository is intended for
  publication / sharing.
- **Don't run `install` scripts against someone else's `~/.claude`** without the user's
  confirmation — they copy files into their home directory.

---

## What this project is

This is a **catalog of reusable artifacts** for Claude Code. There's no application
living here — what lives here is:

- `guides/` — long-form authored guides (markdown)
- `skills/` — Claude Code skills (folders with `SKILL.md`)
- `agents/` — agents (`.md` with YAML frontmatter)
- `commands/` — slash commands (`.md` with frontmatter)
- `prompts/` — one-off prompt templates (organized by topic)
- `templates/` — starters: ready-made `CLAUDE.md`, `.claude/settings.json`, repo structure
- `snippets/` — small pieces: hooks, permissions, regex, checklists
- `scripts/` — helper scripts (installing skills/agents into `~/.claude`)

The full artifact index lives in the root `INDEX.md`. The conventions for each
type live in the `README.md` inside the corresponding folder.

---

## How to work in this repository

### Add a new artifact

1. Decide the type (skill / agent / command / prompt / template / snippet / guide).
2. Open the `README.md` in the matching folder — it has the template and naming rules.
3. Create the artifact from the template. The file/folder name is `kebab-case`, in English.
4. Add one line to the root `INDEX.md` in the right section.
5. Commit using Conventional Commits (`feat(skills): add ...`).

### Update an existing one

- Edit the file itself; update its description/frontmatter when the purpose changes.
- If the name changes — rename the file **and** update `INDEX.md`.

### Reference a guide from inside an artifact

- Use relative paths from the repo root: `../../guides/CLAUDE-MD-GUIDE.ru.md`.
- Don't copy fragments of a guide into a skill — link only.

---

## Conventions

- **Language**: markdown content — Russian (suffix `.ru.md` for explicitly Russian-language
  authored guides). File names, frontmatter fields, artifact names — English.
- **Names**: `kebab-case`. Examples: `git-flow-guide`, `code-review-strict`,
  `planning-prd`.
- **Frontmatter**: skills and agents use YAML (`---` ... `---`) with required
  `name` and `description`. The description must explain *when* to invoke it,
  not *what* it does.
- **Size**: one artifact — one file/one folder, one purpose. If a prompt grows
  into a guide — move it to `guides/`.

---

## Git process

We follow the rules in `guides/GIT-FLOW-GUIDE.ru.md` — `feature/*` branches,
Conventional Commits, PR into `main` with review. It's the canonical reference:
**follow the guide, don't duplicate its content here**.

Destructive operations (`push --force`, `reset --hard`, branch deletion, etc.) —
only on explicit user request.

---

## Non-goals

- This is **not** an executable project: no `package.json`, no build pipeline, no
  CI for builds. CI, if it ever appears, is only for markdown lint / frontmatter
  validation.
- This is **not** a replacement for the user's `~/.claude/` — the repository is
  the source from which artifacts are copied/symlinked into `~/.claude`.
- This is **not** the public Claude Code documentation — it's the author's
  personal library.
