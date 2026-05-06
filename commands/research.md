---
description: Deep multi-agent research across all project knowledge — codebase, docs, RFCs, sources, memory. 5 parallel agents for thorough coverage.
argument-hint: '[topic or question to research]'
---

# /research — Multi-Agent Deep Research (5 Agents)

**Trigger**: User needs to research a topic across the entire project knowledge base.

Examples:

- `/research как работает auth chain`
- `/research SSO SAML integration patterns`
- `/research что уже сделано по webhooks`
- `/research сравни наш queue с n8n и trigger.dev`

---

## Why 5 Agents?

Each knowledge source is large and needs a dedicated context window:

- TODO files: up to 5300 lines each
- RFCs: 64 documents
- Sources: 50+ reference projects
- Packages: 40+ internal libraries
- MCP Memory: cross-session knowledge

3 agents would overflow. 5 agents = each holds only its slice and does it well.

---

## Workflow

### Step 0: VALIDATE INPUT

The user MUST provide a `$ARGUMENTS` — the topic/question to research. If empty, ask:

```
What do you want to research? Examples:
- "auth chain architecture"
- "what's done for webhooks"
- "compare our queue with n8n"
- "SSO SAML integration patterns"
```

### Step 1: RECALL — Quick Memory Check

Before spawning the team, do a quick check:

```
memory_recall("$ARGUMENTS")
```

This gives baseline context. Share results with all teammates in their prompts.

### Step 2: CLASSIFY — Determine Relevant Keywords

Extract 3-5 search keywords from the topic. Examples:

- "auth chain architecture" → `auth, chain, middleware, session, token`
- "SSO SAML integration" → `sso, saml, oidc, connector, login`
- "webhooks v2" → `webhook, event, notification, callback, realtime`

Also determine which domains are relevant (see table in Step 3).

### Step 3: SPAWN RESEARCH TEAM (5 Agents) — MANDATORY: Use CC Teams!

**CRITICAL**: Always use Claude Code Teams for multi-agent research. NEVER use standalone `Task(run_in_background)` calls.

```python
# 1. Create team (TeamCreate tool)
TeamCreate(team_name="research-{sanitized-topic}")

# 2. Spawn ALL 5 agents in ONE message with team_name parameter:
Task(
  description="Search code",
  subagent_type="Explore",
  team_name="research-{sanitized-topic}",
  name="code-researcher",
  prompt="..."
)
Task(
  description="Search RFCs",
  subagent_type="Explore",
  team_name="research-{sanitized-topic}",
  name="rfc-researcher",
  prompt="..."
)
# ... all 5 in ONE message
```

#### Domain Mapping (pick relevant sources for each agent)

| Topic Pattern         | Agent Focus                                    | Key Paths                                       |
| --------------------- | ---------------------------------------------- | ----------------------------------------------- |
| Auth, IAM, OIDC, SSO  | packages/auth\*, services/oidc, services/admin | RFC-039/050/077, sources/logto, sources/zitadel |
| Queue, Jobs, Pipeline | packages/queue, services/queue                 | RFC-032/044, sources/n8n, sources/trigger.dev   |
| Graph, RAG, Knowledge | packages/graph, services/graph                 | RFC-031/036/040/041, sources/graphiti           |
| Frontend, UI, Webapp  | apps/webapp/src, apps/webapp/docs              | sources/langfuse, sources/logto                 |
| API, SDK, Client      | packages/api-_, packages/client_               | RFC-029/030/075, sources/moleculer              |
| Connectors            | connectors/, packages/connector-\*             | RFC-042/076, sources/airbyte                    |
| Realtime, Events, WS  | packages/flux, packages/ws-rpc                 | RFC-028, sources/trigger.dev                    |
| Security, HSM, Vault  | packages/hsm, packages/auth                    | RFC-052/055, sources/zitadel                    |
| Agents, LLM, AI       | packages/agent, services/llm                   | sources/crewai, sources/agno                    |
| Database, Prisma      | packages/database, packages/auth-prisma        | sources/zitadel (eventstore)                    |
| ETL, Ingest           | packages/ingest, services/etl                  | RFC-044, sources/dagster                        |

