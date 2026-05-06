---
name: sprint
description: Волновое исполнение фичи/задачи многоагентной командой — research → план волн (5-8 агентов в 2-5 волнах) → approval → wave-by-wave спавн teammates через TeamCreate. Поддерживает два режима — full sprint (с research-фазой) и lightweight wave (использует контекст текущего чата). Каждая волна — независимая параллельная работа агентов с строгим file ownership; зависимые задачи — в следующей волне. Используется для имплементации больших фич, refactor sprint'ов, milestone'ов. Триггеры (EN/RU) — "sprint", "wave plan", "implement feature in waves", "запусти спринт", "распланируй волны", "реализуй фичу", "implement RFC-XXX", "/sprint", "/wave".
---

# Wave-Based Sprint Execution

Волновое исполнение задач — research, план, approval, wave-by-wave запуск teammates.
Объединяет два режима: **full sprint** (research-first) и **lightweight wave** (использует
контекст чата). Опирается на [`team`](../team/SKILL.md)
и при необходимости — на [`research`](../research/SKILL.md).

---

## Когда использовать

- Большая фича / RFC, требующая 5-8+ агентов и 2-5 волн.
- Рефакторинг с явными слоями зависимостей.
- Milestone из множества подзадач, которые можно частично распараллелить.
- Пользователь сказал: «sprint», «wave», «реализуй», «implement RFC-XXX», «запусти волны».

## Когда НЕ использовать

- Точечный фикс (1 файл, 1 функция) — single agent.
- Чистый research без планов имплементации — [`research`](../research/SKILL.md).
- Code review — [`audit`](../audit/SKILL.md).

---

## Два режима

| Режим | Когда | Step 1 | Step 2 |
|---|---|---|---|
| **Full Sprint** | Свежая задача, контекст пуст или мал | Research через [`research`](../research/SKILL.md) (3 параллельных Explore агента) | Generate plan |
| **Lightweight Wave** | Уже обсудили задачу, контекст наполнен | Extract context из чата (не запускать research) | Generate plan |

Все остальные шаги — общие.

---

## Железные правила (НАРУШЕНИЕ = ПРОВАЛ)

> Эти правила пришли из [`team`](../team/SKILL.md).
> Здесь — критический минимум, который **обязан** быть в каждом плане.

1. **`TeamCreate` — единственный способ запуска.** `Task()` напрямую — запрещено.
2. **Team-lead = только координация.** НЕ пишет код, НЕ редактирует файлы, НЕ запускает тесты. Только: spawn → monitor → verify → report → next wave.
3. **Teammates = вся работа.** Каждый в своём процессе, со своим контекстом.
4. **Доп. работа → НОВЫЙ teammate.** Никогда не нагружай существующего.
5. **Перед `TeamCreate` — проверь существующие команды.** Спроси пользователя перед `TeamDelete`.
6. **Один файл = один агент в волне.** Зависимые задачи — в следующей волне.

---

## Step 1: Research / Extract context

### Full Sprint (default)

3 параллельных Explore агента:

```
Agent R1: Read RFC + TODO
  → Read referenced RFC (if any)
  → Read relevant TODO sections (offset/limit)
  → Extract: completed phases, remaining work, blockers

Agent R2: Scan codebase
  → Glob/Grep for files related to scope
  → Map: existing, reusable, file ownership
  → Note patterns from similar modules

Agent R3: Memory + known issues
  → memory_recall("{topic}") если доступно
  → Read KNOWN-ISSUES.md
  → Recent git log for context
```

(Можно делегировать [`research`](../research/SKILL.md) для глубокого варианта.)

### Lightweight Wave

**НЕ запускай Explore агентов.** Извлеки из чата:

- Файлы, которые читали / обсуждали.
- Tasks / TODO упомянутые.
- Архитектурные решения принятые.
- RFC references.
- User preferences / requirements.

Плюс быстрые локальные проверки:

```bash
git branch --show-current
# Glob/Grep ТОЛЬКО для подтверждения конкретного файла
# Read 1-2 файла ТОЛЬКО если упомянуты и ещё не прочитаны
```

### Контекст-сводка (общая)

```
Branch: {git}
Task: {что делаем}
Done: {checkboxes из RFC/TODO}
Remaining: {что осталось}
Key files: {из чата или research}
Constraints: {из CLAUDE.md, RFC, user preferences}
```

---

## Step 2: Generate FULL TEXT PLAN

### Sizing rules

| Контекст | Волны | Агентов всего |
|---|---|---|
| Small (1-3 tasks) | 1-2 | 2-4 |
| Medium (4-8 tasks) | 2-3 | 4-6 |
| Large (9+ tasks) | 3-5 | 5-8 |

