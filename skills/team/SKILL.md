---
name: team
description: Фундаментальный скилл для запуска многоагентных команд — TeamCreate vs параллельные Task() (sub-agents), роли team-lead vs teammates, file ownership, динамический спавн новых агентов на дополнительные задачи, cleanup. Используется как база для других мульти-агентных скиллов (research, audit, sprint, wave) или напрямую, когда пользователь просит распараллелить задачу. Триггеры (EN/RU) — "create agent team", "run agents in parallel", "team up", "split work across agents", "распараллель", "запусти команду агентов", "team up", "/team-up".
---

# Agent Team Orchestration

База для запуска многоагентных команд в Claude Code. Описывает железные правила
координации, выбор режима (Agent Teams vs sub-agents), file ownership, recipes для
типовых задач. Другие мульти-агентные скиллы ([`research`](../research/SKILL.md),
[`audit`](../audit/SKILL.md), [`sprint`](../sprint/SKILL.md))
ссылаются на этот скилл — здесь живут общие правила.

---

## Когда использовать

- Задача нативно параллельна (research нескольких источников, обзор нескольких пакетов).
- Контекст одной задачи слишком велик для одного агента — нужно разделить по доменам.
- Пользователь просит «распараллель», «запусти команду», «team up».
- Используется как зависимость другими скиллами (audit, research, sprint).

## Когда НЕ использовать

- Задача линейна и помещается в один контекст — однопоточная работа быстрее.
- Изменение в одном файле / одна функция — координация дороже самой работы.
- Нет независимых блоков работы — все шаги зависят от предыдущего.

---

## Железные правила (нарушение = провал)

1. **`TeamCreate` — единственный способ запуска**, когда он доступен. Прямой `Task()` — только в fallback-режиме (Mode B).
2. **Team-lead = ТОЛЬКО координация.** Не пишет код, не редактирует файлы, не запускает тесты. Его работа — spawn → monitor → verify → report → next wave.
3. **Teammates = вся работа.** Каждый в своём процессе, со своим контекстом.
4. **Дополнительная работа → НОВЫЙ teammate.** Никогда не нагружай существующего — потеря фокуса и контекста.
5. **Перед `TeamCreate` — проверь старые команды.** Спроси пользователя перед `TeamDelete`.
6. **Один файл = один агент в волне.** Иначе — конфликты и потеря кода.

---

## Mode Selection (mandatory first step)

Перед спавном проверь, какой режим доступен:

### Mode A: Agent Teams (preferred)

**Сигнал**: `TeamCreate` / `TeamDelete` / `SendMessage` доступны (можно проверить через `ToolSearch({query: "select:TeamCreate"})`).

```
1. TeamCreate(team_name="research-{topic}")
2. Agent(prompt="...", team_name="research-{topic}", name="team-lead")
3. team-lead спавнит teammates: Agent(team_name=..., name=...)
4. Координация через SendMessage(to="...", content="...")
5. После работы: shutdown teammates → TeamDelete()
```

Преимущества: shared context, addressable агенты, team-lead oversight.

### Mode B: Sub-Agents fallback

**Сигнал**: `TeamCreate` не найден или вернул ошибку.

```
Agent(prompt="...", name="agent-a", run_in_background=true)
Agent(prompt="...", name="agent-b", run_in_background=true)
# Wait for completion notifications, synthesize in main context.
```

Без team-lead, без shared context — каждый агент получает полный контекст в своём prompt.

**Правило**: если `TeamCreate` доступен — Mode B запрещён.

---

## Workflow (5 шагов)

### Step 1: RECALL & STUDY

Перед созданием команды собери контекст:

#### 1a. Память (если есть)

Hindsight MCP (`memory_recall`), notes/, decisions/, ADR-*.md, или файлы, на которые указывает CLAUDE.md.

#### 1b. TODO / Task tracker

Найди файлы трекинга: `TODO.md`, `**/docs/TODO.md`, `KNOWN-ISSUES.md`. Большие TODO (>1000 строк) — читай через `offset`+`limit` или делегируй sub-task'у с `subagent_type: "Explore"`.

#### 1c. Source Code — ULTIMATE TRUTH

Если TODO/память противоречат коду — **верь коду**. TODO устаревает, память может быть stale.

Триангуляция:

```
1. TODO claims [x] feature X done
2. memory_recall("X") confirms
3. grep "X" src/ — VERIFY it actually exists
   → нет кода = TODO ошибается, fix the TODO
```

### Step 2: CLASSIFY — выбери recipe

