---
description: Orchestrator — takes any task, builds a pipeline from /research + /write-doc + /team-up, executes autonomously. You describe what you need — it figures out how.
argument-hint: '[any task description in natural language]'
---

# /do — Autonomous Task Orchestrator

**The meta-command that chains everything together.**

You describe WHAT you need. The orchestrator figures out HOW — which commands to use, in what order, and executes the full pipeline autonomously.

Examples:

- `/do спроектируй webhooks v2 и напиши RFC`
- `/do разберись что происходит с auth chain и сделай отчёт`
- `/do добавь SCIM provisioning — исследуй, спланируй, реализуй`
- `/do сравни наш queue с n8n и trigger.dev, напиши report`
- `/do какой статус по SSO? что сделано, что осталось?`
- `/do проведи ревью текущей ветки`

---

## Workflow

### Phase 1: UNDERSTAND — What Does the User Want?

Parse `$ARGUMENTS` and classify the task into one or more categories:

| Category          | Signals in Request                                         | Pipeline                                    |
| ----------------- | ---------------------------------------------------------- | ------------------------------------------- |
| **research**      | "разберись", "изучи", "что есть", "какой статус", "сравни" | RESEARCH → REPORT                           |
| **documentation** | "напиши RFC", "сделай guide", "доку", "report", "ADR"      | RESEARCH → WRITE-DOC                        |
| **feature**       | "добавь", "реализуй", "implement", "создай фичу"           | RESEARCH → PLAN → TEAM-UP → TEST → DOC      |
| **review**        | "ревью", "review", "проверь код", "аудит"                  | TEAM-UP (review squad) → REPORT             |
| **bug**           | "баг", "bug", "не работает", "сломалось", "investigate"    | RESEARCH → TEAM-UP (bug hunt) → FIX         |
| **refactor**      | "рефакторинг", "refactor", "переделай", "migrate"          | RESEARCH → PLAN → TEAM-UP (refactor) → TEST |
| **analysis**      | "анализ", "analyze", "gap analysis", "state of"            | RESEARCH → WRITE-DOC (report)               |
| **status**        | "статус", "status", "что сделано", "прогресс"              | RESEARCH (lightweight) → REPORT             |

**Multiple categories are possible!** Example:

- "спроектируй webhooks и напиши RFC" = **research** + **documentation**
- "добавь SCIM и задокументируй" = **feature** + **documentation**

### Phase 2: RECALL — Check What We Already Know

```
memory_recall("$TOPIC")
memory_recall("$TOPIC architecture decisions")
```

This often reveals that research was already done — skip directly to the next phase.

### Phase 3: PLAN — Build the Pipeline

Based on classification, construct a pipeline of steps.

**IMPORTANT**: Present the pipeline to the user BEFORE executing:

```
## Task: $ARGUMENTS

I've classified this as: [$CATEGORIES]

### Proposed Pipeline:

Step 1: RESEARCH — 5-agent deep search across codebase, RFCs, TODOs, sources, memory
   → Output: Research Report

Step 2: WRITE-DOC (RFC) — Write RFC based on research findings
   → Output: RFC-XXX-WEBHOOKS-V2.md

Step 3: SAVE — File + Memory + RFC-INDEX update
   → Output: Saved to disk + Hindsight

Estimated agents: 7 (5 research + 2 doc)
Approval checkpoints: After research, after draft

Proceed? (yes / adjust pipeline / skip steps)
```

Wait for user to approve the pipeline. User can:

- **"yes"** / **"давай"** → execute all steps
- **"skip research"** → jump to step 2
- **"only research"** → stop after step 1
- Adjust any step

### Phase 4: EXECUTE — Run the Pipeline

Execute each step sequentially. Between steps, use the OUTPUT of the previous step as INPUT for the next.

---

## Pipeline Templates

### Template A: RESEARCH → REPORT (Pure Research)

**For**: "разберись", "изучи", "какой статус", "сравни"

```
Step 1: RESEARCH
  → TeamCreate "research-{topic}" with 5 agents:
    1. code-researcher — packages, services, webapp, tests
    2. rfc-researcher — RFCs, guides, known issues
    3. todo-researcher — TODO files, project status
    4. reference-researcher — sources/, Context7
    5. knowledge-researcher — MCP Memory, research/
  → Output: 5 agent reports

Step 2: SYNTHESIZE
  → Leader combines all 5 reports
  → Cross-references findings
  → Identifies gaps and conflicts

Step 3: DELIVER
  → Present Research Report to user
  → memory_retain() key findings

Step 4: CLEANUP
  → Shutdown team, TeamDelete
```

### Template B: RESEARCH → WRITE-DOC (Research + Documentation)

