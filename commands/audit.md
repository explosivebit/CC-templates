---
description: Expert audit panel — min 4 specialized agents review code with skills (logic, SOLID, types, tests, security, architecture). Compares result vs original task.
argument-hint: '[files, feature, or task to audit]'
---

# Expert Audit Panel (Skill-Based)

Trigger: User wants thorough multi-expert review of code, architecture, or completed feature.
Use when: "проверь", "ревью", "аудит", "оцени качество", "всё ли правильно"

---

## Core Rule: MINIMUM 4 SKILL-AGENTS

**ОБЯЗАТЕЛЬНО**: каждый аудит запускает **минимум 4 агента** со специализированными skills.
Каждый агент проверяет свой аспект. Панель подбирается под задачу.

---

## Architecture (4 Phases)

Phase 1 — SCOPE ANALYSIS: determine what to audit, find original task/RFC, select skill panel
Phase 2 — PARALLEL REVIEW: launch 4-6 agents via TeamCreate with specialized skills
Phase 3 — TASK COMPLETION CHECK: compare what was done vs what was originally requested
Phase 4 — SYNTHESIS & VERDICT: consolidate reports, score, present action plan

---

## Phase 1: SCOPE ANALYSIS (before launching agents)

### 1a. Determine WHAT to audit

Parse `$ARGUMENTS`:

- Specific files? Read them, pass content to agents
- A feature/module? Use Glob + Grep to find all related files
- "последние изменения"? Run `git diff HEAD~1` or `git diff --staged`
- A PR? Run `gh pr diff`
- A sprint? Find all modified files in the sprint

### 1b. Find the ORIGINAL TASK

**ОБЯЗАТЕЛЬНО**: Найти первоначальную постановку задачи:

- RFC файл (`apps/pipeline/docs/RFC-*.md`) — Phase/tasks section
- TODO файл — конкретные checkbox items
- Sprint plan — если был `/sprint`
- Git branch name — для контекста

Это нужно для Phase 3 (проверка: сделано ли то, что просили).

### 1c. Build FILE_LIST — all files in scope (max 30 files)

Read each file content (or relevant sections for files > 500 lines).

### 1d. Select SKILL PANEL (minimum 4, maximum 6)

**Обязательные 4 (ВСЕГДА включены):**

| #   | Agent Name          | subagent_type        | Skill Focus                       | Checklist                                                                           |
| --- | ------------------- | -------------------- | --------------------------------- | ----------------------------------------------------------------------------------- |
| 1   | `logic-reviewer`    | `code-reviewer`      | **Логика + Бизнес-логика**        | Корректность алгоритмов, edge cases, race conditions, data flow, off-by-one errors  |
| 2   | `arch-reviewer`     | `architect-reviewer` | **SOLID + Архитектура**           | SOLID principles, DI, dependency direction, patterns, over-engineering, consistency |
| 3   | `type-reviewer`     | `typescript-pro`     | **Типизация + Type Safety**       | any/as/! usage, generic constraints, duck-typing drift, Zod↔TS alignment            |
| 4   | `security-reviewer` | `code-reviewer`      | **Безопасность + Error Handling** | OWASP, injection, path traversal, PII exposure, error swallowing, DoS vectors       |

**Дополнительные (подбираются по scope):**

| #   | Agent Name          | subagent_type             | Skill Focus                 | When to Include                         |
| --- | ------------------- | ------------------------- | --------------------------- | --------------------------------------- |
| 5   | `test-reviewer`     | `general-purpose`         | **Тестирование + Coverage** | Когда есть тесты или должны быть        |
| 6   | `backend-reviewer`  | `microservices-architect` | **Service Patterns**        | Moleculer, microservices, inter-service |
| 7   | `frontend-reviewer` | `frontend-developer`      | **UI + State + UX**         | React/Next.js components                |
| 8   | `task-reviewer`     | `general-purpose`         | **Task Completion**         | Когда есть RFC/TODO с checklist         |

### 1e. Panel Selection Matrix

| Scope Type                | Agents (min 4)                                       |
| ------------------------- | ---------------------------------------------------- |
| **Backend TypeScript**    | logic + arch + type + security + test (5)            |
| **Full-stack feature**    | logic + arch + type + security + frontend + test (6) |
| **Moleculer services**    | logic + arch + type + security + backend (5)         |
| **Types/interfaces only** | logic + arch + type + security (4)                   |
| **Sprint completion**     | logic + arch + type + security + test + task (6)     |
| **Quick review**          | logic + arch + type + security (4)                   |

---

## Phase 2: LAUNCH PARALLEL REVIEWS via TeamCreate

**CRITICAL**: Use Claude Code Teams. Minimum 4 agents, all parallel.

