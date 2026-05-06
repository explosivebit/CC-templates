---
name: research
description: Глубокий многоагентный research по теме — параллельные агенты-разведчики покрывают source code, design docs/RFC, TODO/status файлы, reference implementations, persistent memory. Каждому агенту — свой ограниченный домен и свой контекст. Используется, когда тема большая (auth chain, сравнение с конкурентами, gap-analysis по фиче) и одного агента/контекста недостаточно. Триггеры (EN/RU) — "deep research", "explore X across the project", "compare our X with Y", "gap analysis for X", "разберись", "изучи", "сравни", "глубокий research", "что есть по теме X", "/research".
---

# Multi-Agent Deep Research

Параллельная разведка темы силами нескольких агентов с непересекающимися областями.
Каждый источник знания — большой и требует своего контекстного окна; разделение
позволяет не выходить за лимит и одновременно дать каждому агенту простор для
тщательной проверки.

Опирается на [`team`](../team/SKILL.md) —
все правила Mode A/B, file ownership, cleanup идут оттуда. Здесь живёт research-recipe.

---

## Когда использовать

- Тема большая или незнакомая, нужен «полный обзор» (auth chain, queue architecture, RAG pipeline).
- Сравнение «наш подход vs reference implementations».
- Gap-analysis перед началом фичи: что уже есть, чего не хватает, где документация рассинхронилась с кодом.
- Пользователь сказал: «разберись», «изучи», «сравни», «что у нас по теме X», «deep research».

## Когда НЕ использовать

- Точечный вопрос «где функция X?» — обычный grep быстрее.
- Все источники в одном модуле (1 пакет, 1 файл) — лишняя оркестрация.
- Нужен план внесения изменений — это [`sprint`](../sprint/SKILL.md).

---

## Архитектура: 5 агентов, 5 доменов

| Агент | Что ищет | Что НЕ трогает |
|---|---|---|
| **code-researcher** | Source code: `src/`, `packages/`, `services/`, `apps/`, тесты | Документацию, reference, memory |
| **doc-researcher** | RFC, design docs, guides, ADR, README верхнего уровня | Source code, TODO |
| **status-researcher** | TODO files, project status docs, KNOWN-ISSUES, recently_completed | Source code, RFC |
| **reference-researcher** | `sources/`, `vendor/`, `examples/`, Context7 для внешних либ | Внутренний код проекта |
| **knowledge-researcher** | Persistent memory (Hindsight/notes), `research/`, `docs/decisions/` | Source code, reference |

Если в проекте нет какого-то источника (нет `sources/` или нет memory) — соответствующего агента просто пропускай. **Не выдумывай несуществующие** домены.

---

## Lightweight mode (2–3 агента)

Для узких/простых вопросов:

- Простой факт-вопрос («где находится X?»).
- Один домен (только код ИЛИ только docs).
- Ожидается <10 файлов.

Тогда — параллельные `Task()` без `TeamCreate`. Правило выбора:

- **3+ агента** → MUST `TeamCreate` (Mode A).
- **1–2 агента** → допустимо без team.
- **Сомнения** → `TeamCreate` (overhead минимален).

---

## Процесс

### Step 0: Validate input

`$ARGUMENTS` — тема. Если пусто:

```
Что исследовать? Примеры:
- "auth chain architecture"
- "что у нас сделано по webhooks"
- "сравни наш queue с n8n и trigger.dev"
- "SSO SAML integration patterns"
```

### Step 1: Recall (быстрая проверка памяти)

Если memory доступна:

```
memory_recall("$ARGUMENTS")
```

Это бесплатно и часто уже содержит частичный ответ. Поделись результатом со всеми teammates.

### Step 2: Classify — keywords + domain mapping

Извлеки 3–5 ключевых слов:

- "auth chain architecture" → `auth, chain, middleware, session, token`
- "SSO SAML integration" → `sso, saml, oidc, connector, login`
- "webhooks v2" → `webhook, event, notification, callback, realtime`

