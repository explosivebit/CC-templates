---
name: audit
description: Многоэкспертный аудит кода / архитектуры / завершённой фичи — минимум 4 параллельных агента-ревьюера со специализациями (логика, архитектура/SOLID, типизация, безопасность; опционально — тесты, бэкенд-паттерны, фронтенд, task-completion). Каждый — со своим чек-листом. Финал — кросс-валидация, score, verdict, action plan. Используется, когда пользователь хочет «чёткую вторую пару глаз» на код, PR, branch diff, спринт. Триггеры (EN/RU) — "audit", "review", "проверь код", "ревью", "оцени качество", "всё ли правильно", "code audit", "expert review", "/audit".
---

# Multi-Expert Audit

Панель из ≥4 агентов с разными скиллами проверяет код одновременно. Опирается на
[`team`](../team/SKILL.md) (Mode A/B,
cleanup) — здесь живёт audit-recipe и чек-листы доменов.

---

## Когда использовать

- Готова фича / спринт / PR — нужна тщательная проверка.
- Пользователь говорит: «проверь», «ревью», «аудит», «оцени качество», «всё ли правильно», "review", "audit".
- Перед мерджем большой ветки.
- После реализации по RFC — нужно сверить «сделали vs. просили».

## Когда НЕ использовать

- Несколько строк кода — линтера/типчекера достаточно.
- Просто синтаксический фикс — code-reviewer как single agent.
- Только архитектурный совет, без чтения кода — single agent с `architect-reviewer`.

---

## Core Rule: минимум 4 агента

Каждый аудит = **минимум 4 специализированных агента**, выполняющих параллельно.
Меньше — это не аудит, а point review. Больше 6 — token explosion.

---

## Архитектура (4 фазы)

| Фаза | Что делает |
|---|---|
| **1. Scope Analysis** | Определи что именно проверяем; найди оригинальную постановку (RFC/TODO/issue); выбери панель |
| **2. Parallel Review** | Запусти 4–6 агентов параллельно через TeamCreate |
| **3. Task Completion Check** | Сверь «сделано vs. просили» |
| **4. Synthesis & Verdict** | Кросс-валидация, score, verdict, action plan |

---

## Фаза 1: Scope Analysis

### 1a. Что проверяем

Парсинг `$ARGUMENTS`:

| Сигнал | Действие |
|---|---|
| Конкретные файлы | Read их целиком, передай в prompts |
| Фича / модуль | Glob + Grep, собери все relevant files |
| «последние изменения» | `git diff HEAD~1` или `git diff --staged` |
| `PR #N` | `gh pr diff N` |
| RFC reference | Найди RFC файл, извлеки phases/tasks |
| «спринт» / «sprint X» | Найти все файлы изменённые за спринт |

### 1b. Найти оригинальную задачу (для Phase 3)

Источник «что просили»:

- RFC / design doc — секция Phase / Implementation TODO.
- TODO file — конкретные `[x]/[ ]` items по теме.
- Sprint plan (если был [`sprint`](../sprint/SKILL.md)).
- Имя ветки (часто содержит RFC/issue).
- GitHub Issue / Linear ticket (если упомянут).

Если ничего не найдено — Phase 3 пропусти, отметь в финальном отчёте.

### 1c. FILE_LIST

До 30 файлов. Для файлов >500 строк — пропусти только релевантные секции (или оригинальный diff).

### 1d. Выбор панели (минимум 4, максимум 6)

#### Обязательные 4 — всегда:

| # | Имя агента | subagent_type (примеры) | Фокус | Чек-лист (см. ниже) |
|---|---|---|---|---|
| 1 | `logic-reviewer` | `code-reviewer` / `general-purpose` | Логика + бизнес-корректность | Алгоритмы, edge cases, race conditions, idempotency |
| 2 | `arch-reviewer` | `architect-reviewer` / `architect-review` | SOLID + архитектура | DI, dependency direction, patterns, over-engineering |
| 3 | `type-reviewer` | `typescript-pro` / `typescript-type-auditor` или (для других языков) `general-purpose` | Типизация / type safety | `any`/casts/non-null, generic constraints, schema↔type alignment |
| 4 | `security-reviewer` | `security-auditor` / `security-expert` | Безопасность + error handling | OWASP, injection, PII, swallowed errors, DoS |

Для нет-TS проектов — Type-reviewer становится `lint-reviewer` (статический анализ, mypy/clippy/etc).

#### Опциональные (по scope):

| # | Имя | Когда |
|---|---|---|
| 5 | `test-reviewer` | Есть тесты или они должны быть |
| 6 | `backend-reviewer` (`backend-architect` / `microservices-architect`) | Бэкенд-сервисы, inter-service, persistence |
| 7 | `frontend-reviewer` (`frontend-developer` / `nextjs-developer`) | UI, state, UX |
| 8 | `task-reviewer` (`general-purpose`) | Есть RFC/TODO с явным чек-листом — нужна верификация полноты |

### 1e. Матрица выбора