```python
# 1. Create team
TeamCreate(team_name="audit-{scope}")

# 2. Launch ALL agents in ONE message
Agent(name="logic-reviewer", subagent_type="code-reviewer", team_name="audit-{scope}", ...)
Agent(name="arch-reviewer", subagent_type="architect-reviewer", team_name="audit-{scope}", ...)
Agent(name="type-reviewer", subagent_type="typescript-pro", team_name="audit-{scope}", ...)
Agent(name="security-reviewer", subagent_type="code-reviewer", team_name="audit-{scope}", ...)
# + optional agents based on scope
```

### Agent Prompt Template

Each agent gets:

```
## Expert Audit Assignment

**Role**: [Specialization]
**Scope**: [File list]
**Context**: [What was built/changed]
**Original Task**: [RFC/TODO reference — what was REQUESTED]

### Your Task
Review the code from YOUR expert perspective. Be CRITICAL but fair.
Read every file carefully. Focus on your domain expertise.

### Files to Review
[Actual file contents pasted here]

### Review Checklist (your domain)
[Domain-specific checklist — see below]

### IMPORTANT: Task Completion Check
Compare what was IMPLEMENTED against what was REQUESTED in the original task.
List any items that are:
- ✅ Done correctly
- ⚠️ Done but with issues
- ❌ Not done / missing
- 🔄 Done differently than requested (explain why it matters or doesn't)

### Output Format (STRICT)

## [Your Role] Review

### Score: X/10

### Task Completion
- ✅ [item] — done correctly
- ⚠️ [item] — done with issues: [what]
- ❌ [item] — missing / not implemented

### Critical Issues (must fix)
- [C1] file.ts:line — Description. Fix: what to do.

### Warnings (should fix)
- [W1] file.ts:line — Description. Suggestion: ...

### Positive Findings
- [P1] Description

### Verdict
ONE of: APPROVE | APPROVE_WITH_FIXES | REQUEST_CHANGES | REJECT

### Key Recommendation (1-2 sentences)
```

### Domain-Specific Checklists

**logic-reviewer (Логика + Корректность):**

- Алгоритмическая корректность — делает ли код то, что заявлено?
- Edge cases: null, undefined, empty arrays, 0, negative values
- Race conditions: concurrent access, shared mutable state
- Data flow: входные данные → обработка → выход — цепочка корректна?
- Off-by-one errors, boundary conditions
- Fire-and-forget: ошибки не теряются молча?
- Кеширование: invalidation, stale data, thundering herd
- Идемпотентность: повторный вызов безопасен?
- Resource cleanup: нет утечек (listeners, timers, connections)

**arch-reviewer (SOLID + Архитектура):**

