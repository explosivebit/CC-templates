---
name: bootstrap
description: Deploys the author's Claude Code starter scaffold into a new or existing project — creates a CLAUDE.md from the template, a guides/ folder with author guides (Git Flow, CLAUDE.md best practices), and guides/INDEX.md. Use when the user starts a new project and wants the standard Claude Code baseline, or when adding these guides to an existing project. Triggers (EN/RU) — "bootstrap project", "init claude baseline", "install my guides", "scaffold claude code", "поставь мои гайды", "разверни базу", "установи базовый CLAUDE.md", "подготовь проект под claude", "засетапь проект".
---

# Bootstrap Claude Project

Deploys the baseline Claude Code artifacts into the current project:
`CLAUDE.md`, `guides/` with author guides, `guides/INDEX.md`.

The skill's resources live next to this SKILL.md, in `resources/`:

```
~/.claude/skills/bootstrap/
├── SKILL.md           ← you are reading this
└── resources/
    ├── guides/
    │   ├── CLAUDE-MD-GUIDE.ru.md
    │   ├── GIT-FLOW-GUIDE.ru.md
    │   └── INDEX.md.template
    └── templates/
        └── CLAUDE.md.template
```

If the skill is invoked from the source repo (`CC-templates/skills/bootstrap`),
the same paths are valid relative to that directory — use the absolute path to
the directory containing this SKILL.md.

---

## When to use

- The user starts a new project and asks to "deploy the baseline", "install the guides", "bootstrap".
- An existing project lacks `CLAUDE.md` or `guides/`, and the user wants it brought up to standard.
- The user explicitly mentions one of the triggers from `description`.

## When NOT to use

- The current cwd is the `CC-templates` repo itself (it's the source — no need to scaffold it).
  → Detect by checking for `CLAUDE.md` + `skills/bootstrap/` in cwd.
- The project already has both `CLAUDE.md` **and** a complete `guides/` — nothing to do.
  → Tell the user and exit.

---

## Input (clarify before running)

Ask the three parameters in one question if the user hasn't specified them:

1. **Target path** — where to install. Defaults to current `pwd`.
2. **Which guides** — `all` (default) / `git-flow` / `claude-md`.
3. **What to do with existing `CLAUDE.md`** — `skip` (leave alone) / `append` (add a
   "See guides" block) / `replace` (recreate from template, save the old one as `CLAUDE.md.bak`).
   Default — `append`. If `CLAUDE.md` is missing — don't ask, create from the template.

---

## Process

### 1. Orient

Run:

```bash
pwd
ls -la
git rev-parse --show-toplevel 2>/dev/null || echo "not a git repo"
test -f CLAUDE.md && echo "CLAUDE.md exists" || echo "no CLAUDE.md"
test -d guides && echo "guides/ exists" || echo "no guides/"
```

Checks:
- If **no `.git`** — warn the user: "the guides assume git, recommend `git init -b main` before continuing." Ask whether to proceed without git.
- If cwd == root of `CC-templates` (signature: `skills/bootstrap/SKILL.md` exists) — refuse with "this is the source, no need to scaffold it".

### 2. Plan

Build a short plan (3–6 lines): what will be created, what will be overwritten, what will be skipped. Show the user and wait for confirmation.

Example:
```
Buy-in:
  + CLAUDE.md (will create from template)
  + guides/CLAUDE-MD-GUIDE.ru.md (will copy)
  + guides/GIT-FLOW-GUIDE.ru.md (will copy)
  + guides/INDEX.md (will create)
Proceed? [y/n]
```

### 3. Execute

**Resolve the absolute path to resources.** Use:
```bash
SKILL_DIR="$HOME/.claude/skills/bootstrap"
test -d "$SKILL_DIR/resources" || SKILL_DIR="<absolute path to this skill in CC-templates>"
```

If the skill was installed via symlink to `CC-templates/skills/bootstrap/`, `$HOME/.claude/skills/bootstrap` works. If the skill is invoked directly from the repo (no install) — use the absolute path to the directory containing this SKILL.md.

**Run the operations for the chosen scenario:**

- **CLAUDE.md:**
  - File missing → `cp "$SKILL_DIR/resources/templates/CLAUDE.md.template" ./CLAUDE.md`, then replace the `<PROJECT_NAME>` placeholder with the project directory name (`basename "$PWD"`).
  - File present and mode `append` → append the block:
    ```
    ## Reference

    See [`guides/INDEX.md`](guides/INDEX.md) — Git Flow, CLAUDE.md best practices.
    ```
    (Deduplicate: if the block is already there, skip.)
  - Mode `replace` → `mv CLAUDE.md CLAUDE.md.bak && cp <template> CLAUDE.md`.
  - Mode `skip` → do nothing.

- **guides/ folder:** `mkdir -p guides`.

- **Copy guides:**
  - `all` → copy both `.ru.md` files from `$SKILL_DIR/resources/guides/` into `./guides/`.
  - `git-flow` → only `GIT-FLOW-GUIDE.ru.md`.
  - `claude-md` → only `CLAUDE-MD-GUIDE.ru.md`.
  - If `./guides/` already has the file — ask: overwrite / skip / diff. Default skip.

- **guides/INDEX.md:** from `resources/guides/INDEX.md.template`, keep only the lines for guides that were actually copied.

### 4. Report

Show the result:
```
✓ CLAUDE.md            created
✓ guides/              created
✓ guides/INDEX.md      created
✓ guides/GIT-FLOW-GUIDE.ru.md
✓ guides/CLAUDE-MD-GUIDE.ru.md
```

Remind the user:
- "Edit `CLAUDE.md` — the 'What this project is' section is still a placeholder."
- "If the repo has no commit yet — commit: `git add . && git commit -m \"chore: add Claude Code baseline scaffold\"`."

---

## Idempotency and safety

- **Never overwrite existing files without explicit confirmation.**
- For `replace` on CLAUDE.md — always save `CLAUDE.md.bak`.
- **Don't auto-commit.** The scaffold leaves changes in the working tree; the commit is the user's call.
- Don't touch `.git/`, `node_modules/`, `vendor/`, or other system directories.

## Errors and recovery

| Symptom | Diagnosis | Action |
|---|---|---|
| `resources/` not found | Skill is broken or not installed | Report the path you tried and ask to reinstall via `scripts/install-skill.sh bootstrap`. |
| `guides/<file>.ru.md` already exists | Idempotent re-run | Show diff; default skip. |
| cwd is `CC-templates` | Run inside the source itself | Refuse with a message. |

## Example references

See `examples/full-setup.md` next to this SKILL.md — a full dialogue example.
