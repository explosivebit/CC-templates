---
description: Orchestrate multi-agent teams for complex tasks — parallelize work, split tasks among agents, coordinate teammates
argument-hint: '[task description]'
---

# Agent Teams — Orchestration Skill for gerts.ai

**Trigger**: User asks to create an agent team, parallelize work, split tasks among agents, or says `/team-up`

---

## Prerequisites

Agent Teams enabled in `.claude/settings.json`:

```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

---

## Execution Mode Selection (MANDATORY FIRST STEP)

**BEFORE anything else**, determine which execution mode to use:

### Mode A: Agent Teams (PREFERRED — TeamCreate/TeamDelete)

**Use when**: `TeamCreate` and `TeamDelete` tools are available (check via ToolSearch if unsure).

```
1. TeamCreate(team_name="sprint-{rfc}-{feature}")  → creates a team
2. Agent(prompt="...", team_name="sprint-...", name="team-lead")  → spawns team lead
3. Team lead spawns teammates via Agent(team_name="sprint-...")
4. Team lead coordinates, synthesizes, reports
5. TeamDelete()  → cleanup after all work done
```

**Team Lead responsibilities:**

- Coordinates all teammates
- Owns the synthesis and final report
- Does NOT implement code itself (delegate mode)
- Monitors progress, resolves conflicts
- Updates RFC progress bars, TODO files, memory

**Teammates** are real agents in the team (NOT sub-agents), with:

- Full tool access
- Shared team context
- Addressable via SendMessage
- Independent execution with file ownership

### Mode B: Sub-Agents Fallback (ONLY when Agent Teams unavailable)

**Use when**: `TeamCreate` tool is NOT available or returns errors.

```
1. Agent(prompt="...", name="agent-a", run_in_background=true)  → parallel sub-agents
2. Agent(prompt="...", name="agent-b", run_in_background=true)
3. Wait for all to complete
4. Synthesize results in main context
```

**Key difference**: No team lead, no shared context, no SendMessage between agents.
Agents are isolated — each gets full context in their prompt.

### How to detect mode:

```typescript
// Try TeamCreate — if available, use Mode A
ToolSearch({ query: 'select:TeamCreate' });
// If returned → Mode A (Agent Teams)
// If not found or error → Mode B (Sub-Agents fallback)
```

**RULE**: NEVER use Mode B sub-agents when TeamCreate is available. Agent Teams provide better coordination, shared context, and team lead oversight.

---

## Workflow (5 Steps)

### Step 1: RECALL & STUDY — Check Memory, TODOs, Source Code

**BEFORE creating any team**, the leader MUST gather context from 3 sources:

#### 1a. Memory (Hindsight MCP)

```
memory_recall("topic relevant to the task")
memory_recall("architectural decisions for [module]")
```

Check for: past decisions, known bugs, user preferences, patterns.

#### 1b. TODO Files — Project Chronology (CRITICAL!)

Each project has its own TODO — a **chronological log** of all work done and remaining:

| Project      | Path                           | Size        |
| ------------ | ------------------------------ | ----------- |
| **Webapp**   | `apps/webapp/docs/dev/TODO.md` | ~1500 lines |
| **Pipeline** | `apps/pipeline/docs/TODO.md`   | ~5300 lines |
| **Landing**  | `apps/landing/docs/TODO.md`    | New         |

**TODO files are LARGE — read carefully with offset/limit:**

```
Read("apps/webapp/docs/dev/TODO.md", limit=100)          # Header + status
Read("apps/webapp/docs/dev/TODO.md", offset=100, limit=200)  # Phase details
Read("apps/pipeline/docs/TODO.md", limit=100)             # Header + status
```

**How to use TODOs:**

- **Before work**: Study what was already done (checkboxes `[x]`) and what remains (`[ ]`)
- **Cross-reference**: Compare TODO entries with `memory_recall()` and actual source code
- **After work**: Log completed work as `[x]` entries with dates and file lists
- **Gaps section**: Each TODO has "Gaps" subsections — these are the NEXT things to do
- **Backend endpoints needed**: TODO lists which endpoints frontend needs but backend doesn't have yet

**Use sub-tasks for reading large TODOs:**

```
Task({
  description: "Study webapp TODO",
  prompt: "Read apps/webapp/docs/dev/TODO.md in chunks (1000 lines each).
    Extract: 1) Current status, 2) Remaining tasks ([ ]), 3) Backend gaps,
    4) Patterns used. Return structured summary.",
  subagent_type: "Explore"
})
```

#### 1c. Source Code — THE ULTIMATE SOURCE OF TRUTH

**If TODO, Memory, and source code don't align — source code WINS. Always.**

TODO can be outdated. Memory can be stale. Source code is what actually runs.

**Verification pattern (triangulation):**

```
1. TODO says [x] "useCreateUser hook done"
2. memory_recall("useCreateUser") confirms
3. Grep("useCreateUser", "apps/webapp/src/") → VERIFY it actually exists

