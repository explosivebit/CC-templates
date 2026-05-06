---
description: Launch implementation team based on existing research reports. Reads IMPLEMENTATION-PLAN.md + CONTINUATION-PROMPT.md and spawns backend/frontend/test agents.
argument-hint: "[path to research report directory] — e.g. 'research/reports/queue-workflows-deep-research-2026-02-11'"
---

# /build — Implement from Research Reports

**Takes a completed research directory** (from `/deep-research`) and spawns an implementation team based on IMPLEMENTATION-PLAN.md and CONTINUATION-PROMPT.md.

Examples:

- `/build research/reports/queue-workflows-deep-research-2026-02-11`
- `/build research/reports/kms-deep-research-2026-02-11`
- `/build research/reports/graphrag-e2e-2026-02-11`

**Input**: A `research/reports/` directory with IMPLEMENTATION-PLAN.md
**Output**: Working code, tests, updated TODO files

---

## Prerequisites

The research directory MUST contain:

- `IMPLEMENTATION-PLAN.md` — phased plan with file ownership map
- `CONTINUATION-PROMPT.md` — stage prompts (optional but recommended)
- `00-SUMMARY.md` — executive summary with ADRs

If missing, suggest running `/deep-research` first.

---

## Workflow

### Step 0: VALIDATE INPUT

```
$ARGUMENTS must be a valid path to research/reports/{dir}/
Check: IMPLEMENTATION-PLAN.md exists
Check: 00-SUMMARY.md exists
```

If no `$ARGUMENTS`, list available research directories:

```
ls research/reports/
```

### Step 1: READ PLAN

Read the implementation plan and present phases to user:

```
Read("$ARGUMENTS/IMPLEMENTATION-PLAN.md")
Read("$ARGUMENTS/00-SUMMARY.md")
Read("$ARGUMENTS/CONTINUATION-PROMPT.md")  # if exists
```

**Present to user:**

```markdown
## Build Plan from: {research-dir}

### Available Phases

| Phase | Name             | Priority | Effort  | Dependencies |
| ----- | ---------------- | -------- | ------- | ------------ |
| 1     | [from IMPL-PLAN] | P0       | 2 weeks | None         |
| 2     | [from IMPL-PLAN] | P0       | 3 weeks | None         |
| 3     | ...              | P1       | ...     | Phase 2      |

### Team Composition

| Role         | Agent Type      | Phases |
| ------------ | --------------- | ------ |
| backend-dev  | general-purpose | 1, 2   |
| frontend-dev | general-purpose | 1, 3   |
| test-writer  | general-purpose | All    |

### Which phases to build?

- "all" — all phases sequentially
- "1,2" — specific phases
- "parallel 1,2" — phases 1+2 in parallel
```

Wait for user to select phases.

### Step 2: PREPARE CONTEXT

For each selected phase, extract from IMPLEMENTATION-PLAN.md:

- Task list (file paths, LOC estimates, test counts)
- Acceptance criteria
- File ownership map
- Dependencies

Combine with:

- CONTINUATION-PROMPT.md stage prompts (if available)
- 00-SUMMARY.md ADRs and key decisions
- Relevant detailed reports (for domain context)

### Step 3: SPAWN IMPLEMENTATION TEAM

```
TeamCreate: "build-{topic}"
```

**Agent allocation:**

- **backend-dev**: Prisma schema, stores, services, workers
- **frontend-dev**: Pages, hooks, components, UI
- **agent-dev** (if agent work): Executor, orchestrator, messaging
- **test-writer**: Tests for all layers

**Agent prompt template:**

```
You are a {role} implementing Phase {N} of the {topic} plan.

## Context
Read these files FIRST:
- CLAUDE.md — project overview, key commands
- {research-dir}/00-SUMMARY.md — research summary + ADRs
- {research-dir}/IMPLEMENTATION-PLAN.md — YOUR tasks in Phase {N}
- {research-dir}/{relevant-report}.md — domain context

## Your Tasks (from IMPLEMENTATION-PLAN.md Phase {N})
{paste task table from IMPL-PLAN}

## Acceptance Criteria
{paste from IMPL-PLAN}

## Project Rules
1. Use APIError with ResponseCode — NEVER generic throw new Error()
2. Use getTenantIdStrict(ctx) for auth — NEVER getTenantId(ctx)
3. API data in TanStack Query — NEVER in Zustand
4. After modifying packages/*, rebuild: pnpm --filter @gerts/[pkg] build
5. Follow FSD layers: shared > entities > features > views > widgets > app
6. Zustand: NEVER use getters (use selector functions)

## Verification
After completing all tasks:
- pnpm --filter @gerts/{pkg} build (must pass)
- pnpm --filter @gerts/{pkg} test (must pass)
- pnpm -r exec tsc --noEmit (must pass)
```

### Step 4: MONITOR & COORDINATE

- Track task completion
- When backend-dev finishes stores → unblock frontend-dev for hooks
- When test-writer needs types → ensure stores are built first
- Handle blockers — adjust tasks if needed

### Step 5: VERIFY

After all agents complete:

```bash
# Type check all
pnpm -r exec tsc --noEmit

# Build affected packages
pnpm --filter @gerts/{affected-pkgs} build

# Run tests
pnpm --filter @gerts/{affected-pkgs} test
```

### Step 6: UPDATE DOCS

1. **TODO files** — mark completed items as `[x]`, add new `[ ]` for gaps
2. **KNOWN-ISSUES.md** — if bugs discovered during implementation
3. **Memory** — save key decisions:
   ```
   memory_retain("# Build: {topic} — Phase {N} Complete
   Implemented: [list]
   Tests: N passing
   Gaps remaining: [list]
   Key decisions: [list]")
   ```

### Step 7: CLEANUP

```
Shutdown teammates → TeamDelete
```

---

## Phase Selection Strategies

### Parallel Phases

If IMPLEMENTATION-PLAN shows phases without dependencies, run them in parallel:

```
Phase 1 (frontend) + Phase 2 (backend) → parallel
Phase 3 (depends on Phase 2) → sequential after Phase 2
```

### Incremental Build

For large plans (7+ phases), build incrementally:

```
Session 1: Phase 1 + 2 (foundation)
Session 2: Phase 3 + 4 (features)  — use CONTINUATION-PROMPT Stage 2
Session 3: Phase 5 + 6 (advanced)  — use CONTINUATION-PROMPT Stage 3
Session 4: Phase 7 (UI polish)     — use CONTINUATION-PROMPT Stage 5
```

### Single-Phase Focus

For quick iterations:

```
/build research/reports/{dir} --phase 1
```

Only implement Phase 1 tasks.

---

## Anti-Patterns

| Anti-Pattern                      | Why Bad                          | Do Instead                                 |
| --------------------------------- | -------------------------------- | ------------------------------------------ |
| Building without reading research | Missing context, wrong patterns  | ALWAYS read 00-SUMMARY + relevant reports  |
| Skipping ADRs                     | Contradicting research decisions | Follow ADRs from 00-SUMMARY                |
| All phases at once                | Context overflow, slow           | 2-3 phases per session                     |
| Not verifying after each phase    | Cascade failures                 | Type-check + test after each phase         |
| Frontend before backend types     | Missing types                    | Backend stores → generate → frontend hooks |