Определи, какие из 5 доменов реально применимы (если в проекте нет `sources/` — нет reference-researcher'а).

### Step 3: Spawn team

`TeamCreate(team_name="research-{sanitized-topic}")` + до 5 параллельных `Agent(team_name=...)` в **одном** message.

Шаблоны промптов — ниже. Каждый получает: тему, ключевые слова, результат `memory_recall` (если был), свой scope, свой output format.

### Step 4: Synthesize

Когда все вернулись:

1. Прочти все 5 reports.
2. Кросс-референс:
   - Source code vs TODO (источник истины — код).
   - RFC vs implementation (заметки о gaps).
   - Наш код vs reference implementations (сравни паттерны).
   - Memory vs current state (обнови memory, если устарело).
3. Identify conflicts — где источники расходятся.
4. Synthesize в финальный отчёт.

### Step 5: Deliver report

Формат — фиксированный (см. ниже).

### Step 6: Save to memory

Если memory доступна:

```
memory_retain("# Research: {topic} — Summary (YYYY-MM-DD)
Scope: 5-agent deep research
Key findings: ...
Gaps: ...
Recommendations: ...
Key files: ...")
```

### Step 7: Cleanup

Shutdown teammates → `TeamDelete()`.

---

## Шаблоны промптов teammates

### Teammate 1: code-researcher (subagent_type: Explore)

```
You are a SOURCE CODE research agent.
Search ONLY source code — no docs, no reference projects, no memory.

TOPIC: "{$ARGUMENTS}"
KEYWORDS: {$KEYWORDS}
MEMORY CONTEXT: {$MEMORY_RECALL_RESULTS}

=== SCOPE ===
- Primary code dirs (ask CLAUDE.md или ищи в обычных местах: src/, packages/, services/, apps/, lib/)
- Tests (*.test.ts, *.spec.ts, __tests__/)
- Configs that affect behavior

=== STRATEGY ===
1. Glob "**/README.md" в основных code-папках — найди релевантные модули.
2. Grep keywords во всём source — найди реализации.
3. Read public API surface (index.ts, mod.rs, __init__.py) релевантных модулей.
4. Check tests — какие сценарии покрыты, какие нет.
5. Note configs (env example, package.json scripts) если влияют.

=== OUTPUT ===

## Source Code: {topic}

### Modules / Packages
| Module | Key Files | Tests | What It Does |

### Patterns
- pattern: where, how it works

### Gaps (NOT implemented)
- missing piece: expected location, why we know it's missing

### Key Files (top 10)
| File | Lines | Relevance |
```

### Teammate 2: doc-researcher (subagent_type: Explore)

```
You are a DOCS & DESIGN research agent.
Search ONLY documentation — RFCs, design docs, ADR, guides, README. No source code, no TODO.

TOPIC, KEYWORDS, MEMORY CONTEXT — same as above.

=== SCOPE ===
- docs/, doc/, documentation/
- RFC-*.md, ADR-*.md, DESIGN-*.md
- README.md (top-level + per-package)
- Guides, runbooks, architecture overviews

=== STRATEGY ===
1. Find index/TOC: docs/INDEX.md, docs/README.md, RFC-INDEX.md.
2. Locate related RFCs/ADRs by topic. Read them (use offset/limit if large).
3. Extract: status, key decisions, open questions, dependencies.
4. Find guides matching keywords. Note: patterns, configurations, examples.

=== OUTPUT ===

## Docs & Design: {topic}

### Related RFCs / ADRs
| ID | Title | Status | Key Decisions |

### Decision History
- decision: source, rationale, date

### Guides
| Guide | Key Info | Relevance |

### Known Issues
- related bugs/issues with refs
```

### Teammate 3: status-researcher (subagent_type: Explore)

```
You are a STATUS & TODO research agent.
Search ONLY TODO files and project status docs to determine "что сделано, что осталось".

TOPIC, KEYWORDS — same.

=== SCOPE ===
- TODO.md, TODO_*.md, **/docs/TODO.md
- KNOWN-ISSUES.md, BUGS.md, ROADMAP.md
- Recently completed sections / changelogs

=== STRATEGY ===

TODO files often LARGE (1000+ lines). NEVER read them whole.
1. Grep keywords in TODO files — find sections.
2. Read relevant sections with offset/limit (±50 lines around match).
3. Extract: [x] done items, [ ] remaining, "Gaps", "Backend endpoints needed".
4. CROSS-CHECK with source code:
   For each [x] done item, quick-verify with grep/glob — does the code actually exist?
   Mark verified vs unverified.

=== OUTPUT ===

## Status: {topic}

### Done [x] (verified in code)
| Item | Location |

### Done [x] (claimed but NOT found in code)
| Item | TODO ref | Where we expected to find it |

### Remaining [ ]
| Item | TODO ref | Phase / Priority |

### Timeline (from TODO dates)
- date: what was done
```

### Teammate 4: reference-researcher (subagent_type: Explore)

```
You are a REFERENCE IMPLEMENTATION research agent.
Search ONLY reference projects — sources/, vendor/, examples/, plus Context7 for library docs.

TOPIC, KEYWORDS — same.

=== STRATEGY ===
1. Read sources/SOURCES-REFERENCE.md or sources/README.md (if exists).
2. Pick 3-5 most relevant reference projects.
3. For each:
   - Grep keywords inside that project.
   - Read main entry points and architecture docs.
   - Focus on PATTERNS, not implementation details.
   - Note pros / cons / tradeoffs.
4. Context7 (for libraries):
   mcp__context7__resolve-library-id(libraryName="...", query="...")
   mcp__context7__query-docs(libraryId="...", query="...")

=== OUTPUT ===

## Reference: {topic}

### Projects Analyzed
For each (top 3-5):

#### {Project}
- Approach: how they solve it
- Key architecture: structure, patterns
- Key files: 2-3 most important paths
- Pros: ...
- Cons: ...
- Relevance to our project: ...

### Industry Patterns
| Pattern | Used By | Pros | Cons |

### Best Fit
- Recommended approach: ...
- Adaptations needed: ...
```

### Teammate 5: knowledge-researcher (subagent_type: Explore)

```
You are a KNOWLEDGE BASE research agent.
Search persistent memory and accumulated research notes.

TOPIC, KEYWORDS — same.

=== STRATEGY ===
1. Memory (Hindsight or whatever's configured):
   memory_recall("{topic}")
   memory_recall("{kw1} architecture")
   memory_recall("{kw2} decisions")
   memory_recall("{kw1} bugs known issues")
   memory_reflect("What patterns emerge for {topic}?")

   Если memory не настроена — пропусти и явно скажи в output.

2. Research directory (if exists):
   research/, research/projects/, research/architecture/, research/reports/
   Glob, Grep, Read relevant files.

3. Decision logs:
   docs/decisions/, ADR/, decisions.md.

=== OUTPUT ===

## Knowledge: {topic}

### From Memory
| Memory | Date | Key Info |

### Past Decisions
- decision: rationale, source

### Research Documents
| Document | Path | What It Contains |

### Patterns & Insights
- pattern 1: where observed, significance

### Contradictions
- Memory says X, but code/research says Y

### Knowledge Gaps
- what we don't know yet
```

---

## Финальный отчёт (формат)

```markdown
# Research Report: {topic}

**Date**: YYYY-MM-DD
**Team**: 5 agents (code + docs + status + reference + knowledge)

---

## Executive Summary

2-3 предложения: что нашли, что есть, чего нет.

## Current State

### Code
{from code-researcher}

### Docs
{from doc-researcher}

### Status (from TODOs)
{from status-researcher}

### Code vs Docs Alignment
| Item | In Code? | In Docs? | Status |
| ---- | -------- | -------- | ------ |
| feature | Yes/No | RFC-XXX/TODO | Aligned / Gap / Stale |

## How Others Do It

{from reference-researcher — top 2-3 approaches}

## Accumulated Knowledge

{from knowledge-researcher}

## Gaps & Opportunities

1. gap — where, impact, suggested approach

## Recommendations

1. recommendation with rationale

## Sources Consulted

{flat list — every file/doc/RFC/source/memory checked, by agent}
```

---

## Tips для leader'а

1. **Memory recall сначала** — бесплатно, может уже содержать ответ.
2. **Хорошие keywords** — каждый агент grep'ит по ним; чем точнее, тем меньше шума.
3. **Передавай memory результаты teammates** — иначе они дублируют работу.
4. **Не дублируй scope** — у каждого агента свой эксклюзивный домен.
5. **Synthesis = ценность** — не просто склеить отчёты, а найти противоречия и инсайты.
6. **Сохраняй findings** — следующий research по близкой теме станет короче.
7. **Verify TODO claims против кода** — главная задача status-researcher'а.

---

## Связанные скиллы

- [`team`](../team/SKILL.md) — базовые правила (Mode A/B, cleanup, file ownership).
- [`audit`](../audit/SKILL.md) — research → audit для проверки качества.
- [`sprint`](../sprint/SKILL.md) — после research → план + волновое исполнение.
- [`rfc`](../rfc/SKILL.md) — research часто завершается RFC.
- [`do`](../do/SKILL.md) — orchestrator цепляет research → write-doc → build.

## Anti-patterns

- **Не запускай 5 агентов на простой вопрос** — lightweight mode для этого.
- **Не разделяй scope нечётко** — пересекающиеся scope = дублированная работа.
- **Не верь только TODO** — verify в коде.
- **Не выводи raw outputs всех 5 агентов** — synthesis сам по себе ценность.
- **Не удаляй team молча** — спроси пользователя перед `TeamDelete`.