| Scope | Панель (≥4) |
|---|---|
| Backend feature | logic + arch + type + security + test (5) |
| Full-stack feature | logic + arch + type + security + frontend + test (6) |
| Microservices | logic + arch + type + security + backend (5) |
| Только types/interfaces | logic + arch + type + security (4) |
| Sprint/RFC completion | logic + arch + type + security + test + task (6) |
| Quick review | logic + arch + type + security (4) |

---

## Фаза 2: Parallel Review

`TeamCreate(team_name="audit-{scope}")` + параллельный спавн всех агентов в одном message.

### Шаблон промпта (общий)

```
## Expert Audit Assignment

**Role**: {ваша специализация}
**Scope**: {file list}
**Context**: {что собиралось / менялось}
**Original Task**: {RFC/TODO ref — что просили}

### Task
Review the code from YOUR expert perspective. Be CRITICAL but fair.
Read every file carefully. Focus on your domain expertise.

### Files to Review
{actual file contents pasted here}

### Domain Checklist (your area)
{domain-specific checklist — see below}

### IMPORTANT: Task Completion Check
Compare what was IMPLEMENTED against what was REQUESTED.
List items as:
- ✅ Done correctly
- ⚠️ Done but with issues
- ❌ Not done / missing
- 🔄 Done differently than requested (explain)

### Output Format (STRICT)

## {Your Role} Review

### Score: X/10

### Task Completion
- ✅ ...
- ⚠️ ...
- ❌ ...

### Critical Issues (must fix)
- [C1] file.ts:line — Description. Fix: what to do.

### Warnings (should fix)
- [W1] file.ts:line — Description. Suggestion: ...

### Positive Findings
- [P1] ...

### Verdict
ONE of: APPROVE | APPROVE_WITH_FIXES | REQUEST_CHANGES | REJECT

### Key Recommendation (1-2 sentences)
```

### Domain Checklists

#### logic-reviewer

- Алгоритмическая корректность.
- Edge cases: null, undefined, empty, 0, negative, very large.
- Race conditions: concurrent access, shared mutable state.
- Off-by-one, boundary conditions.
- Fire-and-forget — ошибки не теряются молча?
- Кеширование: invalidation, stale data, thundering herd.
- Идемпотентность: повторный вызов безопасен?
- Resource cleanup (listeners, timers, connections, file handles).

#### arch-reviewer (SOLID + Architecture)

- **S**: Single Responsibility.
- **O**: Open/Closed — расширение без модификации.
- **L**: Liskov Substitution.
- **I**: Interface Segregation — интерфейсы не раздуты.
- **D**: Dependency Inversion — на абстракции, не на конкретные классы.
- DI через конструкторы, нет monkey-patching.
- Direction: нет circular deps.
- Over-engineering vs under-engineering.
- Consistency с существующими паттернами кодовой базы (изучить аналогичные модули).
- Error model — типизированные ошибки vs generic exceptions.

#### type-reviewer (TS / Rust / Python с type hints / etc.)

- `any` / `unknown` — каждый `any` потенциальный runtime баг.
- `as` casts / unsafe coercions.
- Non-null assertions (`!`) — где можно type guard.
- Generic constraints корректны.
- Duck typing: shape совпадает с реальными данными?
- Schema (Zod/Pydantic/etc.) ↔ type alignment.
- Discriminated unions для state machines.
- Inline types vs named exports (DRY).
- На boundaries — `unknown` + parsing вместо `any`.

#### security-reviewer

- OWASP Top 10: injection, XSS, SSRF, path traversal, IDOR, broken auth.
- Input validation на boundaries (user input, API params, file uploads).
- Encoding output (`encodeURIComponent`, HTML escape, SQL params).
- PII / sensitive data: не логируется, не сохраняется в открытом виде.
- Error handling: try/catch, нет swallowed errors без причины.
- DoS vectors: unbounded loops, arrays, memory growth.
- Limits на user input (size, rate, count).
- Tenant / authorization isolation на каждом уровне.
- Secrets: нет hardcoded, проверка env vars.

#### test-reviewer

- Все public methods покрыты тестами.
- Edge cases: empty, error, timeout, null.
- Negative tests: что если всё сломается?
- Mock quality: реалистичные моки, не stub-заглушки.
- Backward compatibility: старый код не сломан.
- Integration: E2E flow покрыт?
- Determinism: тесты не flaky.
- Test isolation: нет shared state.
- Missing tests: конкретный список с обоснованием.

#### backend-reviewer

- Service boundary violations.
- Inter-service communication: правильный ли механизм?
- Tenant / auth isolation в каждом query / action.
- Idempotency и retry safety.
- Event-driven patterns: правильный ли transport?
- Error resilience: что если зависимость недоступна?
- Resource cleanup: connections, listeners.
- Observability: traces, metrics, structured logs.

#### frontend-reviewer

- State management: где живёт state, не дублирован ли.
- API data — в правильном кеш-слое (Query/SWR), не в client store.
- Components: composability, props vs context.
- Accessibility (a11y): ARIA, keyboard nav, контраст.
- Performance: rerenders, memoization, code splitting.
- UX: loading / error / empty states.
- Routing: правильное использование роутера.