---

### Teammate 1: "code-researcher" (subagent_type: Explore)

**Scope**: Source code only — packages, services, connectors, configs, tests.

```
You are a SOURCE CODE research agent for the gerts.ai project.
You search ONLY source code — no documentation, no external references.

TOPIC: "$ARGUMENTS"
KEYWORDS: $KEYWORDS
MEMORY CONTEXT: $MEMORY_RECALL_RESULTS

=== SEARCH STRATEGY ===

Search in this exact order. For each, use Grep with keywords, then Read key files.

1. PACKAGES (packages/):
   - Glob("packages/*/README.md") — scan for relevant packages
   - Grep("$KEYWORD1|$KEYWORD2", "packages/*/src/") — find implementations
   - Read relevant src/index.ts for public API surface
   - Check package.json for dependencies

2. BACKEND SERVICES (apps/pipeline/src/services/):
   - Grep("$KEYWORDS", "apps/pipeline/src/services/") — find actions
   - Read action files, types.ts, configs
   - Note: route paths, params, auth requirements

3. WEBAPP (apps/webapp/src/):
   - Grep("$KEYWORDS", "apps/webapp/src/features/") — hooks, components
   - Grep("$KEYWORDS", "apps/webapp/src/app/") — routes, pages
   - Grep("$KEYWORDS", "apps/webapp/src/shared/") — shared utils

4. CONNECTORS (connectors/):
   - Grep("$KEYWORDS", "connectors/") — if relevant

5. TESTS (*.test.ts, *.test.tsx):
   - Grep("$KEYWORDS", glob="*.test.ts") — test patterns
   - Count test files per module

6. CONFIGS:
   - Check: apps/pipeline/.env.example, moleculer.config, tsconfig, package.json

=== OUTPUT FORMAT ===

## Source Code: $ARGUMENTS

### Packages
| Package | Key Files | Tests | What It Does |
|---------|-----------|-------|-------------|

### Services
| Service | Actions | Route | Auth |
|---------|---------|-------|------|

### Frontend
| Path | Type (page/hook/component) | What It Does |
|------|---------------------------|-------------|

### Patterns
- [pattern]: [where, how it works]

### Gaps (NOT implemented)
- [missing piece]: [expected location]

### Key Files (top 10)
| File | Lines | Relevance |
|------|-------|-----------|
```

---

### Teammate 2: "rfc-researcher" (subagent_type: Explore)

**Scope**: RFCs and implementation guides only. NOT TODO files.

```
You are an RFC & GUIDES research agent for the gerts.ai project.
You search ONLY RFCs and guides — no source code, no TODO files.

TOPIC: "$ARGUMENTS"
KEYWORDS: $KEYWORDS
MEMORY CONTEXT: $MEMORY_RECALL_RESULTS

=== SEARCH STRATEGY ===

1. RFC INDEX (ALWAYS start here):
   Read("apps/pipeline/docs/RFC-INDEX.md")
   Find ALL RFCs related to the topic.

2. RELEVANT RFCs:
   For each related RFC, read it (use offset/limit for large ones).
   Extract: status, key design decisions, open questions, dependencies.
   Note: RFC number, title, status (Draft/In Progress/Done).

3. GUIDES (apps/pipeline/docs/guides/):
   Grep("$KEYWORDS", "apps/pipeline/docs/guides/")
   Read relevant guides. Extract: key patterns, configurations, examples.

   Key guides to check:
   - PIPELINE-MOLECULER-USAGE-AI.md — Moleculer patterns
   - ERROR-HANDLING-PATTERNS.md — Error handling
   - AUTH-FLOW-GUIDE.md — Auth architecture
   - VAULT-HSM-OPERATIONS-GUIDE.md — Encryption/HSM
   - MCP.md — MCP integration
   - SCHEDULER-API-REFERENCE.md — Scheduler

4. KNOWN ISSUES:
   Read("apps/pipeline/docs/fixes/KNOWN-ISSUES.md")
   Check for related bugs.

5. PROJECT-LEVEL DOCS:
   - AGENTS.md — if topic relates to project structure
   - CLAUDE.md — if topic relates to dev workflow

=== OUTPUT FORMAT ===

## RFCs & Guides: $ARGUMENTS

### Related RFCs
| RFC | Title | Status | Key Decisions |
|-----|-------|--------|--------------|

### RFC Details
For each RFC (most relevant first):
#### RFC-XXX: Title
- **Status**: Draft/In Progress/Done
- **Key Design**: [main architectural choices]
- **Open Questions**: [unresolved items]
- **Dependencies**: [other RFCs, packages]

### Guides Found
| Guide | Key Info | Relevance |
|-------|----------|-----------|

### Known Issues
- [related bugs/issues]

### Decisions History
- [decision 1]: source, rationale
- [decision 2]: source, rationale
```