If step 3 fails → TODO is wrong. Trust the code. Fix the TODO.
```

**Quick verification commands:**

```
Glob("apps/webapp/src/app/(dashboard)/**/*.tsx")   # What pages actually exist
Grep("useCreateUser", "apps/webapp/src/")          # Does this hook exist?
Grep("export function|export const", "apps/pipeline/src/services/admin/src/actions/")  # What actions exist
Grep("TODO|FIXME|HACK", "apps/pipeline/src/services/")  # Inline todos in code
Grep("throw new APIError", "apps/pipeline/src/services/admin/")  # Error patterns used
```

**When things don't match:**

- TODO says done but code missing → **re-implement** (previous work may have been lost)
- TODO says not done but code exists → **update TODO** (someone did it without logging)
- Memory says X but code does Y → **trust code**, update memory with `memory_retain()`
- Always check `git log --oneline -20` for recent changes that may not be in TODO yet

### Step 2: CLASSIFY — Choose Team Recipe

| Recipe                | When                                  | Teammates                        | Token Cost |
| --------------------- | ------------------------------------- | -------------------------------- | ---------- |
| **Review Squad**      | PR review, code audit, security check | 3 (security + perf + tests)      | Medium     |
| **Feature Build**     | New module/feature across layers      | 2-4 (backend + frontend + tests) | High       |
| **Bug Hunt**          | Competing hypotheses, flaky bug       | 3-5 (each tests a theory)        | Medium     |
| **Research**          | RFC analysis, architecture decisions  | 2-3 (each explores an angle)     | Low        |
| **Full-Stack Sprint** | End-to-end feature (DB → API → UI)    | 3 (schema + API + frontend)      | High       |
| **Refactor Wave**     | Large refactor across packages        | 2-4 (each owns a package)        | High       |

### Step 3: RESEARCH — Gather Context for Teammates

**Leader gathers context BEFORE spawning**. Use these sources in order:

#### 3a. TODO Files — What's Done, What's Left

```
# Use sub-tasks for large files!
Task({ description: "Read pipeline TODO", subagent_type: "Explore",
  prompt: "Read apps/pipeline/docs/TODO.md in chunks. Find sections about [topic]. Return: done items, remaining items, gaps, backend endpoints needed." })

Task({ description: "Read webapp TODO", subagent_type: "Explore",
  prompt: "Read apps/webapp/docs/dev/TODO.md in chunks. Find sections about [topic]. Return: done items, remaining items, gaps, patterns used." })
```

**Key TODO sections to look for:**

- `### Phase N:` — chronological phases of work
- `#### Done` / `[x]` — completed items (study patterns used)
- `#### Gaps` / `[ ]` — remaining work (these are your tasks!)
- `**Backend endpoints needed:**` — table of missing API endpoints
- `**Files Modified:**` / `**New files:**` — what was changed/created

#### 3b. RFCs & Docs (64 RFCs + 30 guides)

```
Read("apps/pipeline/docs/RFC-INDEX.md")           # RFC index — start here
Read("apps/pipeline/docs/RFC-0XX-[topic].md")     # Specific RFC
Read("apps/pipeline/docs/guides/[guide].md")       # Implementation guide
Read("apps/pipeline/docs/fixes/KNOWN-ISSUES.md")  # Known bugs
```

**Key RFCs by domain:**
| Domain | RFCs |
|--------|------|
| Auth/IAM | RFC-039, RFC-050, RFC-077 |
| Queue/Jobs | RFC-032, RFC-044 |
| Graph/RAG | RFC-031, RFC-036, RFC-040, RFC-041, RFC-043 |
| API/SDK | RFC-029, RFC-030, RFC-075 |
| Connectors | RFC-042, RFC-076 |
| Realtime | RFC-028 |
| Design System | RFC-063 |
| Security | RFC-052, RFC-055 |

**Key Guides:**
| Guide | Path |
|-------|------|
| Moleculer patterns | `docs/guides/PIPELINE-MOLECULER-USAGE-AI.md` |
| Error handling | `docs/guides/ERROR-HANDLING-PATTERNS.md` |
| Auth flow | `docs/guides/AUTH-FLOW-GUIDE.md` |
| Vault/HSM | `docs/guides/VAULT-HSM-OPERATIONS-GUIDE.md` |
| MCP integration | `docs/guides/MCP.md` |
| Scheduler API | `docs/guides/SCHEDULER-API-REFERENCE.md` |

#### 3b. Sources — Reference Implementations (50 projects)

```
Read("research/SOURCES-REFERENCE.md")  # Full guide to all sources
```

