# agents/

Claude Code agents. Each agent is a single `.md` file with YAML frontmatter.

---

## `<agent-name>.md` template

```markdown
---
name: <agent-name>
description: Runs when <trigger>. Examples: <short scenario 1>; <short scenario 2>.
tools: Read, Grep, Glob, Bash     # optional: restrict tool set
model: sonnet                     # optional: sonnet | opus | haiku
---

# <Title>

## Role

One or two sentences: who the agent is and what specific work it does.

## Inputs

- What it receives (e.g. file path, PR number).

## Process

1. Step 1
2. Step 2

## Output

The response format the agent returns to the main conversation.

## Boundaries

- What the agent does NOT do (e.g. doesn't write code, only reviews).
```

---

## Rules

- **File name** = `<name>.md`, `kebab-case`.
- **`description`** with example triggers — this is what Claude uses to
  decide whether to invoke the agent. Describe situations, not capabilities.
- Keep `tools` to the minimum sufficient set — fewer tools means less noise
  and tighter focus.
- Agent ≠ skill: an agent **runs in an isolated subprocess** and returns a
  summary. A skill runs in the main conversation.

## Install

```bash
cp agents/<name>.md ~/.claude/agents/
# or
ln -s "$(pwd)/agents/<name>.md" ~/.claude/agents/<name>.md
```

## After adding one

1. Update `INDEX.md` (Agents section).
2. Commit: `feat(agents): add <agent-name>`.
