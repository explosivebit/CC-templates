---
description: Generate and execute a wave-based sprint plan with parallel Agent Teams. Researches context, generates phased plan, asks for approval, then executes wave-by-wave via TeamCreate tool.
argument-hint: '[task description — what to implement, RFC reference, scope]'
---

# /sprint — Wave-Based Sprint Planner & Executor

> **Терминология**: Фича = **Agent Teams**. Создание команды = `TeamCreate` (tool). Удаление = `TeamDelete` (tool). Env: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

> **!!! ЖЕЛЕЗНОЕ ПРАВИЛО — ПРОЧИТАЙ ПЕРЕД ЛЮБЫМ ДЕЙСТВИЕМ !!!**
>
> 1. **`TeamCreate`** — ЕДИНСТВЕННЫЙ способ запуска. `Task()` напрямую — **ЗАПРЕЩЕНО**.
> 2. **Team-lead** = ТОЛЬКО координация. **НЕ ПИШЕТ КОД. НЕ РЕДАКТИРУЕТ ФАЙЛЫ. ТОЧКА.**
> 3. **Teammates** = ВСЯ работа. Каждый в СВОЁМ процессе, СВОЙ контекст.
> 4. Доп. работа → **НОВЫЙ teammate**. Нагружать существующих — **ЗАПРЕЩЕНО**.
> 5. Перед `TeamCreate` → **ПРОВЕРИТЬ** старые команды → **СПРОСИТЬ** пользователя → **`TeamDelete`**.
> 6. **НЕ удалять команды молча** — всегда спрашивай пользователя!
>
> **Нарушение = провал спринта. Это правило НЕ обсуждается.**

**Takes a task description**, researches context, generates a FULL TEXT PLAN, shows it to user for review, and ONLY after approval executes wave-by-wave via `TeamCreate`.

Examples:

- `/sprint RFC-080 Phase 5 Command Center — AI sidebar, enhanced cmd+k, full assistant page`
- `/sprint RFC-089 ontology management frontend — CRUD screens, graph viz, versioning UI`
- `/sprint implement webhooks v2 — retry logic, DLQ, delivery UI`
- `/sprint refactor auth chain — JWT validation, session consolidation, middleware cleanup`

**Input**: Task description with scope
**Output**: Text plan → User approval → Wave-by-wave execution

---

## STEP 1: RESEARCH — Gather Context (MANDATORY)

Before generating ANY plan, gather context using parallel sub-agents:

### 1a. Determine Scope

Parse `$ARGUMENTS` to identify:

- **RFC reference** (if mentioned) → read the RFC
- **Branch** → `git branch --show-current`
- **TODO location** → find relevant section in TODO files
- **Existing code** → Glob/Grep for existing files related to task

### 1b. Launch 3 Parallel Research Agents

```
Agent R1 (Explore): "Read RFC + TODO"
  → Read RFC-XXX (if referenced)
  → Read relevant TODO section (apps/pipeline/docs/TODO.md or TODO_PHASE_TWO.md)
  → Extract: completed phases, remaining work, blockers

Agent R2 (Explore): "Scan existing codebase"
  → Glob/Grep for files related to task scope
  → Map: what exists, what can be reused, file ownership
  → Check for patterns in similar modules

Agent R3 (Explore): "Check memory + known issues"
  → memory_recall("[topic]")
  → Read KNOWN-ISSUES.md for related bugs
  → Check recent git log for context
```

### 1c. Synthesize Research into structured context:

- **Context**: branch, RFC, TODO location
- **Completed work**: what's already done
- **Remaining work**: tasks with LOC estimates
- **Existing resources**: reusable files/components
- **Key constraints**: project-specific rules

---

## STEP 2: GENERATE — Build Full Text Plan

Read the SPRINT TEMPLATE from `.claude/commands/sprint-template.md` and generate the COMPLETE plan.

### Plan Generation Rules

1. **Wave sizing**: 2-4 agents per wave, max 5 waves
2. **Total agents**: 5-8 teammates (team-lead is separate, coordination only)
3. **Agent LOC budget**: 100-400 LOC per agent
4. **File ownership**: NO overlapping files between agents in same wave
5. **Dependencies**: Waves sequential, agents within wave parallel
6. **Agent descriptions**: 80-120 words max. "Изучить → Создать → Requirements"
7. **Tests**: In last wave (or dedicated test agent per wave if >200 LOC)