**Sources by domain (pick relevant ones for teammates):**
| Need | Source | Path |
|------|--------|------|
| Job Queue | n8n | `sources/n8n/packages/cli/src/scaling/` |
| Event Sourcing, CQRS | zitadel | `sources/zitadel/internal/eventstore/` |
| Graph RAG | graphiti, graphrag | `sources/graphiti/`, `sources/graphrag/` |
| Agent Memory | hindsight | `sources/hindsight/` |
| Fine-grained Auth | openfga | `sources/openfga/` |
| Data Pipelines | dagster | `sources/dagster/` |
| Multi-Agent | crewAI, agno | `sources/crewAI/`, `sources/agno/` |
| Auth/OIDC | logto, zitadel | `sources/logto/`, `sources/zitadel/` |
| Observability | langfuse | `sources/langfuse/` |
| Document Ingestion | ragflow, onyx | `sources/ragflow/`, `sources/onyx/` |
| Realtime/Events | trigger.dev | `sources/trigger.dev/` |
| Microservices | moleculer | `sources/moleculer/` |
| LLM Proxy | litellm | `sources/litellm/` |
| Workflow Engine | pyspur, orchestra | `sources/pyspur/`, `sources/orchestra/` |
| Connectors | airbyte, rudder | `sources/airbyte/`, `sources/rudder-server/` |

#### 3c. Research — Deep Analysis

```
Read("research/00-MASTER-PLAN.md")                 # Master plan
Read("research/projects/[name]/")                  # Per-project analysis
Read("research/architecture/")                     # Architecture research
Read("research/reports/")                          # Analysis reports
```

**Per-project research** (in `research/projects/`):
| Project | What We Studied |
|---------|----------------|
| adk-js | Google Agent Dev Kit JS integration |
| agno | Multi-agent framework |
| crewAI | Crews + Flows pattern |
| jan | Local AI assistant patterns |
| litellm | LLM proxy architecture |
| onyx | Document search/ingestion |
| trigger-dev | Background jobs, realtime events |
| trustgraph | Knowledge graph patterns |
| queue, queue2 | BullMQ patterns deep-dive |

#### 3d. Packages — Internal Libraries (40+ packages)

```
Read("packages/[name]/README.md")     # Package documentation
Read("packages/[name]/src/index.ts")  # Public API
```

**Decision tree — "I need to...":**
| Need | Package | Tests |
|------|---------|-------|
| Background jobs, retries, DLQ | `@gerts/queue` | 979 |
| Saga/distributed transactions | `@gerts/queue` (SagaOrchestrator) | — |
| Streaming (SSE, WebSocket) | `@gerts/queue` + `@gerts/flux` | — |
| Event collections with TTL | `@gerts/flux` | 200+ |
| Database/Prisma | `@gerts/database` | 1446 |
| Event Sourcing/Projections | `@gerts/database` (EventStore) | — |
| Graph RAG, ontology | `@gerts/graph` | 500+ |
| Session, tenant config | `@gerts/core` | 300+ |
| LLM/Embedding providers | `@gerts/providers` | — |
| Vector DB (Milvus, Qdrant) | `@gerts/vectordb` | — |
| Document ingestion | `@gerts/ingest` | — |
| Rate limiting | `@gerts/api-rlr` | — |
| Fine-grained auth (ReBAC) | `@gerts/auth-openfga` | — |
| API controller pattern | `@gerts/api-core` | — |
| HSM/Encryption (Vault/KMS) | `@gerts/hsm` | 25+ |
| High-perf collections | `@gerts/collection` | 150+ |

#### 3e. Context7 — Library Documentation (MCP)

**Instead of web browsing**, use Context7 for library docs:

```
mcp__context7__resolve-library-id({ libraryName: "react", query: "useEffect cleanup" })
mcp__context7__query-docs({ libraryId: "/vercel/next.js", query: "server actions" })
```

**Common libraries to look up:**
| Library | Context7 ID | When |
|---------|-------------|------|
| Next.js | `/vercel/next.js` | Frontend routing, SSR |
| React | `/facebook/react` | Hooks, patterns |
| TanStack Query | `/tanstack/query` | Data fetching |
| Prisma | `/prisma/prisma` | Database ORM |
| Zustand | `/pmndrs/zustand` | Client state |
| Tailwind CSS | `/tailwindlabs/tailwindcss` | Styling |
| Radix UI | `/radix-ui/primitives` | UI primitives |
| Vitest | `/vitest-dev/vitest` | Testing |

#### 3f. Memory — Hindsight MCP

**Every teammate should use memory tools:**

```
memory_recall("topic")      # Before starting — recall past decisions
memory_retain("content")    # After finishing — save learnings
memory_reflect("query")     # During work — synthesize patterns
```

**What to recall:**

- `"auth architecture decisions"` — before touching auth
- `"frontend patterns gerts"` — before building UI
- `"known bugs [module]"` — before debugging
- `"openapi codegen"` — before API work
- `"session consolidation"` — before session work

### Step 4: SPAWN — Create Team (Mode A) or Launch Agents (Mode B)

#### Mode A: Agent Teams (PREFERRED)