---

### Teammate 3: "todo-researcher" (subagent_type: Explore)

**Scope**: TODO files and project status ONLY. Dedicated agent because TODOs are huge.

```
You are a TODO & STATUS research agent for the gerts.ai project.
You search ONLY TODO files and status docs to determine what's done and what remains.

TOPIC: "$ARGUMENTS"
KEYWORDS: $KEYWORDS

=== SEARCH STRATEGY ===

TODO files are VERY LARGE. NEVER read them whole. Use Grep first, then Read with offset/limit.

1. PIPELINE TODO (apps/pipeline/docs/TODO.md — ~5300 lines):
   - Grep("$KEYWORD1|$KEYWORD2", "apps/pipeline/docs/TODO.md") — find relevant sections
   - Read relevant sections with offset/limit (±50 lines around each match)
   - Look for: [x] done items, [ ] remaining items, "Gaps", "Backend endpoints needed"

2. WEBAPP TODO (apps/webapp/docs/dev/TODO.md — ~1500 lines):
   - Grep("$KEYWORD1|$KEYWORD2", "apps/webapp/docs/dev/TODO.md")
   - Read relevant sections with offset/limit
   - Look for: [x] done, [ ] remaining, "Files Modified", "New files"

3. LANDING TODO (apps/landing/docs/TODO.md):
   - Grep("$KEYWORDS", "apps/landing/docs/TODO.md") — if relevant

4. WEBAPP UI DOCS (apps/webapp/docs/ui/):
   - Grep("$KEYWORDS", "apps/webapp/docs/ui/") — UI status, components

5. WEBAPP DEV DOCS (apps/webapp/docs/dev/):
   - Grep("$KEYWORDS", "apps/webapp/docs/dev/") — patterns, architecture

6. CROSS-CHECK with source code:
   For each [x] done item, quick-verify with Grep that the code exists.
   For each [ ] remaining, note it as a confirmed gap.

=== OUTPUT FORMAT ===

## Project Status: $ARGUMENTS

### Pipeline Backend
| Item | Status | Phase | Notes |
|------|--------|-------|-------|
| [feature] | Done [x] / Remaining [ ] | Phase N | [details] |

### Webapp Frontend
| Item | Status | Phase | Notes |
|------|--------|-------|-------|
| [feature] | Done [x] / Remaining [ ] | Phase N | [details] |

### Verified (code exists)
- [item]: confirmed at [path]

### Gaps (TODO says done but code missing)
- [item]: TODO claims done, but Grep found nothing at [expected path]

### Remaining Work ([ ] items)
1. [task] — from [TODO file, line]
2. [task] — from [TODO file, line]

### Timeline (from TODO dates)
- [date]: [what was done]
```

---

### Teammate 4: "reference-researcher" (subagent_type: Explore)

**Scope**: sources/ directory and reference implementations ONLY.