> **!!! НАПОМИНАНИЕ**: План ОБЯЗАН включать секцию "Execution" с правилом TeamCreate.
> Team-lead = координация. Teammates = код. Task() напрямую = ЗАПРЕЩЕНО. !!!

### Agent Type Selection

| Task Type                 | subagent_type                              | When                   |
| ------------------------- | ------------------------------------------ | ---------------------- |
| General implementation    | `general-purpose`                          | Default for most tasks |
| Frontend React/Next.js    | `frontend-developer` or `nextjs-developer` | UI components, pages   |
| Backend API/Moleculer     | `backend-architect`                        | Services, actions      |
| TypeScript types/generics | `typescript-pro`                           | Complex type work      |
| Tests only                | `general-purpose`                          | Test writing           |
| Docs/RFC update           | `general-purpose`                          | Documentation          |

### Wave Dependency Patterns

```
Pattern A: Foundation → Features → Polish
Pattern B: Backend → Frontend → Integration
Pattern C: Parallel Domains → Integration → Tests
```

---

## STEP 3: PRESENT — Show FULL Plan to User (TEXT ONLY, NO EXECUTION!)

**THIS IS THE MOST IMPORTANT STEP. Output the ENTIRE plan as text.**

Output format — THE FULL SPRINT PROMPT with ALL sections:

```markdown
# {Title} — Sprint Plan

## Контекст

- Ветка: `{branch}`
- RFC: `{rfc-path}`
- TODO: `{todo-path}`

## Что уже сделано

✅ {completed items...}

## Оставшаяся работа

{categorized remaining tasks with LOC estimates}

## Существующие ресурсы (переиспользовать!)

| Файл | Что есть | Переиспользовать |
| ---- | -------- | ---------------- |
| ...  | ...      | ...              |

## Волны

### Wave 1 — {Name} ({N} агентов параллельно)

{full agent descriptions with files, tasks, requirements}

### Wave 2 — {Name} ({N} агентов параллельно)

{...}

### Wave N — {Name} ({N} агентов параллельно)

{...}

## Зависимости

{wave dependency graph}

## Ключевые файлы

{reference table}

## Правила

{sprint-specific rules}

## Effort Summary

| Wave | Agents | LOC | Tests | Description |
| ---- | ------ | --- | ----- | ----------- |
| ...  | ...    | ... | ...   | ...         |
```

**After outputting the full plan, ASK:**

```
---

**Sprint Plan готов. {N} волн, {M} агентов, ~{LOC} LOC, ~{tests} тестов.**

Варианты:
1. ✅ **Запускаем** — создаю TeamCreate и начинаю Wave 1
2. ✏️ **Корректировка** — скажи что поменять (добавить/убрать агентов, поменять волны, etc.)
3. 📋 **Сохранить план** — сохраню в файл для выполнения позже
4. ❌ **Отмена**
```

**DO NOT proceed until user explicitly says "запускаем" / "да" / "go" / "1"**

---

## STEP 4: EXECUTE — Wave-by-Wave via TeamCreate

> **!!! СТОП. ПЕРЕЧИТАЙ ЖЕЛЕЗНОЕ ПРАВИЛО ИЗ НАЧАЛА ФАЙЛА ПЕРЕД ВЫПОЛНЕНИЕМ. !!!**

### 4a. Team Cleanup + Creation — ОБЯЗАТЕЛЬНО, БЕЗ ИСКЛЮЧЕНИЙ

```
⛔ ЗАПРЕЩЕНО: Task() напрямую, team-lead пишет код, teammate получает чужую работу
✅ ОБЯЗАТЕЛЬНО: TeamDelete → TeamCreate → team-lead (координация) → teammates (код)
```

**Шаги:**

```
1. ПРОВЕРИТЬ существующие команды ("sprint-*", "wave-*"):
   a) Нет команды → proceed к шагу 2
   b) Команда существует → ПРОВЕРИТЬ её состояние:
      - Все teammates завершили работу? → команда ЗАКОНЧЕНА
      - Teammates не отвечают / зависли / давно нет активности? → команда ЗАВИСЛА
      - Teammates ещё работают? → команда АКТИВНА — ПОДОЖДИ или спроси пользователя
   c) СПРОСИТЬ пользователя:
      "⚠️ Обнаружена существующая команда '{name}'.
       Состояние: {закончена/зависла/активна}.
       Удалить через TeamDelete и создать новую? (да/нет)"
   d) Пользователь подтвердил → TeamDelete
   e) Пользователь отказал → спросить что делать (продолжить старую? отменить?)

2. TeamCreate: "sprint-{topic}"
   - НИКОГДА не пропускай TeamCreate — ВСЕГДА используй (НЕ raw Task() calls)
   - Даже для маленьких спринтов — координация через team-lead ОБЯЗАТЕЛЬНА

3. Структура команды:
   - team-lead = ТОЛЬКО КООРДИНАЦИЯ (НЕ пишет код, НЕ редактирует файлы, ТОЧКА)
   - teammates = ВСЯ работа (каждый в СВОЁМ процессе, СВОЙ контекст)
   - team-lead: spawn → monitor → verify → report → next wave
```

