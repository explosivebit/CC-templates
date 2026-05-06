---
name: rfc
description: Создаёт, читает и обновляет RFC (Request for Comments) / design docs — структурированные документы для архитектурных решений. Знает каноническую структуру (Meta header, Phase Progress, Implementation TODO, ADR), правила обновления прогресс-баров, формат checkbox'ов. Используется при предложении нового технического решения, документировании архитектуры, или обновлении прогресса по существующему RFC после спринта/волны. Триггеры (EN/RU) — "write RFC", "create design doc", "update RFC progress", "draft proposal", "ADR", "напиши RFC", "сделай design doc", "обнови прогресс RFC", "создай предложение", "архитектурное решение".
---

# RFC Document

Канонический формат RFC / design docs / ADR. Скилл универсальный: работает там, где
RFC хранятся в `docs/rfc/`, `docs/design/`, `docs/adr/` или просто в корне проекта.
Имя префикса (RFC / ADR / DESIGN) определяется конвенцией проекта — спроси `CLAUDE.md`
или посмотри уже существующие файлы.

---

## Когда использовать

- Пользователь предложил новый архитектурный подход и хочет «зафиксировать как RFC / ADR».
- Нужно обновить прогресс по существующему RFC после волны/спринта (Phase Progress, Implementation Log).
- Нужно прочитать RFC и извлечь актуальный статус, оставшиеся задачи, ADR.
- Нужно создать `RFC-INDEX.md` для папки с RFC.

## Когда НЕ использовать

- Пользователю нужен README, getting-started guide или туториал — это другой формат.
- Решение тривиальное (переименование переменной, фикс опечатки) — RFC overkill.
- Документ описывает API endpoints — это OpenAPI, а не RFC.

---

## Базовая структура RFC

```
┌─────────────────────────────────────────┐
│ 1. Title + Meta Table                   │  ← обязательно
│ 2. Summary                              │  ← обязательно
│ 3. Motivation / Problem Statement       │  ← обязательно
│ 4. Goals / Non-Goals                    │  ← обязательно
│ 5. Architecture Overview                │  ← рекомендуется (ASCII art)
│ 6. Detailed Design                      │  ← основное тело
│ 7. Table of Contents                    │  ← если RFC > 500 строк
│ ...                                     │
│ N-2. Implementation TODO                │  ← обязательно (фазы + чекбоксы)
│ N-1. Implementation Log                 │  ← после начала работы (волны)
│ N.   ADRs / References                  │  ← опционально
└─────────────────────────────────────────┘
```

---

## 1. Meta Header (обязательно)

```markdown
# RFC-{NNN}: {Title}

| Field          | Value                                              |
| -------------- | -------------------------------------------------- |
| **Status**     | Draft / Active / Done / Superseded                 |
| **Author**     | {Team / Person}                                    |
| **Created**    | YYYY-MM-DD                                         |
| **Updated**    | YYYY-MM-DD                                         |
| **Priority**   | P0 / P1 / P2                                       |
| **Depends On** | RFC-XXX, RFC-YYY                                   |
| **Supersedes** | RFC-ZZZ (если заменяет)                            |
| **Branch**    | `feat/RFC-{NNN}-short-name` или `merged to main`   |
| **TODO Line**  | ~{line_number}                                     |
```

### Phase Progress (ASCII bars в начале файла)

```
Phase 0 ████████████████████████ 27/27 (100%) DB Foundation       CLOSED
Phase 1 ██████████████████████░░ 11/12 ( 92%) Versioning          1.10 deferred
Phase 2 ████████████████████░░░░ 16/19 ( 84%) Import/Export       Active
Phase 3 ██████████████████████░░ 28/30 ( 93%) Frontend CRUD       Active
─────────────────────────────────────────────────────────────────
TOTAL                            82/88 ( 93%)
```

**Правила**:
- Бар = 24 символа (`█` filled, `░` empty).
- Numbers right-aligned.
- Обновляй после **каждого** sprint/wave.
- `<-` после строки активной фазы (если хочешь подсветить).

---

## 2. Status — допустимые значения и нюансы

| Status | Когда |
|---|---|
| `Draft` | RFC написан, реализация не начата. |
| `Active — Wave N complete, Phase X partial` | В процессе. Указывай детали. |
| `~99% DONE — Phase 0-5 done, Remaining: E2E + hardening` | Почти завершён. |
| `**PR #N MERGED** — Phase 0-5 done, Phase 6-7 pending` | Часть смерджена, остальное в работе. |
| `Done` | Полностью реализован. |
| `Superseded by RFC-XXX` | Заменён новым RFC. |

---

## 3. Implementation TODO

Живой трекер прогресса. Структура секции:

