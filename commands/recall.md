---
description: 'Restore context — Hindsight memory + recent git commits + branch status. Use at session start.'
argument-hint: "[optional: topic — e.g. 'memory', 'ontology', 'webapp']"
---

# /recall — Restore Context

**Quick context restore from Hindsight memory and git history.**

---

## Workflow

### Step 1: GATHER (all in parallel)

#### 1A. Hindsight Memory

```
memory_recall(query: "recent decisions, architecture changes, current sprint status")
memory_recall(query: "blockers, bugs, known issues, pending work")
```

If `$ARGUMENTS` provided:

```
memory_recall(query: "$ARGUMENTS — recent work, decisions, status, next steps")
```

#### 1B. Git History (bash, parallel)

```bash
# Branch + dirty state
git branch --show-current
git status --short

# Last 15 commits (graph view)
git log --oneline --all --graph -15

# Last 10 on current branch
git log --format="%h %ad %s" --date=relative -10

# Changed files in last 5 commits
git diff --stat HEAD~5..HEAD 2>/dev/null || echo "Less than 5 commits"

# Stashes
git stash list
```

### Step 2: SYNTHESIZE

From gathered data extract:

1. **Branch & intent** — what RFC/feature is in progress
2. **Recent progress** — last 5-10 commits summary
3. **Decisions** — key choices from Hindsight
4. **Open items** — blockers, bugs, pending tasks
5. **Dirty state** — uncommitted changes, stashes

### Step 3: PRESENT

```markdown
# Context — $DATE

**Branch**: `$BRANCH` | **Last commit**: $TIME ago

---

## Recent Commits

| Commit | When | Description |
| ------ | ---- | ----------- |

## Changed Areas

(group by package/app)

## From Memory

### Decisions & Context

- ...

### Current Focus

- ...

### Known Issues

- ...

---

## Working Tree

$STATUS (or "Clean")

## Stashes

$STASHES (or "None")

---

## Next Steps

1. ...
2. ...
```

### Step 4: SUGGESTIONS

- Uncommitted changes → "Review and commit"
- Hindsight mentions pending TODO → "Continue with: ..."
- Recent commits in one area → "Focused on [X], next logical step: [Y]"
- `$ARGUMENTS` matches RFC → link to RFC file, show progress bar
