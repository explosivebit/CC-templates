---
description: Quick wave-based execution from CURRENT chat context. No research — uses what's already discussed. Generates plan → approve → Agent Teams wave-by-wave.
argument-hint: '[optional: wave description or task focus — uses chat context if omitted]'
---

# /wave — Execute Waves from Current Context

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

**Lightweight version of `/sprint`.** Skips research phase — uses whatever context is already in the chat (prior research, discussion, file reads, etc.) to generate a wave plan and execute it.

**Use when**: You've already discussed/researched the task and now need structured execution.
**Use `/sprint` instead when**: Starting from scratch, no prior context in chat.

Examples:

- `/wave` — generate plan from everything discussed so far
- `/wave Phase 5 Command Center — 4 волны, sidebar + cmd+k + assistant + polish`
- `/wave backend actions for ontology CRUD — 2 волны`
- `/wave оставшиеся задачи из TODO`

---

## STEP 1: EXTRACT — Build Context from Chat (NO external research)

**DO NOT launch Explore agents or research sub-tasks.**

Instead, extract from the CURRENT conversation:

1. **Scan chat history** for:
   - Files that were read/discussed
   - Tasks/TODOs mentioned
   - Architecture decisions made
   - RFC references
   - Existing code patterns identified
   - User requirements/preferences

2. **Quick local checks** (fast, no sub-agents):
   - `git branch --show-current` — current branch
   - Glob/Grep ONLY if needed to confirm a specific file exists
   - Read 1-2 files ONLY if directly referenced and not yet read

3. **Build context summary**:
   ```
   Branch: {from git}
   Task: {from chat discussion}
   What's done: {from chat — checkboxes, completed items}
   What remains: {from chat — discussed tasks}
   Key files: {from chat — files read/mentioned}
   Constraints: {from chat — user preferences, decisions}
   ```

---

## STEP 2: GENERATE — Build Wave Plan

Using chat context + sprint-template.md format, generate the plan.

### Sizing Rules

| Chat context size  | Waves | Agents total |
| ------------------ | ----- | ------------ |
| Small (1-3 tasks)  | 1-2   | 2-4          |
| Medium (4-8 tasks) | 2-3   | 4-6          |
| Large (9+ tasks)   | 3-5   | 5-8          |

### Agent Description Format (compact — 80 words max)

```
**Agent {i}: `{name}`** (subagent_type: `{type}`)
- Файлы: {NEW/MODIFY} `{path}` (~{LOC})
- Задача: {one-line}
  - Изучить: {files to read}
  - Создать: {what to build}
  - Requirements: {constraints}
```

---

## STEP 3: PRESENT — Show Full Plan, Ask for Approval

**Output the COMPLETE plan as text.** Follow sprint-template.md structure:

```markdown
# {Title} — Wave Plan

## Контекст

- Ветка: `{branch}`
- Источник: текущий чат (context from discussion)

## Задачи

{extracted from chat}

## Существующие ресурсы

| Файл | Что есть | Переиспользовать |
| ---- | -------- | ---------------- |
| ...  | ...      | ...              |

## Волны

### Wave 1 — {Name} ({N} агентов)

{agent descriptions}

### Wave 2 — {Name} ({N} агентов)

{agent descriptions}

## Зависимости

Wave 1 → Wave 2 → ...

## Правила

1. Каждый агент ТОЛЬКО свои файлы
2. Follow CLAUDE.md project rules
3. {sprint-specific from chat context}
4. 0 новых TS ошибок

## Effort Summary

| Wave | Agents | LOC | Tests | Description |
| ---- | ------ | --- | ----- | ----------- |
```

**Then ask:**

```
---
**Wave Plan готов. {N} волн, {M} агентов, ~{LOC} LOC.**

1. ✅ **Запускаем** — TeamCreate → Wave 1
2. ✏️ **Корректировка** — скажи что поменять
3. 📋 **Сохранить** — сохраню план в файл
4. ❌ **Отмена**
```

**WAIT for user approval. Do NOT execute until "запускаем" / "да" / "1".**

---

## STEP 4: EXECUTE — TeamCreate + Wave-by-Wave

> **!!! СТОП. ПЕРЕЧИТАЙ ЖЕЛЕЗНОЕ ПРАВИЛО ИЗ НАЧАЛА ФАЙЛА ПЕРЕД ВЫПОЛНЕНИЕМ. !!!**

### 4a. Team Setup — ОБЯЗАТЕЛЬНО, БЕЗ ИСКЛЮЧЕНИЙ

```
⛔ ЗАПРЕЩЕНО: Task() напрямую, team-lead пишет код, teammate получает чужую работу
✅ ОБЯЗАТЕЛЬНО: TeamDelete → TeamCreate → team-lead (координация) → teammates (код)
```

**Шаги:**

