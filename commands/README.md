# commands/

Claude Code slash commands. Each command is a single `.md` file.

Invoke in a session: `/<command-name> <args>`.

---

## `<command-name>.md` template

```markdown
---
description: One line: what the command does. Shown in the `/` menu.
argument-hint: "<arg1> [arg2]"     # optional: argument hint
allowed-tools: Read, Edit, Bash    # optional: tool whitelist
---

# Instruction for Claude

The command body is a **prompt** that gets injected into the conversation
when the user runs `/<command-name>`. Write in the imperative, addressed
to Claude.

Arguments are available as `$ARGUMENTS`, `$1`, `$2`, etc.

## Example

1. Read file `$1`.
2. Find functions longer than 50 lines.
3. Suggest how to split them.
```

---

## Rules

- **File name** = command name, `kebab-case`. Invoke as `/<filename-without-.md>`.
- Commands are **prompt templates**, not code. Don't keep bash scripts here;
  those go in `scripts/`.
- `description` — concise, under 80 characters; visible in autocomplete.
- If a command does multistep work that won't fit in one prompt, consider
  shaping it as an **agent** or **skill** instead.

## Install

Globally:

```bash
cp commands/<name>.md ~/.claude/commands/
```

Per project:

```bash
mkdir -p <project>/.claude/commands
cp commands/<name>.md <project>/.claude/commands/
```

## After adding one

1. Update `INDEX.md` (Slash commands section).
2. Commit: `feat(commands): add /<command-name>`.