```typescript
// 1. Create team
TeamCreate((team_name = 'sprint-rfc128-autonomy'));

// 2. Spawn team lead (does NOT implement — only coordinates)
Agent({
  prompt: 'You are the Team Lead for sprint-rfc128-autonomy. ...',
  team_name: 'sprint-rfc128-autonomy',
  name: 'team-lead',
  mode: 'plan', // requires plan approval
});

// 3. Team lead spawns teammates (from within team lead's context):
Agent({
  prompt: 'You are backend-dev. Your files: ...',
  team_name: 'sprint-rfc128-autonomy',
  name: 'backend-dev',
  mode: 'bypassPermissions',
});

// 4. Team lead monitors via SendMessage:
SendMessage({ to: 'backend-dev', message: 'Status update?' });

// 5. After all work done:
TeamDelete();
```

#### Mode B: Sub-Agents Fallback (when TeamCreate unavailable)

```typescript
// Launch parallel sub-agents directly
Agent({ prompt: '...', name: 'agent-a', run_in_background: true, mode: 'bypassPermissions' });
Agent({ prompt: '...', name: 'agent-b', run_in_background: true, mode: 'bypassPermissions' });
// Wait for notifications, then synthesize
```

**Include in EVERY teammate spawn prompt (both modes):**

```
Project ecosystem (USE these resources — this is MANDATORY):

=== CONTEXT SOURCES (study BEFORE implementing) ===

1. MEMORY: Start with memory_recall("[your topic]") to check past decisions
2. TODO FILES (large — read with offset/limit or use sub-tasks):
   - Pipeline: apps/pipeline/docs/TODO.md (~5300 lines)
   - Webapp:   apps/webapp/docs/dev/TODO.md (~1500 lines)
   - Landing:  apps/landing/docs/TODO.md
   Study: [x] = done items (learn patterns), [ ] = remaining (your tasks)
   Compare TODO entries with memory_recall() and actual source code
3. RFCs: Read relevant RFC from apps/pipeline/docs/RFC-*.md
   - Index: apps/pipeline/docs/RFC-INDEX.md
4. GUIDES: Implementation guides in apps/pipeline/docs/guides/
5. SOURCES: Reference implementations in sources/ (50 projects)
   - Index: research/SOURCES-REFERENCE.md
   - Per-project analysis: research/projects/[name]/
6. PACKAGES: Internal libraries in packages/ — check README.md before reimplementing
   - Check if @gerts/[pkg] already solves your need
7. RESEARCH: Deep analysis in research/ and research/projects/
   - Architecture: research/architecture/
   - Reports: research/reports/
   - Cross-analysis: research/cross-analysis/
8. CONTEXT7 (for library docs — NOT web browsing!):
   Use mcp__context7__resolve-library-id then mcp__context7__query-docs
9. KNOWN ISSUES: apps/pipeline/docs/fixes/KNOWN-ISSUES.md
10. AGENTS: .claude/agents/ — 26 specialized agents available
11. SKILLS: Activate relevant skills (Skill("typescript-pro"), etc.)

=== LOGGING RESULTS ===

After completing work, LOG results:
- Update relevant TODO.md with [x] completed items
- Add new [ ] items for discovered gaps
- Include: date, file list, patterns used
- Format: ### Phase N.X: Feature Name (YYYY-MM-DD)

=== PROJECT RULES (MUST follow) ===

1. Use APIError with ResponseCode — NEVER generic throw new Error()
2. Use getTenantIdStrict(ctx) for auth — NEVER getTenantId(ctx)
3. API data in TanStack Query — NEVER in Zustand
4. After modifying packages/*, rebuild: pnpm --filter @gerts/[pkg] build
5. Follow FSD layers: shared → entities → features → views → widgets → app
6. Events go through eventstore.pushWithJobs() for audit trail
7. Zustand: NEVER use getters in state (use selector functions)
8. OIDC endpoints at root: /oauth2/* (NOT /api/v1/oauth2/*)
9. REST API: /v1/* (NO /api prefix — added at k8s ingress)
10. X-Tenant-ID: default header required for OIDC endpoints
```

### Step 5: MONITOR → SYNTHESIZE → RETAIN

After team completes:

1. **Synthesize** — combine findings from all teammates
2. **Retain** — save key learnings to memory:
   ```
   memory_retain("# [Topic] — Team findings\n[key decisions]\n[patterns discovered]")
   ```
3. **Update TODO files** — this is MANDATORY:
   - Mark completed items as `[x]` with date
   - Add new `[ ]` items for discovered gaps
   - Add `**Files Modified:**` and `**New files:**` tables
   - Format new sections as: `### Phase N.X: Feature Name (YYYY-MM-DD)`
   - Which TODO to update:
     - Backend work → `apps/pipeline/docs/TODO.md`
     - Frontend work → `apps/webapp/docs/dev/TODO.md`
     - Landing work → `apps/landing/docs/TODO.md`
   - Use sub-tasks for large TODO updates:
     ```
     Task({ description: "Update webapp TODO",
       prompt: "Read apps/webapp/docs/dev/TODO.md, find the section about [topic],
         mark [x] completed items, add new [ ] gaps, add Files Modified table.
         Read file with offset/limit — it's ~1500 lines.",
       subagent_type: "general-purpose" })
     ```