- **S**: Single Responsibility — каждый класс/модуль делает одно
- **O**: Open/Closed — можно расширить без модификации?
- **L**: Liskov Substitution — подтипы заменяемы?
- **I**: Interface Segregation — интерфейсы не раздуты?
- **D**: Dependency Inversion — зависимости на абстракции?
- DI через конструкторы, нет monkey-patching (Hard Req #14)
- Dependency direction: нет circular deps
- Over-engineering vs under-engineering
- Consistency с существующими паттернами кодовой базы
- APIError с ResponseCode, не generic `throw new Error`
- getTenantIdStrict для authenticated endpoints

**type-reviewer (Типизация):**

- `any` usage — каждый `any` = потенциальный runtime баг
- `as` casts — unsafe type assertions
- `!` non-null assertions — вместо type guards
- Generic constraints: `<T extends ...>` корректны?
- Duck typing: interface shapes совпадают с реальными данными?
- Zod schema ↔ TypeScript type alignment
- Return type inference: явные vs inferred
- `unknown` vs `any` на boundaries
- Discriminated unions для state machines
- Inline types vs named exports (DRY)

**security-reviewer (Безопасность):**

- OWASP Top 10: injection, XSS, SSRF, path traversal
- Input validation на boundaries (user input, API params)
- `encodeURIComponent` для URL path/query params
- PII/sensitive data: не логируется, не сохраняется в открытом виде
- Error handling: try/catch, нет swallowed errors без причины
- DoS vectors: unbounded loops, arrays, memory growth
- Content length limits на user input
- Tenant isolation: tenantId проверяется на каждом уровне
- Auth propagation: ctx.call() не broker.call() в handlers

**test-reviewer (Тестирование):**

- Все public methods покрыты тестами
- Edge cases: empty, error, timeout, null
- Negative tests: что если всё сломается?
- Mock quality: реалистичные моки, не stub-заглушки
- Backward compatibility: старый код не сломан
- Integration: E2E flow протестирован
- Determinism: тесты не flaky
- Test isolation: нет shared state между тестами
- Missing tests: конкретный список

**backend-reviewer (Service Patterns):**

- Service boundary violations
- Inter-service communication: ctx.call vs broker.call
- Tenant isolation в каждом query/action
- Idempotency и retry safety
- Event-driven patterns: channels vs emit (Hard Req #12)
- Error resilience: что если сервис недоступен?
- Resource cleanup: connections, listeners

---

## Phase 3: TASK COMPLETION CHECK

**ОБЯЗАТЕЛЬНО после получения всех отчётов.**

Сравнить что было ЗАПРОШЕНО (RFC/TODO) vs что было СДЕЛАНО:

```markdown
### Task Completion Matrix

| #   | Original Task | Status                           | Details      |
| --- | ------------- | -------------------------------- | ------------ |
| 1   | task from RFC | ✅ Done / ⚠️ Issues / ❌ Missing | what exactly |
| 2   | ...           | ...                              | ...          |

### Completion Rate: X/Y tasks (Z%)
```

Если completion < 80% → verdict не может быть APPROVE.

---

## Phase 4: SYNTHESIS & VERDICT

### 4a. Collect Reports + Cross-Reference

- Consensus: Multiple agents flagged same issue = HIGH confidence
- Unique findings: Only one agent noticed = verify importance
- Conflicts: Agents disagree = present both sides

### 4b. Calculate Overall Score

Weighted average (1-10):

| Agent             | Weight | Reason                                   |
| ----------------- | ------ | ---------------------------------------- |
| logic-reviewer    | 1.3    | Logic bugs are hardest to catch later    |
| arch-reviewer     | 1.2    | Architecture decisions are costly to fix |
| security-reviewer | 1.2    | Security bugs are critical               |
| type-reviewer     | 1.0    | Type safety baseline                     |
| test-reviewer     | 0.8    | Tests can be added later                 |
| backend-reviewer  | 0.8    | Service patterns                         |
| frontend-reviewer | 0.8    | UI patterns                              |
| task-reviewer     | 0.7    | Task completion                          |

### 4c. Final Verdict

| Condition                                 | Verdict                |
| ----------------------------------------- | ---------------------- |
| All APPROVE + completion ≥ 80%            | **APPROVE**            |
| Majority APPROVE, some APPROVE_WITH_FIXES | **APPROVE_WITH_FIXES** |
| Any REQUEST_CHANGES                       | **REQUEST_CHANGES**    |
| Any REJECT or completion < 50%            | **REJECT**             |

### 4d. Consolidated Report

```markdown
# Audit Report: [Target]

**Panel**: [agents used with their skills]
**Files reviewed**: N files, ~M LOC
**Date**: YYYY-MM-DD
**Original Task**: [RFC/TODO reference]

## Overall Score: X.X/10

## Task Completion: X/Y (Z%)

## Verdict: [APPROVE | APPROVE_WITH_FIXES | REQUEST_CHANGES | REJECT]

---

### Task Completion Matrix

| #   | Task | Status | Details |
| --- | ---- | ------ | ------- |

### Consensus Issues (2+ agents agree)

| #   | Severity | Issue | Agents | File:Line |
| --- | -------- | ----- | ------ | --------- |

### Unique Findings

| #   | Agent | Severity | Issue | File:Line |
| --- | ----- | -------- | ----- | --------- |

### Debate (agents disagree)

| Issue | For | Against | Recommendation |
| ----- | --- | ------- | -------------- |

### Positive Highlights

- Top 5 things done well

### Action Plan (priority order)

1. [CRITICAL] ...
2. [WARNING] ...
3. [NICE-TO-HAVE] ...
```

### 4e. Ask User

```
Варианты:
1. ✅ Применить все исправления (critical + warnings)
2. 🔧 Только critical исправления
3. 📋 Показать каждое исправление по одному
4. ❌ Отклонить — я сделаю сам
```

---

## Token Budget Management

- Max 6 agents per audit
- File content in prompt directly — agent doesn't re-read files
- Model: `sonnet` for all agents (faster, cheaper)
- Large files (>500 lines): pass only changed sections
- Each agent prompt: max ~8000 tokens
- Each agent response: ~1500-2500 tokens

---

## Examples

```
/audit                              → audit staged/unstaged changes (auto-detect)
/audit последний коммит             → git diff HEAD~1
/audit packages/auth/               → all files in package
/audit RFC-124 Phase 5              → find RFC, extract tasks, audit completion
/audit PR #42                       → gh pr diff 42
```

---

## Cleanup

After synthesis:

1. Shutdown all reviewers via `SendMessage(type="shutdown_request")`
2. `TeamDelete()`

---

## Error Handling

- Agent fails/times out: note in report, don't block others
- Scope empty: ask user to clarify
- Scope > 30 files: ask user to narrow or split
- All APPROVE but tsc fails: override to REQUEST_CHANGES
- No RFC/TODO found: skip Phase 3, note in report