#### task-reviewer

- Каждый item из RFC / TODO / spec — реализован?
- Реализован буквально или иначе? Если иначе — почему?
- Документация / changelog обновлены?
- Tests для каждого нового item?

---

## Фаза 3: Task Completion Check

После всех reports — leader строит таблицу:

```markdown
### Task Completion Matrix

| # | Original Task | Status | Details |
| - | ------------- | ------ | ------- |
| 1 | task from RFC | ✅ Done / ⚠️ Issues / ❌ Missing | what exactly |
| 2 | ...           | ...                            | ...          |

### Completion Rate: X/Y tasks (Z%)
```

Если completion < 80% → verdict не может быть APPROVE.

---

## Фаза 4: Synthesis & Verdict

### 4a. Кросс-референс

- **Consensus** (несколько агентов flag'нули одно) → high confidence.
- **Unique** (один агент заметил) → verify importance.
- **Conflict** (агенты не согласны) → представь обе стороны.

### 4b. Overall Score

Взвешенное среднее (1-10):

| Agent | Weight | Reason |
|---|---|---|
| logic-reviewer | 1.3 | Logic bugs hardest to catch later |
| arch-reviewer | 1.2 | Architecture costly to fix |
| security-reviewer | 1.2 | Security bugs critical |
| type-reviewer | 1.0 | Type safety baseline |
| test-reviewer | 0.8 | Tests can be added later |
| backend-reviewer | 0.8 | Service patterns |
| frontend-reviewer | 0.8 | UI patterns |
| task-reviewer | 0.7 | Task completion |

### 4c. Final Verdict

| Условие | Verdict |
|---|---|
| Все APPROVE + completion ≥ 80% | **APPROVE** |
| Большинство APPROVE, часть APPROVE_WITH_FIXES | **APPROVE_WITH_FIXES** |
| Любой REQUEST_CHANGES | **REQUEST_CHANGES** |
| Любой REJECT или completion < 50% | **REJECT** |

### 4d. Финальный отчёт

```markdown
# Audit Report: {target}

**Panel**: {agents used with skills}
**Files reviewed**: N files, ~M LOC
**Date**: YYYY-MM-DD
**Original Task**: {ref}

## Overall Score: X.X/10
## Task Completion: X/Y (Z%)
## Verdict: {APPROVE | APPROVE_WITH_FIXES | REQUEST_CHANGES | REJECT}

---

### Task Completion Matrix
| # | Task | Status | Details |

### Consensus Issues (2+ agents agree)
| # | Severity | Issue | Agents | File:Line |

### Unique Findings
| # | Agent | Severity | Issue | File:Line |

### Debate (agents disagree)
| Issue | For | Against | Recommendation |

### Positive Highlights
- top 5 things done well

### Action Plan (priority order)
1. [CRITICAL] ...
2. [WARNING] ...
3. [NICE-TO-HAVE] ...
```

### 4e. Спроси пользователя

```
Варианты:
1. ✅ Применить ВСЕ исправления (critical + warnings)
2. 🔧 Только critical
3. 📋 Показать каждое по одному
4. ❌ Отклонить — сделаю сам
```

---

## Token Budget

- Max 6 agents per audit.
- Файлы — встраивай в промпт (агент не должен re-read'ить).
- Большие файлы (>500 строк) — только relevant sections / diff.
- Каждый prompt: ≤8000 tokens.
- Каждый response: ~1500–2500 tokens.

---

## Error handling

| Симптом | Действие |
|---|---|
| Агент упал/timeout | Отметь в отчёте, не блокируй других |
| Scope пуст | Спроси пользователя |
| Scope > 30 файлов | Разбей или попроси пользователя сузить |
| Все APPROVE, но type-check / build fails | Override до REQUEST_CHANGES |
| Нет RFC/TODO | Skip Phase 3, отметь в отчёте |

---

## Cleanup

После synthesis — shutdown teammates → `TeamDelete()` (Mode A) / просто дождись завершения (Mode B). См. cleanup checklist в [`team`](../team/SKILL.md).

---

## Связанные скиллы

- [`team`](../team/SKILL.md) — фундамент (Mode A/B, file ownership, cleanup).
- [`research`](../research/SKILL.md) — пред-аудит исследование.
- [`sprint`](../sprint/SKILL.md) — после спринта обычно идёт audit.
- [`do`](../do/SKILL.md) — pipeline `sprint → audit`.
- [`rfc`](../rfc/SKILL.md) — обновление RFC после audit (Implementation Log + Insights).

## Anti-patterns

- **Меньше 4 агентов** — это не аудит, а point review.
- **Один агент с большим promptом «проверь всё»** — теряется фокус по доменам.
- **Score 8/10 без consensus issues** — подозрительно, попроси cross-validate.
- **APPROVE при completion 50%** — нарушение правила Phase 3.
- **Файлы переданы по ссылкам, а не по содержимому** — агенты re-read'ят и сжигают tokens.