4. **Log issues** — new bugs → `docs/fixes/KNOWN-ISSUES.md`
5. **Cleanup** — shutdown teammates → TeamDelete

---

## Team Recipes

### Recipe 1: Review Squad

**Use when**: PR review, code audit, security check

```
Create an agent team called "review-squad" to review the changes in [scope].

Spawn 3 teammates:
1. "security-reviewer" — Focus on auth vulnerabilities, injection, IDOR,
   tenant isolation. Check every endpoint uses getTenantIdStrict(ctx).
   Read: apps/pipeline/docs/guides/ERROR-HANDLING-PATTERNS.md
   Read: apps/pipeline/docs/fixes/KNOWN-ISSUES.md
   Check sources/zitadel and sources/logto for auth patterns.
   Report findings with severity (Critical/High/Medium/Low).

2. "perf-reviewer" — Focus on N+1 queries, missing indexes,
   unbounded queries, memory leaks. Check Prisma includes and query patterns.
   Read: packages/database/README.md for our Prisma patterns.
   Study sources/langfuse for observability patterns.
   Report with estimated impact.

3. "test-reviewer" — Validate test coverage for new code. Check edge cases,
   error paths, missing mocks. Study our existing test patterns:
   Read: packages/auth-prisma/src/oidc-stores.test.ts (159 tests, good patterns)
   Read: packages/queue/ (979 tests, saga/DLQ patterns)
   Report gaps with suggested test cases.

Have them review independently, then share findings with each other
to cross-validate. Synthesize a final report.
```

---

### Recipe 2: Feature Build (Full-Stack)

**Use when**: New feature spanning backend + frontend + tests

```
Create an agent team called "feature-[name]" to implement [feature].

FIRST: Read RFC-XXX for requirements. Check memory_recall("[feature topic]").

Spawn 3 teammates:
1. "backend-dev" — Implement the backend:
   - Read relevant RFC and guide FIRST
   - Study similar service in apps/pipeline/src/services/ for patterns
   - Study relevant source (n8n/zitadel/logto) for reference
   - Moleculer action in apps/pipeline/src/services/[service]/
   - Types in [service]/types.ts
   - Use Context7 for any library questions (NOT web browser)
   - Save architectural decisions with memory_retain()
   Files: apps/pipeline/src/services/**, packages/**

2. "frontend-dev" — Implement the frontend:
   - Read apps/webapp/docs/dev/tasks/TODO.md for current state
   - Read apps/webapp/docs/dev/FRONTEND-PATTERNS.md for conventions
   - Study existing pages for patterns (e.g., iam/users/[id]/page.tsx)
   - Use Context7 for React/Next.js/TanStack Query questions
   - Use existing DS components (DataTable, StatusBadge, EmptyState)
   Files: apps/webapp/src/**

3. "test-writer" — Write tests for both layers:
   - Study test patterns: packages/auth-prisma/src/*.test.ts
   - Mock Prisma $transaction by passing same mock objects as callback arg
   - Use Vitest patterns from packages/queue/src/*.test.ts
   - Use Context7 for Vitest questions
   Files: **/*.test.ts, **/*.test.tsx

Require plan approval for backend-dev before implementation.
Wait for backend-dev to finish before frontend-dev starts API integration.
```

---

### Recipe 3: Bug Hunt (Competing Hypotheses)

**Use when**: Hard-to-reproduce bug, unclear root cause

```
Create an agent team called "bug-hunt-[issue]" to investigate [bug description].

ALL teammates: Start with memory_recall("[bug topic]") and check KNOWN-ISSUES.md

Spawn 4 teammates, each investigating a different hypothesis:
1. "hypothesis-auth" — Theory: auth chain issue.
   Read: apps/pipeline/docs/guides/AUTH-FLOW-GUIDE.md
   Study: sources/logto, sources/zitadel for auth patterns
   Trace: api.service.ts → middleware → action

2. "hypothesis-data" — Theory: data integrity issue.
   Read: packages/database/README.md, packages/auth-prisma/src/
   Check Prisma queries, transaction boundaries, event ordering.

3. "hypothesis-config" — Theory: environment/config mismatch.
   Read: apps/pipeline/.env.example, moleculer.config.ts
   Check: SERVICES env var, service lifecycle

4. "hypothesis-timing" — Theory: race condition.
   Study: packages/queue/ (BullMQ patterns), packages/flux/ (event streams)
   Check: async flows, event handlers, projection ordering

Have them actively DISPROVE each other's theories.
Save findings with memory_retain().
```