### 4a-bis. Dynamic Teammates — НОВЫЙ teammate на КАЖДУЮ доп. задачу

```
⛔ ЗАПРЕЩЕНО: добавлять работу существующему teammate
✅ ОБЯЗАТЕЛЬНО: спавнить НОВОГО teammate для каждой доп. задачи
```

**Если в процессе волны обнаружилась доп. работа:**

```
- Баг, недостающий файл, нужен компонент, рефактор, etc.
- team-lead создаёт НОВОГО teammate для этой задачи
- Новый teammate работает в СВОЁМ отдельном процессе, СВОЙ контекст
- НЕ НАГРУЖАЙ существующих teammates доп. работой — НИКОГДА
- Новый teammate получает: задача, файлы, requirements
- team-lead ждёт ALL teammates (оригинальные + новые) перед закрытием wave
```

### 4b. Team-Lead Role

Team-lead gets the FULL plan and operates as **coordinator only**:

```
You are the team lead for sprint "{title}".

!!! IRON RULE — YOUR ROLE: COORDINATE ONLY !!!
- You do NOT write code. EVER.
- You do NOT edit files. EVER.
- You do NOT run tests. EVER.
- You ONLY: spawn teammates → monitor → verify → report → next wave.
- Extra work discovered? → Spawn NEW teammate. NEVER add work to existing ones.

## Full Sprint Plan
{paste entire plan from Step 3}

## Execution Protocol

### For each Wave (sequential):

1. ANNOUNCE wave start:
   "🌊 Wave {N}/{total}: {wave name} — spawning {M} agents"

2. SPAWN all agents in this wave as teammates (parallel):
   - Each teammate gets their agent description from the plan
   - Name format: wave{N}-{agent-name}
   - Include in each prompt:
     a) Their specific task from the plan
     b) Files they own (NEW/MODIFY)
     c) What to study first
     d) Requirements
     e) "Follow CLAUDE.md project rules"
     f) "Report back when done with: files created/modified, LOC, any issues"

3. WAIT for all wave agents to complete

4. VERIFY wave results:
   - Did all agents report completion?
   - Any TS errors? (ask agents to check)
   - Any file conflicts?

5. UPDATE task overlay (send to user):
   "✅ Wave {N} complete: {summary}
    Remaining: Wave {N+1}...Wave {total}
    Next: {wave N+1 description}"

6. ASK user before proceeding to next wave:
   "Wave {N} done. Continue to Wave {N+1}? (yes / pause / abort)"

### After ALL waves complete:
1. Final verification: ask one agent to run tsc --noEmit
2. **INSIGHTS EXTRACTION** (ОБЯЗАТЕЛЬНО — см. STEP 6a)
3. Summary report to user
4. Shutdown all teammates
5. Signal completion
```

### 4c. Wave Handoff Protocol (CRITICAL for context preservation)

Between waves, team-lead sends **handoff prompt** to user:

```markdown
---
## 📊 Sprint Progress: {title}

### ✅ Completed
- Wave 1: {what was done} — {LOC} LOC, {files} files
- Wave 2: {what was done} — {LOC} LOC, {files} files

### 🔄 Current: Wave {N}
{wave description, agents, expected output}

### 📋 Remaining
- Wave {N+1}: {description}
- Wave {N+2}: {description}

### ⚠️ Issues Found
- {any issues from completed waves}

---

Продолжаем Wave {N}? Или:

- `/compact` — сжать контекст перед следующей волной
- `plan mode` — войти в план мод для ревью
- `очистить контекст` — я сохраню прогресс и дам тебе continuation prompt
```

### 4d. Token Budget Awareness

**Before each new wave, check context size:**