```
You are a REFERENCE IMPLEMENTATION research agent for the gerts.ai project.
You search ONLY the sources/ directory — studying how other projects solve similar problems.

TOPIC: "$ARGUMENTS"
KEYWORDS: $KEYWORDS

=== SEARCH STRATEGY ===

1. SOURCES INDEX:
   Read("research/SOURCES-REFERENCE.md") — find which projects are relevant.

2. Pick 3-5 most relevant source projects. Key mapping:

   | Domain | Sources |
   |--------|---------|
   | Auth/OIDC | sources/logto/, sources/zitadel/ |
   | Job Queue | sources/n8n/, sources/trigger.dev/ |
   | Graph RAG | sources/graphiti/, sources/graphrag/ |
   | Observability | sources/langfuse/ |
   | Connectors | sources/airbyte/, sources/rudder-server/ |
   | Agents | sources/crewai/, sources/agno/ |
   | Data Pipeline | sources/dagster/ |
   | Ingestion | sources/ragflow/, sources/onyx/ |
   | LLM Proxy | sources/litellm/ |
   | Workflow | sources/pyspur/, sources/orchestra/ |
   | Microservices | sources/moleculer/ |
   | Memory | sources/hindsight/ |
   | Auth (fine-grained) | sources/openfga/ |

3. For each relevant source:
   - Grep("$KEYWORDS", "sources/[name]/") — find relevant modules
   - Read key architecture files (README, main entry points)
   - Focus on ARCHITECTURE and PATTERNS, not implementation details
   - Note: how they structure it, what patterns they use, trade-offs

4. CONTEXT7 — For library documentation (if topic involves external libs):
   Use mcp__context7__resolve-library-id then mcp__context7__query-docs

=== OUTPUT FORMAT ===

## Reference Implementations: $ARGUMENTS

### Projects Analyzed
For each (top 3-5):

#### [Project Name] (sources/[path])
- **Their approach**: [how they solve it]
- **Key architecture**: [patterns, structure]
- **Key files**: [2-3 most important files]
- **Pros**: [advantages]
- **Cons**: [disadvantages]
- **Relevance to gerts.ai**: [how applicable]

### Industry Patterns Comparison
| Pattern | Used By | Pros | Cons |
|---------|---------|------|------|

### Best Fit for gerts.ai
- **Recommended approach**: [which pattern and why]
- **Key adaptations needed**: [what to change for our context]

### Library Docs (Context7)
- [library]: [key findings]
```

---

### Teammate 5: "knowledge-researcher" (subagent_type: Explore)

**Scope**: MCP Memory, research/ directory, research/projects/, and cross-cutting synthesis.

```
You are a KNOWLEDGE BASE research agent for the gerts.ai project.
You search MCP Memory (Hindsight) and the research/ directory for accumulated knowledge.

TOPIC: "$ARGUMENTS"
KEYWORDS: $KEYWORDS

=== SEARCH STRATEGY ===

1. MCP MEMORY (Hindsight) — accumulated knowledge across sessions:
   memory_recall("$ARGUMENTS")
   memory_recall("$KEYWORD1 architecture")
   memory_recall("$KEYWORD2 decisions")
   memory_recall("$KEYWORD1 patterns")
   memory_recall("$KEYWORD1 bugs known issues")

   Extract ALL relevant memories. Note dates and confidence.

2. RESEARCH DIRECTORY (research/):
   - Read("research/00-MASTER-PLAN.md") — master plan context
   - Grep("$KEYWORDS", "research/") — find relevant analysis
   - Glob("research/reports/*.md") — available reports
   - Glob("research/*.md") — top-level analysis files

3. RESEARCH PROJECTS (research/projects/):
   - Glob("research/projects/*/") — list all per-project analyses
   - Grep("$KEYWORDS", "research/projects/") — find relevant ones
   - Read relevant project analyses

4. CROSS-ANALYSIS:
   - Grep("$KEYWORDS", "research/cross-analysis/") — if exists
   - Grep("$KEYWORDS", "research/architecture/") — if exists

5. REFLECT on findings:
   memory_reflect("What patterns emerge from our research on $ARGUMENTS?")

=== OUTPUT FORMAT ===

## Knowledge Base: $ARGUMENTS

### From Memory (Hindsight)
| Memory | Date | Key Info |
|--------|------|----------|
| [title] | [date] | [relevant content] |

### Past Decisions
- [decision]: [rationale, source]

### Research Documents
| Document | Path | What It Contains |
|----------|------|-----------------|

### Per-Project Analysis
| Project | Path | Key Findings |
|---------|------|-------------|

### Patterns & Insights
- [pattern 1]: [where observed, significance]
- [pattern 2]: [where observed, significance]

### Contradictions / Conflicts
- [if memory says X but research says Y, note it]

### Knowledge Gaps
- [what we DON'T know yet about this topic]
```