| Recipe | Когда | Teammates | Стоимость |
| --- | --- | --- | --- |
| **Review Squad** | PR review, code audit | 3 (security + perf + tests) | Medium |
| **Feature Build** | Новая фича по слоям | 2–4 (backend + frontend + tests) | High |
| **Bug Hunt** | Конкурирующие гипотезы | 3–5 (каждый тестит теорию) | Medium |
| **Research** | Анализ архитектуры | 2–3 (каждый — свой угол) | Low |
| **Full-Stack Sprint** | E2E фича (DB → API → UI) | 3 (schema + API + frontend) | High |
| **Refactor Wave** | Большой рефакторинг | 2–4 (каждый — свой пакет) | High |

### Step 3: RESEARCH — собери контекст для teammates

Источники в порядке приоритета:

1. **TODO files** — что сделано, что осталось, какие gaps.
2. **RFC/design docs** — конвенции, требования. См. [`rfc`](../rfc/SKILL.md).
3. **Reference implementations** — `sources/`, `vendor/`, `node_modules/` ключевых либ.
4. **Internal packages** — `packages/*/README.md`, `src/index.ts`. Не реимплементируй то, что уже есть.
5. **Library docs** — Context7 MCP вместо web-браузинга.
6. **Memory** — past decisions, known bugs.

### Step 4: SPAWN

#### Mode A:

```typescript
// 1. Create team
TeamCreate({ team_name: "feature-auth" });

// 2. Spawn team-lead (КООРДИНАТОР, НЕ кодер)
Agent({
  prompt: TEAM_LEAD_PROMPT,
  team_name: "feature-auth",
  name: "team-lead",
  mode: "plan", // требует plan approval
});

// 3. team-lead спавнит teammates изнутри своего контекста:
Agent({
  prompt: BACKEND_DEV_PROMPT,
  team_name: "feature-auth",
  name: "backend-dev",
  mode: "bypassPermissions",
});

// 4. Координация через сообщения:
SendMessage({ to: "backend-dev", content: "Status?" });

// 5. После работы:
// shutdown each teammate, then:
TeamDelete();
```

#### Mode B:

```typescript
Agent({ prompt: PROMPT_A, name: "agent-a", run_in_background: true });
Agent({ prompt: PROMPT_B, name: "agent-b", run_in_background: true });
// Wait for notifications, synthesize.
```

---

## Teammate Prompt Template

Каждый teammate получает один и тот же шаблон с конкретикой:

```
You are {role} on team "{team-name}".

=== CONTEXT SOURCES (study BEFORE implementing) ===

1. CLAUDE.md (project root) — project rules, conventions, build commands.
2. Memory (if available): recall("{your topic}") for past decisions.
3. TODO files (large — read with offset/limit or via Task subagent): {paths}
   - [x] = done items (learn patterns), [ ] = remaining (your tasks).
4. RFCs / design docs: {relevant RFC paths or "ask user"}.
5. Reference implementations: {paths in sources/ or vendor/}.
6. Internal packages: {packages to study before implementing}.
7. Library docs: prefer Context7 MCP over web search.
8. Known issues: {KNOWN-ISSUES.md path}.

=== YOUR FILES (strict ownership) ===

NEW:
- {path1} (~{LOC})
- {path2} (~{LOC})

MODIFY:
- {path3} (~{LOC} delta)

READ-ONLY (study, don't edit):
- {path4} (depends on it)

=== YOUR TASKS ===

{task list — 5-6 concrete items, не одна гигантская задача}

=== PROJECT RULES ===

Follow CLAUDE.md. Plus, specifically for this work:
- {rule 1 — extracted from project's CLAUDE.md or RFC}
- {rule 2}
- {rule 3}

=== AFTER COMPLETION ===

Report back with:
- Files created / modified (paths + LOC)
- Tests written
- Any blockers / issues / discovered tech debt
- Whether type-check / build / tests pass

Update relevant TODO files with [x] for completed items, add [ ] for discovered gaps.
Save key learnings to memory if memory system is configured.
```

---

## Step 5: SYNTHESIZE → RETAIN → CLEANUP

После того как все teammates завершили:

1. **Synthesize** — собери reports, кросс-валидируй (consensus = high confidence; unique = verify).
2. **Retain** — сохрани в memory ключевые решения, паттерны.
3. **Update docs** — TODO files (add `[x]` + `Files Modified`), KNOWN-ISSUES.md, relevant RFC.
4. **Cleanup** —
   - Mode A: shutdown each teammate (`SendMessage(type="shutdown_request")`), затем `TeamDelete()`.
   - Mode B: дождись завершения, никаких дополнительных шагов.