**Жёсткие лимиты**:

- Max **5 волн**.
- Max **5 агентов в волне**.
- Max **400 LOC на агента** (>400 — разбей на 2 агента).
- Min **100 LOC на агента** (<100 — объедини с другим).

### Agent Description Format

```
**Agent {i}: `{kebab-name}`** (subagent_type: `{type}`)
- Файлы: NEW/MODIFY
  - `{path}` (~{LOC})
- Задача: {one-line}
  - Изучить: {2-4 файлов FIRST}
  - Создать: {bullet points}
  - Requirements: {2-4 constraints}
```

### Subagent type selection

| Тип задачи | subagent_type |
|---|---|
| Generic implementation | `general-purpose` |
| Frontend (React/Vue/etc) | `frontend-developer` / `nextjs-developer` |
| Backend / API / services | `backend-architect` / `microservices-architect` |
| TypeScript types | `typescript-pro` |
| Tests | `general-purpose` или `tester` |
| Docs | `documentation-engineer` |

(Адаптируй под доступные subagent types в репо `agents/`.)

### Wave dependency patterns

- **Foundation → Features → Polish**
- **Backend → Frontend → Integration**
- **Parallel Domains → Integration → Tests**

Внутри волны — параллельно. Между волнами — sequential, dependency через файлы.

---

## Step 3: Present plan, wait for approval

> **КРИТИЧНО**: вывод плана как **текст**. Никакого исполнения, пока user не сказал «запускаем».

```markdown
# {Title} — Sprint/Wave Plan

## Контекст
- Ветка: `{branch}`
- RFC: `{path}` (если есть)
- TODO: `{path}` (с line range, если знаем)

## Что уже сделано
✅ {item 1} ({summary — LOC, tests, deliverables})
✅ {item 2} (...)

## Оставшаяся работа

### {Category 1}: {name} (~{LOC})
- {sub-task} (~{LOC})

### {Category 2}: {name}
- [ ] {task} (~{LOC}) — `{file-path}`

## Существующие ресурсы (изучить!)

| Файл | Что есть | Переиспользовать |
|---|---|---|
| `{path}` | {desc} | {how} |

## Волны

### Wave 1 — {Name}: {summary} ({M} агентов параллельно)

**Agent 1: `{name}`** (subagent_type: `{type}`)
- Файлы: NEW
  - `{path}` (~{LOC})
- Задача: ...
  - Изучить: ...
  - Создать: ...
  - Requirements: ...

**Agent 2: `{name}`** (...)
...

### Wave 2 — ... (same pattern)

## File Ownership

| Agent | Files (NEW/MODIFY) | Read-only deps |
|---|---|---|
| agent-1 | shared/types.ts (NEW) | — |
| agent-2 | features/store.ts (NEW) | shared/types.ts |
| agent-3 | features/page.tsx (NEW) | features/store.ts |

(Если у двух агентов в одной волне один файл — стоп, перепланируй.)

## Зависимости

Wave 1: [agent-a] [agent-b] [agent-c] — параллельно
                ↓
Wave 2: [agent-d] [agent-e] — параллельно
       ↑ depends on {что из wave 1}

## Ключевые файлы

| Файл | Зачем |
|---|---|
| `{path}` | reason |

## Правила

1. Каждый агент — ТОЛЬКО свои файлы.
2. Follow CLAUDE.md project rules.
3. {sprint-specific rule from research / chat}
4. 0 новых type-check ошибок.

## Effort Summary

| Wave | Agents | LOC | Tests | Description |
|---|---|---|---|---|
| 1 | 3 | ~420 | 12 | Foundation |
| 2 | 3 | ~810 | 18 | Features |
```

После плана — **спроси**:

```
---

**Plan готов. {N} волн, {M} агентов, ~{LOC} LOC, ~{tests} тестов.**

Варианты:
1. ✅ Запускаем — TeamCreate → Wave 1
2. ✏️ Корректировка — скажи что поменять
3. 📋 Сохранить план в файл
4. ❌ Отмена
```

**НЕ продолжай** до явного «запускаем» / «да» / «go» / «1».

---

## Step 4: Execute wave-by-wave

### 4a. Setup

```
1. ПРОВЕРИТЬ существующие команды:
   - Если есть "sprint-*" / "wave-*" — проверь состояние:
     · все teammates завершили? → ЗАКОНЧЕНА
     · не отвечают / зависли? → ЗАВИСЛА
     · ещё работают? → АКТИВНА (подожди или спроси)
   - СПРОСИ пользователя: "Команда '{name}' — {статус}. Удалить через TeamDelete?"
   - Подтвердил → TeamDelete | Отказал → спроси что делать
2. TeamCreate(team_name="sprint-{topic}" или "wave-{topic}")
3. team-lead = ТОЛЬКО координация
4. teammates = вся работа
```