**For**: "напиши RFC", "сделай guide", "report"

```
Step 1: RESEARCH (same as Template A)
  → Output: Research Report with full context

Step 2: WRITE-DOC
  → Determine doc type (RFC/guide/report/ADR)
  → Determine file path and next RFC number
  → Write document using research findings as input
  → Follow template for the doc type

Step 3: APPROVAL CHECKPOINT
  → Present draft to user
  → Wait for: approve / edit / reject

Step 4: SAVE (only after approval)
  → Write file to disk
  → memory_retain() summary
  → Update RFC-INDEX.md (if RFC)
  → Update relevant TODO (if applicable)

Step 5: CLEANUP
```

### Template C: RESEARCH → PLAN → TEAM-UP (Feature Implementation)

**For**: "добавь", "реализуй", "implement"

```
Step 1: RESEARCH (same as Template A, but focused on implementation context)
  → What exists, what's needed, reference patterns

Step 2: PLAN
  → Based on research, create implementation plan
  → File ownership map
  → Task breakdown (5-6 per teammate)
  → Dependencies between teammates

Step 3: APPROVAL CHECKPOINT
  → Present plan to user
  → Wait for approval

Step 4: TEAM-UP
  → TeamCreate with implementation teammates
  → Backend-dev, frontend-dev, test-writer, etc.
  → Each gets research context + their task list
  → Plan approval for risky changes

Step 5: VERIFY
  → Type check: pnpm -r exec tsc --noEmit
  → Tests: pnpm --filter @gerts/[pkg] test
  → Build: pnpm --filter @gerts/[pkg] build

Step 6: DOC (optional, if task included documentation)
  → Update TODO files with [x] completed items
  → memory_retain() implementation decisions

Step 7: CLEANUP
```

### Template D: TEAM-UP REVIEW (Code Review)

**For**: "ревью", "review", "аудит"

```
Step 1: SCOPE
  → Determine what to review (current branch diff, specific files, PR)
  → git diff main...HEAD for branch changes

Step 2: TEAM-UP (Review Squad)
  → TeamCreate with 3 reviewers:
    1. security-reviewer — auth, injection, IDOR, tenant isolation
    2. perf-reviewer — N+1, indexes, memory, query patterns
    3. test-reviewer — coverage, edge cases, missing tests

Step 3: SYNTHESIZE
  → Combine all review findings
  → Prioritize: Critical > High > Medium > Low

Step 4: DELIVER
  → Present review report
  → memory_retain() key issues found

Step 5: CLEANUP
```

### Template E: RESEARCH → BUG HUNT (Bug Investigation)

**For**: "баг", "не работает", "investigate"

```
Step 1: RESEARCH (focused on the bug area)
  → Check memory for known issues
  → Check KNOWN-ISSUES.md
  → Understand the architecture around the bug

Step 2: TEAM-UP (Bug Hunt)
  → TeamCreate with hypothesis teams:
    1. hypothesis-auth — auth chain issue
    2. hypothesis-data — data integrity
    3. hypothesis-config — config/env mismatch
    4. hypothesis-timing — race condition

Step 3: SYNTHESIZE
  → Which hypothesis is confirmed?
  → Root cause identified?

Step 4: FIX (if simple enough)
  → Apply fix
  → Add test
  → Verify

Step 5: DOCUMENT
  → Update KNOWN-ISSUES.md
  → memory_retain() root cause + fix

Step 6: CLEANUP
```

### Template F: LIGHTWEIGHT STATUS CHECK

**For**: "статус", "что сделано", "прогресс"

**NO team needed** — use parallel sub-agents:

```
Step 1: PARALLEL SEARCH (3 sub-agents, not a team)
  → Task(Explore): Search TODO files for topic
  → Task(Explore): Search codebase for topic
  → Task(Explore): memory_recall for topic

Step 2: SYNTHESIZE
  → Combine into status report

Step 3: DELIVER
  → Present status to user
```

---

## Decision Logic (How to Pick Template)

```
1. Parse $ARGUMENTS for category signals (see table in Phase 1)
2. Check if multiple categories apply

3. Select template:
   - Only research signals → Template A
   - Research + doc signals → Template B
   - Feature signals → Template C
   - Review signals → Template D
   - Bug signals → Template E
   - Status signals → Template F
   - Feature + doc → Template C, then add doc step from Template B
   - Research + feature → Template A, then Template C with research output

4. If unclear, ask user:
   "I see you want [X]. Should I:
   a) Just research and report?
   b) Research, then write a doc?
   c) Research, plan, and implement?
   d) Something else?"
```

---

## Approval Checkpoints