```markdown
## N. Implementation TODO

**Branch**: `feat/RFC-{NNN}-short-name`
**Start Date**: YYYY-MM-DD
**Strategy**: краткое описание подхода

### Phase Progress

| Phase | Name           | Done | Total | %     | Status        |
| ----- | -------------- | ---- | ----- | ----- | ------------- |
| 0     | DB Foundation  | 27   | 27    | 100%  | CLOSED        |
| 1     | Versioning     | 11   | 12    | 92%   | 1.10 deferred |
| ...   | ...            | ...  | ...   | ...   | ...           |
| TOTAL |                | 82   | 88    | 93%   |               |

### Phase 0: DB Foundation

- [x] 0.1 Schema design — `db/schema.sql`
- [x] 0.2 Migration scripts — `db/migrations/0001_*.sql`
- [x] 0.3 Seed data — `db/seeds/`
- [ ] 0.4 Indexes review — `db/schema.sql` (deferred — see Phase Progress)

### Phase 1: ...
```

**Правила чекбоксов**:
- `[x]` = реально сделано (не «по плану», а есть код в репо). Перед галочкой — `grep`/`glob` для проверки.
- `[ ]` = ещё не сделано (или deferred с пометкой).
- После каждого пункта — путь к файлу или ключевая ссылка.

---

## 4. Implementation Log

После начала работы добавляй секции по волнам/спринтам:

```markdown
## N+1. Implementation Log

### Wave 1 — DB Foundation (YYYY-MM-DD)

**Sprint**: 3 agents, ~420 LOC, 12 tests added.

**Files Created**:
- `db/schema.sql` (250 LOC)
- `db/migrations/0001_initial.sql` (120 LOC)

**Files Modified**:
- `package.json` (add prisma scripts)

**Decisions**:
- Используем soft-delete вместо hard-delete для аудита.
- Индекс на `(tenant_id, created_at)` для основного query pattern.

#### Sprint Insights & Bottlenecks
- **ADR**: ... (link to ADR section)
- **Узкое место**: ...
- **Tech debt**: ...
- **Паттерн для переиспользования**: ...

### Wave 2 — Backend Logic (YYYY-MM-DD)
...
```

---

## 5. ADR (Architecture Decision Records)

Внутри RFC или отдельным файлом:

```markdown
### ADR-{NNN}: {Title}

**Status**: Accepted | Proposed | Deprecated | Superseded by ADR-XXX
**Date**: YYYY-MM-DD
**Context**: что заставляет принимать решение
**Decision**: что мы решаем
**Consequences**:
  - Положительные: …
  - Отрицательные: …
  - Tradeoffs: …
**Alternatives considered**: …
```

---

## Процесс: создание нового RFC

### 1. Сориентируйся

```bash
# найди существующие RFC
find . -name "RFC-*.md" -not -path "*/node_modules/*" 2>/dev/null
find . -name "ADR-*.md" -not -path "*/node_modules/*" 2>/dev/null
ls docs/rfc/ docs/design/ docs/adr/ 2>/dev/null
```

- Узнай конвенцию (RFC / ADR / DESIGN, путь, нумерация).
- Найди `RFC-INDEX.md` (если есть) — определи следующий свободный номер.

### 2. Спроси у пользователя

- Тема RFC (одно предложение).
- Уровень: full RFC или короткий ADR?
- Куда сохранить: путь по конвенции проекта.
- Зависимости / Supersedes (если есть).

### 3. Создай файл

Заполни Meta Header, Summary, Motivation, Goals/Non-Goals.
Добавь пустые Phase Progress бары (0%) и пустой Implementation TODO.
**Не пиши Implementation Log** — он появится после первой волны.

### 4. Обнови индекс

Если есть `RFC-INDEX.md`:

```markdown
| RFC | Title | Status | Updated |
| --- | ----- | ------ | ------- |
| 080 | Command Center | Draft | 2026-04-26 |
```

### 5. Закомить (только по запросу пользователя)

`feat(docs): add RFC-{NNN}-{short-name}`.

---

## Процесс: обновление RFC после волны/спринта

1. Читай RFC с `offset`+`limit` если он большой (>500 строк) — сначала Meta + Phase Progress, потом конкретный Phase.
2. Обнови Phase Progress (бары, таблицу, проценты, статусы).
3. Поставь `[x]` напротив выполненных пунктов; **верифицируй** их `grep`/`glob` — если кода нет, не ставь галочку.
4. Добавь новый блок в Implementation Log — Wave N с датой, файлами, решениями, инсайтами.
5. Обнови `Updated` поле в Meta.
6. Если был мерж — обнови `Status` (например, `**PR #N MERGED** — Phase X done`).

---

## Связанные скиллы

- [`sprint`](../sprint/SKILL.md) — после волны нужно обновить RFC.
- [`research`](../research/SKILL.md) — research часто заканчивается RFC.
- [`do`](../do/SKILL.md) — пайплайн «research → write RFC».

## Anti-patterns

- **Не ставь `[x]` без верификации в коде** — TODO быстро становится устаревшим.
- **Не дублируй Phase Progress в трёх местах** — Meta + начало TODO достаточно.
- **Не пиши «Implementation Log: TBD»** — пустую секцию просто не создавай.
- **Не клади в RFC API endpoints/полные схемы JSON** — они принадлежат `openapi.yaml` или отдельному guide.
- **Не путай RFC и ADR**: RFC — широкое предложение, ADR — точечное решение. Если документ — одно решение на 1 страницу, это ADR.