---

### Step 4: MONITOR & SYNTHESIZE

As leader, wait for all 5 teammates to complete. Then:

1. **Read all 5 reports** from teammates
2. **Cross-reference findings**:
   - Source code vs TODOs (code wins if conflict)
   - RFCs vs implementation (note gaps)
   - Our code vs reference implementations (compare patterns)
   - Memory vs current state (update if stale)
3. **Identify conflicts** — where sources disagree
4. **Synthesize** into a final research report

### Step 5: DELIVER REPORT

Present the synthesized report to the user:

```markdown
# Research Report: $ARGUMENTS

**Date**: YYYY-MM-DD
**Team**: 5 agents (code + rfcs + todos + references + knowledge)

---

## Executive Summary

[2-3 sentences: what we found, what's the state, what's missing]

## Current State

### What Exists in Code

[from code-researcher — packages, services, frontend]

### What Documentation Says

[from rfc-researcher — RFC status, guide findings]

### Project Status (from TODOs)

[from todo-researcher — done items, remaining items, verified vs unverified]

### Code vs Docs Alignment

| Item      | In Code? | In Docs?       | Status                |
| --------- | -------- | -------------- | --------------------- |
| [feature] | Yes/No   | RFC-XXX / TODO | Aligned / Gap / Stale |

## How Others Do It

[from reference-researcher — top 2-3 approaches, comparison table]

## Accumulated Knowledge

[from knowledge-researcher — past decisions, patterns, insights]

## Gaps & Opportunities

1. [gap] — [where found], [impact], [suggested approach]

## Recommendations

1. [recommendation with rationale]

## Key Files

| File | What | Relevance |
| ---- | ---- | --------- |

## Sources Consulted

[list of all files, docs, RFCs, sources, memories checked — by agent]
```

### Step 6: SAVE TO MEMORY

After delivering the report:

```
memory_retain("# Research: $ARGUMENTS — Summary (YYYY-MM-DD)
Scope: 5-agent deep research across code, RFCs, TODOs, references, knowledge
Key findings:
- [finding 1]
- [finding 2]
- [finding 3]
Gaps: [main gaps]
Recommendations: [top 2-3]
Key files: [most important paths]")
```

### Step 7: CLEANUP

```python
# 1. Send shutdown to all teammates
SendMessage(type="shutdown_request", recipient="code-researcher", content="Done")
SendMessage(type="shutdown_request", recipient="rfc-researcher", content="Done")
SendMessage(type="shutdown_request", recipient="todo-researcher", content="Done")
SendMessage(type="shutdown_request", recipient="reference-researcher", content="Done")
SendMessage(type="shutdown_request", recipient="knowledge-researcher", content="Done")

# 2. Wait for shutdowns to be approved

# 3. Delete team
TeamDelete()
```

---

## Lightweight Mode (2-3 sub-agents, no team)

For narrow/simple questions (< 3 knowledge layers, < 10 files), use parallel Task() calls WITHOUT TeamCreate:

```python
# Use ONLY when:
# - Simple factual question ("where is X?")
# - Single domain (only code OR only docs)
# - Expected < 10 files to check
# - 2-3 agents max

Task(description="Search code", subagent_type="Explore", prompt="...")
Task(description="Search docs", subagent_type="Explore", prompt="...")
```

**Decision rule**:

- **3+ agents** → MUST use TeamCreate (full team mode)
- **1-2 agents** → lightweight Task() calls OK
- **When in doubt** → use TeamCreate (coordination overhead is minimal)

---

## Tips for the Leader

1. **Always memory_recall first** — it's free and may already have the answer
2. **Extract good keywords** — each agent searches with Grep, so keywords matter
3. **Share memory results** — pass memory_recall output to all teammates in spawn prompt
4. **Don't duplicate work** — each agent has its own exclusive scope
5. **Cross-reference is the value** — the synthesis is where insights emerge
6. **Save findings** — future /research calls will benefit from memory
7. **Verify TODOs against code** — todo-researcher's #1 job is to check if [x] items actually exist