### 4b. Team-lead prompt

```
You are the team lead for "{title}".

!!! IRON RULE — YOUR ROLE: COORDINATE ONLY !!!
- You do NOT write code. EVER.
- You do NOT edit files. EVER.
- You do NOT run tests. EVER.
- You ONLY: spawn teammates → monitor → verify → report → next wave.
- Extra work discovered? → Spawn NEW teammate. NEVER add to existing.

## Full Plan
{plan from Step 3}

## Execution Protocol

For each Wave (sequential):

1. ANNOUNCE: "🌊 Wave {N}/{total}: {wave name} — spawning {M} agents"

2. SPAWN all wave agents as teammates (parallel).
   Each teammate prompt includes:
   a) Their specific task from plan
   b) Files they own (NEW/MODIFY)
   c) What to study FIRST
   d) Requirements
   e) "Follow CLAUDE.md project rules"
   f) "Report back: files created/modified, LOC, issues"

3. WAIT for all wave agents to complete.

4. VERIFY:
   - Did all agents report completion?
   - Any type-check errors? (ask one agent to run typecheck)
   - Any file conflicts?

5. UPDATE task overlay (send to user):
   "✅ Wave {N} complete: {summary}
    Remaining: Wave {N+1}..."

6. ASK user: "Wave {N} done. Continue to Wave {N+1}? (yes / pause / abort)"

After ALL waves:
1. Final verification (typecheck/build/tests).
2. INSIGHTS EXTRACTION (mandatory — see Step 6).
3. Summary report.
4. Shutdown teammates.
5. Signal completion.
```

### 4c. Dynamic teammates

Если в процессе волны обнаружилась доп. работа (баг, недостающий файл, нужен компонент):

```
- Team-lead создаёт НОВОГО teammate для этой задачи
- Новый teammate работает в СВОЁМ процессе, СВОЙ контекст
- НЕ нагружай существующих
- Team-lead ждёт ALL teammates (оригинальные + новые) перед закрытием wave
```

### 4d. Wave handoff

Между волнами — task overlay для пользователя:

```markdown
---
## 📊 Sprint Progress: {title}

### ✅ Completed
- Wave 1: {summary} — {LOC} LOC, {N} files
- Wave 2: ...

### 🔄 Current: Wave {N}
{description, agents, expected output}

### 📋 Remaining
- Wave {N+1}: {description}

### ⚠️ Issues
- {any from completed waves}

---

Продолжаем Wave {N}? Или:
- `/compact` — сжать контекст
- `plan mode` — войти в plan mode
- «очистить контекст» — сохрани прогресс и дай continuation prompt
```

### 4e. Token budget awareness

Перед каждой новой волной:

```
IF tokens remaining < 30%:
  WARN user:
    "⚠️ Контекст ~{X}% заполнен. Перед Wave {N}:
     A. /compact — сжать (быстро, теряет детали)
     B. Новый чат с continuation prompt:

     ## Continuation: {title} — Wave {N}
     Branch: {branch}
     Completed: Wave 1-{N-1} ({summary})
     Remaining: Wave {N}-{total}

     ### Wave {N} Prompt: {full description}
     ### Files Modified So Far: {list}

     C. Продолжить как есть (рискованно)"

IF tokens remaining < 15%:
  → FORCE save continuation prompt, suggest new chat.
```

---

## Step 5: Wave completion overlay

После каждой волны:

```markdown
## 📋 Sprint Task Overlay: {title}

### Progress: Wave {N}/{total}

| Wave | Status | Agents | LOC | Output |
|---|---|---|---|---|
| 1 | ✅ Done | 3 | ~420 | stores, hooks, types |
| 2 | ✅ Done | 3 | ~810 | sidebar, cmd+k, components |
| 3 | 🔄 Next | 4 | ~1100 | full page, admin tools |
| 4 | ⏳ Pending | 3 | ~500 | tests, polish, docs |

### Files Modified (cumulative)
- NEW: {list}
- MODIFIED: {list}

### Key Decisions
- {decision 1}
- {decision 2}

### Next Wave: {N} — {name}
{brief description}
```

Затем варианты:

```
1. ▶️ Wave {N} — следующая волна
2. 🔍 Ревью — покажи файлы предыдущей волны
3. 📊 Токены — проверить сколько осталось
4. 💾 Сохранить прогресс — continuation prompt
5. ⏸️ Пауза
```

---

## Step 6: Final — Insights Extraction (MANDATORY)

После завершения ВСЕХ волн команда **обязана** извлечь и задокументировать инсайты.
**Без этого спринт не считается завершённым.**