---

### Recipe 4: Research & Architecture

**Use when**: RFC analysis, technology decisions, gap analysis

```
Create an agent team called "research-[topic]" to analyze [topic].

Spawn 3 teammates:
1. "codebase-analyst" — Study our current implementation:
   - memory_recall("[topic] architecture decisions")
   - Read relevant packages/ (check README.md first)
   - Read relevant services in apps/pipeline/src/services/
   - Map existing patterns, conventions, gaps
   - Use Grep to find usage patterns across codebase

2. "reference-analyst" — Study reference implementations:
   - Read research/SOURCES-REFERENCE.md for index
   - Read research/projects/[relevant]/ for our past analysis
   - Read sources/[relevant]/ for actual code
   - Study: research/architecture/, research/reports/
   - Use Context7 for library documentation
   - Extract patterns, compare approaches

3. "architect" — Synthesize findings into a design:
   - Receive reports from both analysts
   - Read existing RFCs for context (apps/pipeline/docs/RFC-INDEX.md)
   - Propose architecture aligned with existing patterns
   - Draft RFC in apps/pipeline/docs/RFC-XXX-[topic].md
   - Save decisions with memory_retain()

Require plan approval for architect before writing RFC.
```

---

### Recipe 5: Refactor Wave

**Use when**: Large refactor spanning multiple packages

```
Create an agent team called "refactor-[scope]" to refactor [description].

ALL: Read relevant package README.md, check KNOWN-ISSUES.md

Spawn teammates, one per package/area:
1. "[package-1]-dev" — Own: packages/[pkg1]/src/**
   - Read packages/[pkg1]/README.md first
   - Study test files for expected behavior
2. "[package-2]-dev" — Own: packages/[pkg2]/src/**
3. "integration-tester" — Run cross-package tests after each milestone:
   - pnpm -r exec tsc --noEmit (type check all)
   - pnpm --filter @gerts/[pkg] test (unit tests)
   - Save findings with memory_retain()

Rules:
- Each teammate owns EXACTLY their files — no cross-editing
- After modifying packages/*, MUST rebuild: pnpm --filter @gerts/[pkg] build
```

---

## Module → File Ownership Map

### Backend Services (apps/pipeline/src/services/)

| Service       | Path                              | Related RFC      | Reference Source     |
| ------------- | --------------------------------- | ---------------- | -------------------- |
| Admin (IAM)   | `services/admin/`                 | RFC-039, RFC-050 | zitadel, logto       |
| OIDC (Auth)   | `services/oidc/`                  | RFC-050          | logto, zitadel       |
| IAM Events    | `services/iam/`                   | RFC-050          | zitadel (eventstore) |
| Queue         | `services/queue/`                 | RFC-032          | n8n, trigger.dev     |
| Connectors    | `services/connectors/`            | RFC-042, RFC-076 | airbyte, rudder      |
| Graph         | `services/graph/`                 | RFC-031, RFC-040 | graphiti, graphrag   |
| Webhooks      | `services/webhooks/`              | RFC-028          | n8n                  |
| Files         | `services/files/`                 | RFC-052          | onyx                 |
| LLM/Chat      | `services/llm/`, `services/chat/` | —                | litellm              |
| Ingest        | `services/ingest/`                | RFC-040          | ragflow, onyx        |
| ETL           | `services/etl/`                   | RFC-044          | dagster              |
| Vector        | `services/vector/`                | —                | —                    |
| Scheduler     | `services/scheduler/`             | —                | trigger.dev          |
| Tenant Config | `services/tenant-config/`         | —                | —                    |

### Frontend Modules (apps/webapp/src/)

| Module    | Feature Path                 | Route Path                      | Related Source |
| --------- | ---------------------------- | ------------------------------- | -------------- |
| IAM Users | `features/admin/users/`      | `app/(dashboard)/iam/users/`    | logto, zitadel |
| IAM Roles | `features/admin/roles/`      | `app/(dashboard)/iam/roles/`    | logto          |
| IAM Teams | `features/admin/teams/`      | `app/(dashboard)/iam/teams/`    | —              |
| Sessions  | `features/admin/sessions/`   | `app/(dashboard)/iam/sessions/` | logto          |
| Audit     | `features/admin/audit/`      | `app/(dashboard)/iam/audit/`    | langfuse       |
| Settings  | `features/admin/oauth-apps/` | `app/(dashboard)/settings/`     | —              |
| Knowledge | `features/admin/knowledge/`  | `app/(dashboard)/knowledge/`    | onyx           |
| AI Chat   | `features/admin/ai/`         | `app/(dashboard)/ai/`           | jan            |
| Pipelines | `features/admin/pipelines/`  | `app/(dashboard)/pipelines/`    | trigger.dev    |
| Observe   | —                            | `app/(dashboard)/observe/`      | langfuse       |
| Auth      | `features/auth/`             | `app/(auth)/`                   | logto, zitadel |
| Shared UI | `shared/ui/`, `shared/lib/`  | —                               | —              |