---

## File Ownership (железное правило)

> **Один файл = один агент в волне.** Иначе — race condition в репо.

### Правила

1. **Один файл = один агент** — два агента НИКОГДА не редактируют один файл параллельно.
2. **Зависимости через волны** — если B зависит от файла A, B идёт в **следующую** волну.
3. **Shared types** (index.ts, types.ts) — один агент создаёт, остальные только читают; barrel exports добавляет последний агент в волне.
4. **При конфликте** — остановиться и спросить пользователя: merge вручную, откатить одного, или переделать. **Никогда** не откатывать молча.

### Таблица ownership (обязательна в плане)

```
| Agent      | Files (NEW/MODIFY)              | Read-only deps |
| ---------- | ------------------------------- | --------------- |
| agent-1    | shared/types.ts (NEW)           | —               |
| agent-2    | features/users/store.ts (NEW)   | shared/types.ts |
| agent-3    | features/users/page.tsx (NEW)   | features/users/store.ts |
```

Если у двух агентов в одной волне один файл в колонке `Files` — стоп, перепланируй.

---

## Recipes (детали)

### Recipe 1: Review Squad (3 agents)

Используется в [`audit`](../audit/SKILL.md) — там детально.

Минимум: security-reviewer + perf-reviewer + test-reviewer. Каждый изучает свой угол, потом перекрёстно валидирует.

### Recipe 2: Feature Build (3 agents)

backend-dev + frontend-dev + test-writer. Backend и tests могут идти параллельно (если контракт фиксирован), frontend — после backend types.

### Recipe 3: Bug Hunt (4 agents)

Каждый агент **тестирует свою гипотезу** и активно пытается **опровергнуть** другие. Гипотезы — auth / data / config / timing (race condition). Сходимость = подтверждение root cause.

### Recipe 4: Research (3 agents)

Codebase-analyst + reference-analyst + architect (synthesizer). Подробнее — в [`research`](../research/SKILL.md).

### Recipe 5: Refactor Wave

По одному агенту на пакет/модуль. Плюс integration-tester, который запускает type-check + tests после каждого милстоуна.

---

## Anti-Patterns (избегать!)

| Anti-Pattern | Почему плохо | Делай иначе |
|---|---|---|
| Два teammates правят один файл | Конфликты, потеря кода | Strict file ownership, разные волны |
| `Task()` напрямую в Mode A | Нет координации, нет shared context | `TeamCreate` всегда, когда доступно |
| Team-lead пишет код | Смешение ролей | Team-lead = только координация |
| Доп. работа существующему teammate | Перегрузка контекста | Новый teammate на каждую новую задачу |
| Skip memory_recall (если есть memory) | Re-doing past decisions | Recall первым шагом |
| Чтение TODO целиком (>1000 строк) | Context overflow | offset/limit или sub-task |
| Web-браузинг для library docs | Медленно, шумно | Context7 MCP |
| >5 teammates | Token explosion | 2-4 — sweet spot |
| Не сохранять learnings | Потеря знаний | memory_retain после |
| Один гигантский task на teammate | Нет чекпойнтов | 5-6 мелких задач |
| Не сверять TODO с кодом | TODO может врать | Triangulate (TODO + memory + grep) |

---

## Cleanup checklist

После завершения работы команды:

- [ ] Каждый teammate сохранил свои learnings (memory, если настроена).
- [ ] Все teammates помечены completed.
- [ ] Shutdown requests отправлены всем.
- [ ] Все shutdowns подтверждены.
- [ ] `TeamDelete()` вызван (Mode A).
- [ ] TODO файлы обновлены (`[x]` + `Files Modified`).
- [ ] KNOWN-ISSUES.md обновлён, если найдены баги.
- [ ] Relevant RFC обновлён (Implementation Log + Phase Progress) — см. [`rfc`](../rfc/SKILL.md).
- [ ] Изменения готовы к ревью (diff осмотрен).

---

## Связанные скиллы

- [`research`](../research/SKILL.md) — research recipe (5 агентов).
- [`audit`](../audit/SKILL.md) — review squad (4-6 экспертов).
- [`sprint`](../sprint/SKILL.md) — wave-based execution на этом фундаменте.
- [`do`](../do/SKILL.md) — мета-оркестратор, выбирает между этими скиллами.
- [`rfc`](../rfc/SKILL.md) — обновление RFC после команды.