### Что собрать

- **Архитектурные решения (ADR)** — что и почему выбрали.
- **Узкие места** — context overflow, cascading errors, stale build.
- **Tech debt** — что не успели, заглушки, что доделать.
- **Паттерны для переиспользования** — что родилось хорошее, копируется.

### Куда записать

1. **RFC / design doc** (если есть) — секция `Implementation Log` → `Sprint Insights & Bottlenecks`. См. [`rfc`](../rfc/SKILL.md).
2. **TODO files** — секция `Sprint Insights & Technical Debt`:

   ```markdown
   | # | Задача | RFC/Ref | Приоритет | Почему важно |
   | - | ------ | ------- | --------- | ------------ |
   | 1 | ...    | ...     | P1/P2     | ...          |
   ```

3. **KNOWN-ISSUES.md** (если найдены баги):

   ```markdown
   ### N. {Short Description}
   **Файл:** `path/to/file:line`
   **Описание:** ...
   **Статус:** Open
   **Обнаружено:** YYYY-MM-DD ({Sprint context})
   ```

4. **Memory** (если доступна): `memory_retain` ADR + tech debt + patterns + insights.

### Final output

```markdown
## ✅ Sprint Complete: {title}

**Waves**: {N}/{N} | **Agents**: {total} | **LOC**: ~{total} | **Tests**: {count}

### Deliverables
{что построили}

### Files Created/Modified
{cumulative list}

### Insights & Tech Debt
{extracted, см. выше}

### Possible Next Steps
- [ ] Run full test suite
- [ ] Type-check
- [ ] Commit
- [ ] Audit (см. [`audit`](../audit/SKILL.md))
```

---

## Wave Patterns Quick Reference

| Тип | Pattern | Волны | Агентов |
|---|---|---|---|
| Full-stack feature | Stores/Types → Backend → Frontend → Tests | 4 | 8 |
| UI-only | Stores/Hooks → Components → Pages → Tests | 3-4 | 6-8 |
| Backend-only | Schema/Types → Services → Actions → Tests | 3 | 5-6 |
| Refactor | Foundation → Migration → Integration → Cleanup | 3-4 | 6-8 |
| Bug sprint | Research → Fixes → Verification → Docs | 2-3 | 4-6 |

---

## Anti-Patterns (нарушение = провал спринта)

| Anti-Pattern | Почему | Делай иначе |
|---|---|---|
| ⛔ `Task()` вместо `TeamCreate` | Нет координации, нет handoff | ВСЕГДА `TeamCreate` |
| ⛔ Team-lead пишет код | Смешение ролей, потеря контроля | Team-lead = ТОЛЬКО координация |
| ⛔ Доп. работа существующему teammate | Перегрузка, потеря фокуса | НОВЫЙ teammate на каждую доп. задачу |
| ⛔ Два агента правят один файл | Конфликты, потеря кода | Strict file ownership |
| Execute без user approval | Wrong plan, wasted tokens | ВСЕГДА показывай план, жди «запускаем» |
| >5 агентов в волне | Token explosion | Раздели на больше волн |
| >400 LOC на агента | Качество падает | Раздели на 2 |
| Не проверять stale teams | TeamCreate fails | Сначала TeamDelete старых |
| Нет task overlay между волнами | Lost context | ВСЕГДА overlay |
| Игнор token budget | Overflow посреди sprint | Проверяй перед каждой волной |
| Дублирование CLAUDE.md правил | Wasted tokens | "Follow CLAUDE.md" + 3-4 specific |
| Skip insights extraction | Знания теряются | INSIGHTS — обязательны |

---

## Связанные скиллы

- [`team`](../team/SKILL.md) — фундамент (Mode A/B, file ownership, recipes).
- [`research`](../research/SKILL.md) — research-фаза full sprint'а.
- [`audit`](../audit/SKILL.md) — после спринта — audit.
- [`rfc`](../rfc/SKILL.md) — Implementation Log + Insights пишутся в RFC.
- [`do`](../do/SKILL.md) — чейнит всё вместе.
- [`build`](../build/SKILL.md) — если уже есть готовый research report с IMPLEMENTATION-PLAN.md.
- [`restore`](../restore/SKILL.md) — на старте сессии перед спринтом.

## Decision Guide: full sprint vs lightweight wave

```
У тебя уже есть контекст в чате?
  ├── ДА → lightweight wave (skip research, generate plan)
  │    ├── Обсуждали задачу → wave
  │    ├── Читали RFC/TODO → wave
  │    └── Делали research → wave
  │
  └── НЕТ → full sprint (research + plan)
       ├── Новая задача → full sprint
       └── Старт сессии после паузы → restore, потом full sprint
```