```
IF tokens remaining < 30% of context window:
  → WARN user:
    "⚠️ Контекст заполнен на ~{X}%. Рекомендую перед Wave {N}:

    Вариант A: /compact — сжать контекст (быстро, может потерять детали)
    Вариант B: Новый чат с continuation prompt:

    ## Continuation: {title} — Wave {N}
    Branch: {branch}
    Completed: Wave 1-{N-1} ({summary})
    Remaining: Wave {N}-{total}

    ### Wave {N} Prompt:
    {full wave N description with all agents}

    ### Files Modified So Far:
    {list of files from completed waves}

    Вариант C: Продолжить как есть (рискованно)"

IF tokens remaining < 15%:
  → FORCE save continuation prompt and suggest new chat
```

---

## STEP 5: WAVE COMPLETION — Task Overlay & Next Steps

After EACH wave, output a task overlay:

```markdown
## 📋 Sprint Task Overlay: {title}

### Progress: Wave {completed}/{total}

| Wave | Status     | Agents | LOC    | Key Output                 |
| ---- | ---------- | ------ | ------ | -------------------------- |
| 1    | ✅ Done    | 3      | ~420   | stores, hooks, types       |
| 2    | ✅ Done    | 3      | ~810   | sidebar, cmd+k, components |
| 3    | 🔄 Next    | 4      | ~1,100 | full page, admin tools     |
| 4    | ⏳ Pending | 3      | ~500   | tests, polish, docs        |

### Files Modified (cumulative)

- NEW: {list of new files}
- MODIFIED: {list of modified files}

### Key Decisions Made

- {decision 1 from Wave 1}
- {decision 2 from Wave 2}

### Next Wave: {N} — {name}

{brief description of what's next}
```

**Then propose next action:**

```
Что дальше?

1. ▶️ **Wave {N}** — запустить следующую волну
2. 🔍 **Ревью** — покажи файлы из предыдущей волны для проверки
3. 📊 **Токены** — проверить сколько контекста осталось
4. 💾 **Сохранить прогресс** — continuation prompt для нового чата
5. ⏸️ **Пауза** — остановиться, продолжить позже
```

---

## STEP 6: FINAL — Cleanup, Insights & Documentation

After ALL waves complete:

### 6a. INSIGHTS EXTRACTION (ОБЯЗАТЕЛЬНО после каждого спринта!)

**Собрать и задокументировать ВСЕ инсайты, узкие места, технический долг:**

```markdown
### В RFC файл (секция Implementation Log, после wave entry):

#### Sprint Insights & Bottlenecks

- **Архитектурные решения (ADR)**: union type cascades, local vs cross-package interfaces, DI patterns
- **Узкие места**: stale dist/, agent context overflow, cascading TS errors
- **Technical Debt**: что не успели, заглушки (stubs), что нужно доделать
- **Паттерны для переиспользования**: config chain, DI для embed, resolveLabel wrapper

### В TODO_PHASE_TWO.md (секция "Sprint Insights & Technical Debt"):

| #   | Задача | RFC | Приоритет | Почему важно |
| --- | ------ | --- | --------- | ------------ |
| 1   | ...    | ... | P1/P2     | ...          |

### В KNOWN-ISSUES.md (если обнаружены баги):

### N. Short Description

**Файл:** `path/to/file.ts:line`
**Описание:** What's happening
**Статус:** Open
**Обнаружено:** YYYY-MM-DD (Sprint context)

### В Hindsight (memory_retain):

- Все ADR + technical debt + паттерны
- Tags: sprint, RFC-XXX, insights
```

**ПРАВИЛО**: Каждый спринт ОБЯЗАН завершаться блоком инсайтов. Без этого спринт НЕ считается завершённым.

```
1. Team-lead sends final summary to user
2. **INSIGHTS EXTRACTION** — extract & document insights (see above)
3. TeamDelete — cleanup team resources
4. Update docs:
   - RFC: Implementation Log + Insights & Bottlenecks section
   - TODO files: mark [x] completed items + Sprint Insights & Technical Debt table
   - KNOWN-ISSUES.md: if bugs found
   - memory_retain(): ADR + technical debt + patterns

5. Final output:

## ✅ Sprint Complete: {title}

**Waves**: {N}/{N} | **Agents used**: {total} | **LOC**: ~{total} | **Tests**: {count}

### Deliverables
{list of what was built}

### Files Created/Modified
{cumulative list}

### Possible Next Steps
- [ ] Run full test suite: `pnpm -r test`
- [ ] Type check: `pnpm -r exec tsc --noEmit`
- [ ] Commit: `/commit`
- [ ] Code review: `/audit`
```