### Packages (40+)

| Category   | Packages                                                      | Rebuild Command                                      |
| ---------- | ------------------------------------------------------------- | ---------------------------------------------------- |
| Foundation | core, database, utils, collection, fetch                      | `pnpm --filter @gerts/[pkg] build`                   |
| Data       | flux, providers, vectordb, memory, ingest, graph              | `pnpm --filter @gerts/[pkg] build`                   |
| Execution  | flow, runtime, scheduler, tools, agent, a2a                   | `pnpm --filter @gerts/[pkg] build`                   |
| API        | api-core, api-client, api-rlr, ws-rpc, mcp-adapter, api-types | `pnpm --filter @gerts/[pkg] build`                   |
| Auth       | auth, auth-prisma, auth-openfga, auth-moleculer               | `pnpm --filter @gerts/[pkg] build`                   |
| Client     | client, client-react, sdk, ui                                 | `pnpm --filter @gerts/[pkg] build`                   |
| Security   | hsm                                                           | `pnpm --filter @gerts/[pkg] build`                   |
| Database   | database                                                      | `pnpm --filter @gerts/database exec prisma generate` |

---

## Available Agents (.claude/agents/)

When spawning teammates, choose the right `subagent_type`:

| Agent                     | Best For                             | Tools                        |
| ------------------------- | ------------------------------------ | ---------------------------- |
| `typescript-pro`          | Advanced TS types, monorepo patterns | All                          |
| `backend-architect`       | API design, microservices, Moleculer | All                          |
| `frontend-developer`      | React, Next.js, UI components        | All                          |
| `nextjs-developer`        | Next.js 15 App Router, SSR           | All                          |
| `fullstack-developer`     | End-to-end features                  | All                          |
| `code-reviewer`           | Security, quality, patterns          | Read, Grep, Glob, Bash       |
| `architect-reviewer`      | Design decisions, system design      | All                          |
| `debugger`                | Production issues, root cause        | All                          |
| `error-detective`         | Error patterns, log analysis         | All                          |
| `research-analyst`        | Research, web search, synthesis      | Read, Write, Grep, WebSearch |
| `search-specialist`       | Finding code, patterns               | Read, Write, Grep, WebSearch |
| `performance-engineer`    | Optimization, profiling              | All                          |
| `microservices-architect` | Service boundaries, communication    | All                          |
| `documentation-engineer`  | Docs, API docs                       | Read, Write, Grep, WebSearch |
| `prompt-engineer`         | LLM prompts, AI features             | All                          |
| `platform-engineer`       | Infrastructure, DevOps               | All                          |
| `mcp-developer`           | MCP servers, integrations            | All                          |
| `gerts-api-tester`        | Gerts Pipeline API testing           | All                          |
| `Explore`                 | Quick codebase exploration           | Read-only                    |
| `general-purpose`         | Anything, full tool access           | All                          |

---

## Available Skills & Plugins

Teammates can activate skills for domain knowledge:

| Skill                                               | When to Activate             |
| --------------------------------------------------- | ---------------------------- |
| `typescript-pro`                                    | Advanced type system         |
| `typescript-advanced-types`                         | Generics, conditional types  |
| `api-design-principles`                             | REST/GraphQL design          |
| `microservices-patterns`                            | Service communication        |
| `frontend-design`                                   | UI components, design system |
| `javascript-testing-patterns`                       | Vitest, Testing Library      |
| `backend-development:architecture-patterns`         | Clean arch, DI, SOLID        |
| `backend-development:event-store-design`            | Event sourcing               |
| `backend-development:cqrs-implementation`           | CQRS read/write split        |
| `database-design:postgresql`                        | Prisma schema, indexes       |
| `developer-essentials:auth-implementation-patterns` | JWT, OAuth2, sessions        |

**Activate in teammate prompt:**

```
Before implementing, activate relevant skills:
Skill("typescript-pro") for type-safe patterns
Skill("api-design-principles") for REST conventions
```

---

## Context7 Quick Reference

**Use Context7 instead of web browsing for library docs:**

```javascript
// Step 1: Resolve library ID
mcp__context7__resolve -
  library -
  id({
    libraryName: 'next.js',
    query: 'server actions and form handling',
  });

// Step 2: Query docs
mcp__context7__query -
  docs({
    libraryId: '/vercel/next.js',
    query: 'how to implement server actions with form validation',
  });
```

**Pre-resolved IDs for common libs:**
| Library | ID | Use For |
|---------|-----|---------|
| Next.js | `/vercel/next.js` | SSR, routing, server actions |
| React | `/facebook/react` | Hooks, patterns, Server Components |
| TanStack Query | `/tanstack/query` | Data fetching, mutations |
| Prisma | `/prisma/prisma` | ORM, migrations, queries |
| Zustand | `/pmndrs/zustand` | Client state |
| Tailwind CSS | `/tailwindlabs/tailwindcss` | Utility classes |
| Vitest | `/vitest-dev/vitest` | Testing framework |
| Moleculer | `/moleculerjs/moleculer` | Microservices framework |
| BullMQ | `/taskforcesh/bullmq` | Job queue |