```
1. ПРОВЕРИТЬ существующие команды ("wave-*", "sprint-*"):
   a) Нет команды → proceed к шагу 2
   b) Команда существует → ПРОВЕРИТЬ её состояние:
      - Все teammates завершили? → ЗАКОНЧЕНА
      - Не отвечают / зависли? → ЗАВИСЛА
      - Ещё работают? → АКТИВНА — подожди или спроси пользователя
   c) СПРОСИТЬ пользователя:
      "⚠️ Обнаружена команда '{name}'. Состояние: {статус}.
       Удалить через TeamDelete? (да/нет)"
   d) Подтвердил → TeamDelete | Отказал → спросить что делать

2. TeamCreate: "wave-{topic}"
   - НИКОГДА не используй Task() напрямую — ТОЛЬКО TeamCreate
   - team-lead = ТОЛЬКО КООРДИНАЦИЯ (НЕ пишет код, НЕ редактирует файлы, ТОЧКА)
   - teammates = ВСЯ работа (каждый в СВОЁМ процессе, СВОЙ контекст)

3. Dynamic teammates — НОВЫЙ teammate на КАЖДУЮ доп. задачу:
   - Баг, недостающий файл, нужен компонент? → НОВЫЙ teammate
   - ЗАПРЕЩЕНО добавлять работу существующему teammate — НИКОГДА
   - Новый teammate = отдельный процесс, свой контекст, свои файлы
   - Team-lead ждёт ALL teammates (оригинальные + новые) перед закрытием wave
```

### 4b. Team-Lead Prompt

```
You are the team lead for wave execution "{title}".

!!! IRON RULE — YOUR ROLE: COORDINATE ONLY !!!
- You do NOT write code. EVER.
- You do NOT edit files. EVER.
- You do NOT run tests. EVER.
- You ONLY: spawn teammates → monitor → verify → report → next wave.
- Extra work discovered? → Spawn NEW teammate. NEVER add work to existing ones.

## Plan
{full plan from Step 3}

## Protocol

For EACH wave:

1. ANNOUNCE: "🌊 Wave {N}/{total}: {name} — {M} agents"

2. SPAWN all wave agents as teammates (parallel).
   Each teammate prompt includes:
   - Their task from the plan (files, study, create, requirements)
   - "Follow CLAUDE.md project rules"
   - "Report when done: files created/modified, LOC, issues"

3. WAIT for all agents to complete.

4. VERIFY: ask one agent to check for TS errors if relevant.

5. REPORT to user with task overlay:

   📊 Sprint Progress: {title}
   ✅ Wave {N}: {summary} — {LOC} LOC, {files} files
   📋 Remaining: Wave {N+1}...
   ⚠️ Issues: {any}

6. ASK before next wave:
   "Wave {N} done. Next?"
   - ▶️ Wave {N+1}
   - 🔍 Ревью файлов
   - 📊 Проверить токены
   - 💾 Continuation prompt
   - ⏸️ Пауза

### Token Budget Check (before each wave):
IF context is getting large:
  → Suggest /compact or continuation prompt
  → Provide continuation prompt text if user wants new chat

### After ALL waves:
1. **INSIGHTS EXTRACTION** (ОБЯЗАТЕЛЬНО!):
   - Собрать: ADR, узкие места, tech debt, паттерны для переиспользования
   - Записать в RFC (Implementation Log → "Sprint Insights & Bottlenecks")
   - Записать в TODO_PHASE_TWO.md (секция "Sprint Insights & Technical Debt")
   - Записать в KNOWN-ISSUES.md (если обнаружены баги)
   - Отдельный блок в финальном отчёте пользователю
2. memory_retain(): ADR + tech debt + patterns + insights
3. Final summary (включая блок "Insights & Technical Debt")
4. TeamDelete
```

### 4c. Task Overlay (after each wave)

```markdown
## 📋 Wave Progress: {title}

| Wave | Status | Agents | LOC  | Output        |
| ---- | ------ | ------ | ---- | ------------- |
| 1    | ✅     | 3      | ~400 | stores, hooks |
| 2    | 🔄     | 3      | ~800 | components    |
| 3    | ⏳     | 2      | ~300 | tests         |

### Files Modified

- NEW: {list}
- MODIFIED: {list}

### Next: Wave {N} — {description}
```

---

## STEP 5: COMPLETION

```markdown
## ✅ Wave Execution Complete: {title}

**Waves**: {N}/{N} | **LOC**: ~{total} | **Tests**: {count}

### Deliverables

{what was built}

### Next Steps

- [ ] `pnpm -r exec tsc --noEmit` — type check
- [ ] `pnpm -r test` — run tests
- [ ] `/commit` — commit changes
- [ ] `/audit` — code review
```

---

## /wave vs /sprint — Decision Guide

```
У тебя уже есть контекст в чате?
  ├── ДА → /wave (быстрый — пропускает research)
  │    ├── Обсуждали задачу → /wave
  │    ├── Читали RFC/TODO → /wave
  │    └── Делали /research → /wave
  │
  └── НЕТ → /sprint (полный — делает research)
       ├── Новая задача → /sprint [task]
       └── Начало сессии → /sprint [RFC-XXX]
```
