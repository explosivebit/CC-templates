# CC-templates

A personal library of artifacts for Claude Code: guides, skills, agents,
slash commands, prompt and settings templates. Used as a "source" — the pieces
you need get plugged into new projects from here.

---

## Quick start

```bash
# 1. Clone / cd into the directory
cd ~/Work/ExtraBoostLessons/CC-templates

# 2. See what's here
cat INDEX.md

# 3. Install a skill into ~/.claude/skills/
./scripts/install-skill.sh <skill-name>

# 4. Use a prompt template — copy it into a new project
cp prompts/<topic>/<name>.md <target-project>/
```

> Install scripts are added as artifacts appear. While folders are still
> empty — use `INDEX.md` as the map.

---

## Structure

```
CC-templates/
├── CLAUDE.md          # how to work with this repo (instructions for Claude Code)
├── README.md          # this file
├── INDEX.md           # index of every artifact
├── guides/            # long-form authored guides (CLAUDE.md, Git Flow, …)
├── skills/            # Claude Code skills (folder with SKILL.md)
├── agents/            # agents (.md with frontmatter)
├── commands/          # slash commands
├── prompts/           # one-off prompt templates by topic
├── templates/         # starters: CLAUDE.md, settings.json, structure
├── snippets/          # hooks, permissions, regex, checklists
└── scripts/           # install/symlink into ~/.claude
```

Every subfolder has its own `README.md` with formatting rules and a template
for a new artifact.

---

## Navigation

- **I want to see everything at once** → `INDEX.md`
- **I want to add a new artifact** → `CLAUDE.md` → "How to work" section
- **I want to understand how to write my own `CLAUDE.md`** → `guides/CLAUDE-MD-GUIDE.ru.md`
- **I want the git/PR/release process** → `guides/GIT-FLOW-GUIDE.ru.md`

---

## License / sharing

Personal library. If you share it with someone — make sure the artifacts
contain no personal data, tokens, or internal links.