---

## Delegate Mode

When you want the leader to ONLY coordinate (not implement):

1. Create the team
2. Press `Shift+Tab` to enter delegate mode
3. Leader can only: spawn, message, shutdown teammates, manage tasks
4. Leader does NOT write code

**Best for**: Large teams (4+), complex coordination.

---

## Anti-Patterns (AVOID)

| Anti-Pattern                              | Why Bad                        | Do Instead                    |
| ----------------------------------------- | ------------------------------ | ----------------------------- |
| Two teammates editing same file           | Overwrites, conflicts          | Strict file ownership         |
| Skipping memory_recall                    | Re-doing past decisions        | ALWAYS recall first           |
| Not reading TODO files                    | Missing context, re-doing work | Read TODOs with sub-tasks     |
| Reading entire TODO at once               | Context overflow (5300 lines!) | Use offset/limit or sub-tasks |
| Not logging results to TODO               | Lost work history              | ALWAYS update TODO after      |
| Web browsing for library docs             | Slow, noisy                    | Use Context7 MCP              |
| Not reading RFCs/sources                  | Reinventing the wheel          | Study before coding           |
| Leader implementing instead of delegating | Bottleneck                     | Use delegate mode             |
| Too many teammates (>5)                   | Token explosion                | 2-4 is sweet spot             |
| No plan approval on risky changes         | Wasted work                    | Require plan approval         |
| Not saving learnings                      | Lost knowledge                 | memory_retain() after         |
| One giant task per teammate               | No checkpoints                 | 5-6 smaller tasks each        |
| Not reading package README                | Reimplementing existing code   | Check packages/ first         |
| Not verifying TODO vs source code         | TODO may be outdated           | Grep/Glob to verify           |

---

## Cleanup & Knowledge Retention

After team work is done:

1. **Retain** — each teammate saves key learnings:
   ```
   memory_retain("# [Topic] — Implementation Notes\nKey decisions: ...\nPatterns used: ...\nGotchas: ...")
   ```
2. Ask each teammate to mark tasks as completed
3. Send shutdown requests to all teammates
4. Wait for all shutdowns to be approved
5. Run `TeamDelete` to clean up resources
6. **Update docs** if needed:
   - New bugs → `docs/fixes/KNOWN-ISSUES.md`
   - Done tasks → `apps/webapp/docs/dev/tasks/TODO.md`
   - Architecture decisions → relevant RFC
7. Commit changes: review diff carefully

---

## Quick Prompts (Copy-Paste)

### Minimal team (2 agents)

```
Create an agent team "quick-[task]" with 2 teammates:
1. "implementer" — [describe task]. Files: [paths]
   Start with: memory_recall("[topic]"), read relevant RFC, check packages/
2. "reviewer" — Review implementer's work. Check: security, tests, patterns.
   Study: sources/[relevant] for reference patterns.
```

### Frontend-only team

```
Create an agent team "ui-[feature]" with 2 teammates:
1. "page-builder" — Create page + components in apps/webapp/src/.
   Read: apps/webapp/docs/dev/FRONTEND-PATTERNS.md
   Use: existing DS components, FSD layers, Context7 for React/Next.js
2. "hook-builder" — Create TanStack Query hooks in features/admin/[module]/hooks.ts.
   Read: apps/webapp/src/shared/api/client.ts for API client patterns
   Use: Context7 for TanStack Query docs
```

### Backend-only team

```
Create an agent team "api-[feature]" with 2 teammates:
1. "action-dev" — Create Moleculer actions in apps/pipeline/src/services/[svc]/.
   Read: apps/pipeline/docs/guides/PIPELINE-MOLECULER-USAGE-AI.md
   Read: RFC-XXX for requirements
   Study: sources/[relevant] for patterns
2. "store-dev" — Create Prisma store methods in packages/auth-prisma/.
   Read: packages/auth-prisma/src/oidc-stores.ts for patterns
   Include tests. Rebuild: pnpm --filter @gerts/auth-prisma build
```

### Research team

```
Create an agent team "research-[topic]" with 3 teammates:
1. "our-code" — Study packages/ and services/ for current implementation.
   memory_recall("[topic]"). Use Grep/Glob to map patterns.
2. "their-code" — Study sources/ and research/projects/ for reference.
   Read research/SOURCES-REFERENCE.md first. Use Context7 for lib docs.
3. "synthesizer" — Combine findings into RFC draft.
   Read apps/pipeline/docs/RFC-INDEX.md for format.
   memory_retain() all architectural decisions.
Require plan approval for synthesizer.
```