The orchestrator runs autonomously BUT pauses at key checkpoints:

| Checkpoint              | When                     | What User Sees                       |
| ----------------------- | ------------------------ | ------------------------------------ |
| **Pipeline approval**   | After Phase 3 (PLAN)     | Proposed pipeline + estimated agents |
| **Research review**     | After research completes | Summary of findings, proceed?        |
| **Draft review**        | After doc/RFC is written | Full document, approve/edit/reject?  |
| **Implementation plan** | Before spawning dev team | File ownership, task breakdown       |
| **Final review**        | After implementation     | Diff summary, tests passing?         |

**User can say at any checkpoint:**

- **"давай"** / **"yes"** → continue
- **"стоп"** → abort
- **"пропусти"** → skip this step
- **"измени [X]"** → adjust and retry

---

## Context Passing Between Steps

Each step's output feeds into the next step's input:

```
RESEARCH output (5 reports)
    ↓ passed as context to
WRITE-DOC (uses findings for content)
    ↓ passed as context to
TEAM-UP (teammates get research + doc as requirements)
    ↓ results saved to
MEMORY (memory_retain with synthesis)
```

**How to pass context:**

- Research report → include as literal text in next step's prompt
- Keep it concise — extract key points, not raw data
- Each step summarizes for the next (avoids context overflow)

---

## Error Handling

| Situation                  | Action                                                 |
| -------------------------- | ------------------------------------------------------ |
| Team agent fails           | Retry once, if still fails → report partial results    |
| Research finds nothing     | Report "no results", ask user for more keywords        |
| Doc draft rejected         | Ask for specific feedback, rewrite                     |
| Implementation fails tests | Report test failures, attempt fix, if stuck → ask user |
| Pipeline takes too long    | Report progress after each step, user can abort        |
| Memory save fails          | Report error, continue with pipeline                   |

---

## Integration with Existing Commands

The orchestrator delegates to the actual command logic:

| Step      | Delegates To            | How                              |
| --------- | ----------------------- | -------------------------------- |
| RESEARCH  | `/research` logic       | 5-agent team, same prompts       |
| WRITE-DOC | `/write-doc` logic      | 2-agent team, same templates     |
| TEAM-UP   | `/team-up` logic        | Recipe-based team, same patterns |
| REVIEW    | `/team-up` Review Squad | 3-reviewer team                  |
| MEMORY    | `memory_retain()`       | Direct MCP call                  |

The orchestrator **chains** these, not replaces them. Each step follows the same workflow defined in its command.

---

## Examples

### Example 1: "спроектируй webhooks v2 и напиши RFC"

```
Category: research + documentation
Template: B (RESEARCH → WRITE-DOC)
Pipeline:
  1. RESEARCH (5 agents) → webhook patterns, our code, n8n/trigger.dev reference
  2. WRITE-DOC (RFC) → RFC-XXX-WEBHOOKS-V2.md
  3. SAVE → file + memory + RFC-INDEX
Checkpoints: after research, after draft
```

### Example 2: "какой статус по SSO SAML?"

```
Category: status
Template: F (LIGHTWEIGHT)
Pipeline:
  1. 3 parallel sub-agents → TODO + code + memory
  2. Synthesize → status report
No team needed, fast.
```

### Example 3: "добавь SCIM provisioning — полный цикл"

```
Category: feature + documentation
Template: C + B hybrid
Pipeline:
  1. RESEARCH → SCIM standards, our IAM, reference (zitadel)
  2. PLAN → implementation plan, file ownership
  3. TEAM-UP → backend-dev + test-writer
  4. WRITE-DOC (guide) → SCIM-INTEGRATION-GUIDE.md
  5. SAVE → files + memory + TODO updates
Checkpoints: after research, after plan, after implementation, after doc
```

### Example 4: "проведи security ревью текущей ветки"

```
Category: review
Template: D (REVIEW)
Pipeline:
  1. SCOPE → git diff main...HEAD
  2. TEAM-UP → 3 reviewers (security + perf + tests)
  3. SYNTHESIZE → prioritized findings
  4. SAVE → memory + KNOWN-ISSUES if bugs found
```

---

## Tips

1. **Start specific** — "спроектируй webhooks для real-time event delivery с retry и DLQ" works better than "сделай webhooks"
2. **Say what you want at the end** — "и напиши RFC" tells the orchestrator to include doc step
3. **You can interrupt** — at any checkpoint, adjust the pipeline
4. **Pipeline is visible** — you always see what's planned before execution starts
5. **Memory accumulates** — each `/do` saves findings, so the next `/do` on similar topic is faster
6. **Lightweight by default** — status checks don't spawn full teams
