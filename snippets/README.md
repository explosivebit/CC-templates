# snippets/

Small reusable fragments: hook configs, `permissions` blocks, regexes,
markdown checklists, `settings.json` snippets.

A snippet is a **fragment**, not a standalone artifact. It's pasted into
another file.

---

## Layout

```
snippets/
├── hooks/                  # hook config examples for settings.json
├── permissions/            # permissions blocks (allow/deny lists)
├── checklists/             # markdown checklists for PRs, code review
├── regex/                  # useful regular expressions
└── frontmatter/            # ready-made frontmatter blocks
```

---

## `<folder>/<name>.md` template

```markdown
# <Snippet name>

**Purpose**: where it goes and why.
**Where to paste**: path / context (e.g. `~/.claude/settings.json`,
`hooks.PostToolUse` section).

---

```<language>
<snippet body>
```

## Notes

- Dependencies, gotchas, what to tweak per project.
```

---

## Rules

- A snippet is **small**. If it grew past 100 lines, it's a template — move
  it to `templates/`.
- Always state **where** to paste it — otherwise in a month it's unclear
  why it exists.
- Don't duplicate snippets across folders; if two places need one, keep a
  single copy and link to it.

## After adding one

1. Update `INDEX.md` (Snippets section).
2. Commit: `feat(snippets): add <folder>/<name>`.