---

## Quick Reference: Wave Patterns

| Task Type          | Wave Pattern                                   | Waves | Agents |
| ------------------ | ---------------------------------------------- | ----- | ------ |
| Full-stack feature | Stores/Types → Backend → Frontend → Tests      | 4     | 8      |
| UI-only feature    | Stores/Hooks → Components → Pages → Tests      | 3-4   | 6-8    |
| Backend-only       | Schema/Types → Services → Actions → Tests      | 3     | 5-6    |
| Refactor           | Foundation → Migration → Integration → Cleanup | 3-4   | 6-8    |
| Bug sprint         | Research → Fixes → Verification → Docs         | 2-3   | 4-6    |

## Anti-Patterns (НАРУШЕНИЕ = ПРОВАЛ СПРИНТА)

| Anti-Pattern                              | Why Bad                               | Do Instead                                   |
| ----------------------------------------- | ------------------------------------- | -------------------------------------------- |
| **⛔ Task() вместо TeamCreate**           | **Нет координации, нет handoff**      | **ВСЕГДА TeamCreate**                        |
| **⛔ Team-lead пишет код**                | **Смешение ролей, потеря контроля**   | **Team-lead = ТОЛЬКО координация**           |
| **⛔ Доп. работа существующему teammate** | **Перегрузка, потеря фокуса**         | **НОВЫЙ teammate на каждую доп. задачу**     |
| **⛔ Два агента правят один файл**        | **Конфликты, потеря кода, TS ошибки** | **Strict File Ownership (см. ниже)**         |
| Executing without user approval           | Wrong plan, wasted tokens             | ALWAYS show plan first, wait for "запускаем" |
| >5 agents per wave                        | Token explosion                       | Split into more waves                        |
| >400 LOC per agent                        | Quality drops                         | Split agent into 2                           |
| Not checking for stale teams              | TeamCreate fails                      | TeamDelete old teams first                   |
| No task overlay between waves             | Lost context                          | ALWAYS output progress overlay               |
| Ignoring token budget                     | Context overflow mid-sprint           | Check before each wave                       |
| Not saving continuation prompt            | Lost progress on context clear        | ALWAYS offer continuation option             |
| Duplicating CLAUDE.md rules               | Wasted tokens                         | "Follow CLAUDE.md" + 3-4 specific rules      |

## Strict File Ownership (ОБЯЗАТЕЛЬНО)

> **ЖЕЛЕЗНОЕ ПРАВИЛО**: Один файл = один агент. Нарушение = конфликты + потеря кода.

### Правила

1. **Один файл = один агент** — два агента НИКОГДА не редактируют один файл параллельно
2. **Хронология зависимостей** — если агент B зависит от файла агента A, B идёт в СЛЕДУЮЩУЮ волну
3. **Shared types** (index.ts, types.ts) — один агент создаёт, остальные только читают. Barrel exports добавляет ПОСЛЕДНИЙ агент в волне
4. **Wave-based isolation** — зависимые задачи → разные волны. Независимые (разные файлы) → одна волна
5. **При конфликте** — ОСТАНОВИТЬСЯ и СПРОСИТЬ пользователя: merge вручную, откатить одного, или переделать. НИКОГДА не откатывать молча

### Как планировать волны

```
✅ ПРАВИЛЬНО — разные файлы параллельно:
Wave 1: Agent A → graph-store.ts, Agent B → convo-graph-store.ts

⛔ НЕПРАВИЛЬНО — один файл параллельно:
Wave 1: Agent A → graph-store.ts (edges), Agent B → graph-store.ts (entities)

✅ ПРАВИЛЬНО — зависимость через волны:
Wave 1: Agent A → graph-store.ts (edges + entities)
Wave 2: Agent B → recall.ts (uses edges from Wave 1)
```

### File Ownership Table (обязательно в плане спринта)

Каждый план ОБЯЗАН содержать таблицу:

```
| Agent | Files (NEW/MODIFY) | Read-only deps |
|-------|-------------------|---------------|
| agent-1 | graph-store.ts (MODIFY) | types.ts |
| agent-2 | recall.ts (MODIFY) | graph-store.ts (READ) |
| agent-3 | decay-engine.ts (NEW) | — |
```

Если два агента в одной волне имеют один файл в колонке "Files" — **СТОП, перепланировать**.
