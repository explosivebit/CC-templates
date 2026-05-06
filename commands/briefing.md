---
description: "Daily briefing from Orchestra — unread messages, mentions, today's tasks, overdue, project stats. Your morning standup in 10 seconds."
argument-hint: "[optional: focus area — e.g. 'Development', 'Product', 'full']"
---

# /briefing — Daily Orchestra Briefing

**Your morning standup from Orchestra. Shows everything you need to know to start the day.**

Examples:

- `/briefing` — full briefing (all sections)
- `/briefing Development` — focus on Development project only
- `/briefing urgent` — only overdue + mentions + unread

---

## Workflow

### Step 1: GATHER — Parallel Data Collection

**Run ALL of these in parallel** (they're independent):

```
mcp__orch__get_current_context()          → who am I, which workspace
mcp__orch__get_workspace_overview()       → projects, folders, teams
mcp__orch__get_unread_chats()             → unread messages
mcp__orch__get_mentions()                 → @mentions
mcp__orch__get_reminders()                → active reminders
mcp__orch__get_starred_messages()         → saved messages
mcp__orch__query_entities(repoType="folder", repoUid="today")              → due today
mcp__orch__query_entities(repoType="folder", repoUid="expired")            → overdue
mcp__orch__query_entities(repoType="folder", repoUid="assigned_to_me")     → my tasks
mcp__orch__query_entities(repoType="folder", repoUid="recently_completed") → completed
```

### Step 2: FOCUS — Apply Filter (if provided)

If `$ARGUMENTS` contains a project name, filter results to that project only.
If `$ARGUMENTS` = "urgent", show only: overdue + mentions + unread.
If empty, show everything.

### Step 3: PRESENT — Formatted Briefing

Present the briefing in this exact format:

```markdown
# Daily Briefing — $DATE

**Workspace**: $WORKSPACE_NAME | **User**: $USER_NAME

---

## Urgent Attention

### Overdue Tasks ($COUNT)

| Task | Project | Due | Days Late | Priority |
| ---- | ------- | --- | --------- | -------- |

### Unread Messages ($COUNT chats)

| Chat | Type | Unread | Last Message |
| ---- | ---- | ------ | ------------ |

### @Mentions ($COUNT)

| From | In  | Message | When |
| ---- | --- | ------- | ---- |

---

## Today's Focus

### Due Today ($COUNT)

| Task | Project | Status | Priority |
| ---- | ------- | ------ | -------- |

### Assigned to Me ($COUNT)

| Task | Project | Status | Priority |
| ---- | ------- | ------ | -------- |

---

## Project Status

| Project | Total Tasks | Backlog | To Do | Doing | Review | Done |
| ------- | ----------- | ------- | ----- | ----- | ------ | ---- |

---

## Quick Stats

| Metric                  | Count |
| ----------------------- | ----- |
| Total active tasks      | N     |
| Assigned to me          | N     |
| Due today               | N     |
| Overdue                 | N     |
| Recently completed (7d) | N     |
| Unread chats            | N     |
| Pending reminders       | N     |
| Starred messages        | N     |

---

## Active Reminders

| Message | Chat | Remind At |
| ------- | ---- | --------- |

## Starred for Later

| Message | Chat | Saved At |
| ------- | ---- | -------- |
```

### Step 4: ACTIONABLE INSIGHTS

After the data, add a short **"Recommended Actions"** section:

```markdown
## Recommended Actions

1. **[Priority]** [action] — [reason]
   e.g., "Reply to @mention in Development — question about API"
2. **[Priority]** [action] — [reason]
   e.g., "Task 'Core - v1' is overdue — update status or reschedule"
```

Logic for recommendations:

- Overdue tasks → suggest updating or completing
- Unread messages → suggest reading most active chat
- @Mentions → suggest replying
- Tasks in "Doing" for >3 days → suggest moving to Review
- Reminders due today → remind about them

---

## Sections to Skip

Skip any section that has 0 items (don't show empty tables). But always show "Quick Stats".

---

## Focus Modes

### `/briefing urgent`

Show ONLY:

- Overdue tasks
- Unread messages
- @Mentions
- Recommended Actions

### `/briefing [project name]`

Filter all sections to that project only. Use `query_entities` with `repoType="project"` and the project UID.

### `/briefing full`

Show everything including starred messages and reminders (default behavior).

---

## Tips

1. **Run at start of day** — gives you full context in seconds
2. **Focus mode** — `/briefing Development` when you know what you're working on
3. **Follow up** — use `/orch task [uid]` to drill into specific tasks
4. **Navigate** — briefing shows UIDs, use `/orch navigate task [uid]` to open in Orchestra UI
