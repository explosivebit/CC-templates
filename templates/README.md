# templates/

Starters and boilerplate: ready-made `CLAUDE.md`, `.claude/settings.json`,
basic project structure — anything convenient to copy wholesale into a
new project.

Layout — **by artifact type**:

```
templates/
├── claude-md/          # CLAUDE.md variants for different stacks
├── settings/           # .claude/settings.json presets
├── hooks/              # ready-made hook configs
└── project-skeleton/   # full skeleton for a new project
```

---

## File template

Each template ships with a short `README.md` alongside:

```markdown
# <Template name>

**For**: project type / scenario.
**Contains**: list of files.
**How to apply**: copy commands + what to edit afterward.
```

---

## Rules

- A template must be **self-contained** — copy the folder, get a working
  artifact without manual assembly.
- Placeholders in plain form: `<PROJECT_NAME>`, `<AUTHOR>` — easy to grep
  and replace.
- Don't hardcode absolute paths or personal data.

## After adding one

1. Update `INDEX.md` (Templates section).
2. Commit: `feat(templates): add <name>`.
