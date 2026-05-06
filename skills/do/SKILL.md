---
name: do
description: Мета-оркестратор — принимает задачу на естественном языке, классифицирует её (research / docs / feature / review / bug / refactor / status), строит pipeline из других скиллов (research → write-doc → wave-sprint → audit), показывает план пользователю, исполняет с approval-чекпойнтами. Используется, когда пользователь хочет «сделай X» без указания конкретного скилла. Триггеры (EN/RU) — "do X", "implement and document", "research and write RFC", "сделай", "разберись и реализуй", "проведи ревью ветки", "/do".
---

# Task Orchestrator

«Мета-команда»: принимает любую формулировку задачи и сам собирает pipeline из других
скиллов. Сам не делает работу — делегирует. Цель — снять с пользователя ментальный
overhead «какой скилл вызвать»; пользователь говорит «что», оркестратор решает «как».

---

## Когда использовать

- Пользователь описал задачу одной фразой и не указал конкретный скилл.
- Задача очевидно требует нескольких шагов (research + RFC, research + sprint + audit, etc.).
- Пользователь сказал: «сделай», «разберись», «проведи ревью», «реализуй и задокументируй».

## Когда НЕ использовать

- Конкретный скилл явно подходит и пользователь его указал — вызывай его напрямую.
- Тривиальная задача (read file, fix typo) — не оркеструй, просто сделай.
- Один shot research / один shot audit — вызывай скилл напрямую.

---

## Workflow

### Phase 1: UNDERSTAND — классификация

Парси `$ARGUMENTS` в одну или несколько категорий:

| Категория | Сигналы | Pipeline |
|---|---|---|
| **research** | "разберись", "изучи", "что есть", "какой статус", "сравни" | research → report |
| **documentation** | "напиши RFC", "сделай guide", "доку", "report", "ADR" | research → write-doc |
| **feature** | "добавь", "реализуй", "implement", "создай фичу" | research → plan → wave-sprint → tests → docs |
| **review** | "ревью", "review", "проверь код", "аудит" | audit (review squad) → report |
| **bug** | "баг", "не работает", "сломалось", "investigate" | research → bug-hunt team → fix |
| **refactor** | "рефакторинг", "refactor", "переделай", "migrate" | research → plan → wave-sprint (refactor) → tests |
| **analysis** | "анализ", "analyze", "gap analysis", "state of" | research → write-doc (report) |
| **status** | "статус", "что сделано", "прогресс" | lightweight research (3 explore) → report |

**Несколько категорий допустимы**:

- "спроектируй webhooks v2 и напиши RFC" = research + documentation
- "добавь SCIM и задокументируй" = feature + documentation

### Phase 2: RECALL

Если есть memory — быстрая проверка:

```
memory_recall("$TOPIC")
memory_recall("$TOPIC architecture decisions")
```

Часто research уже сделан раньше — можно skip-ать.

### Phase 3: PLAN — постройка pipeline

На основе классификации выбери template (см. ниже). Покажи pipeline пользователю **до** execution:

```markdown
## Task: $ARGUMENTS

Классифицировано как: [{categories}]

### Proposed Pipeline:

Step 1: RESEARCH — multi-agent research (5 агентов параллельно: code, docs, status, reference, knowledge)
   → Output: Research Report

Step 2: WRITE-DOC (RFC) — RFC по результатам research'а
   → Output: RFC-XXX-WEBHOOKS-V2.md

Step 3: SAVE — File + Memory + RFC-INDEX update

Estimated agents: 7 (5 research + 2 doc)
Approval checkpoints: после research, после draft

Proceed? (yes / adjust pipeline / skip steps)
```

Жди ответа. Пользователь может:

- **"yes" / "давай" / "1"** → execute all
- **"skip research"** → jump to step 2
- **"only research"** → stop after step 1
- Скорректировать любой шаг

### Phase 4: EXECUTE — пошагово

Выполняй steps sequential. Output одного шага → input следующего (передавай как краткий
summary, не raw данные — иначе context overflow).

---

## Pipeline Templates

### Template A: RESEARCH → REPORT (pure research)

**Для**: "разберись", "изучи", "какой статус", "сравни"

```
Step 1: RESEARCH
  → [`research`](../research/SKILL.md), 5 агентов
  → Output: 5 reports

Step 2: SYNTHESIZE
  → Cross-reference, identify gaps, conflicts

Step 3: DELIVER
  → Present report
  → memory_retain (если memory есть)

Step 4: CLEANUP
```

### Template B: RESEARCH → WRITE-DOC (research + docs)

**Для**: "напиши RFC", "сделай guide", "report"

```
Step 1: RESEARCH (как Template A) → research report

Step 2: WRITE-DOC
  → Определи doc type (RFC / guide / report / ADR)
  → Определи путь и следующий номер (см. [`rfc`](../rfc/SKILL.md))
  → Напиши документ, используя research как input
  → Следуй формату из [`rfc`](../rfc/SKILL.md)

Step 3: APPROVAL CHECKPOINT
  → Покажи draft пользователю
  → Wait: approve / edit / reject

Step 4: SAVE (только после approval)
  → Write file
  → memory_retain summary
  → Update RFC-INDEX (если RFC)
  → Update TODO (если применимо)

Step 5: CLEANUP
```

### Template C: RESEARCH → PLAN → WAVE-SPRINT (feature implementation)

**Для**: "добавь", "реализуй", "implement"

```
Step 1: RESEARCH (как Template A, focus на implementation context)
  → Что есть, что нужно, reference patterns

Step 2: PLAN
  → На основе research → план через [`sprint`](../sprint/SKILL.md) Step 2
  → File ownership map
  → Task breakdown (5-6 на teammate)
  → Dependencies

Step 3: APPROVAL CHECKPOINT
  → Покажи план
  → Wait approval

Step 4: WAVE-SPRINT execute
  → [`sprint`](../sprint/SKILL.md) Step 4 — wave-by-wave
  → Backend, frontend, tests teammates с research context

Step 5: VERIFY
  → typecheck, build, tests (project-specific commands)

Step 6: DOC (опционально, если задача включала docs)
  → Update TODO с [x]
  → memory_retain decisions
  → Update RFC (Implementation Log + Insights)

Step 7: CLEANUP
```

### Template D: AUDIT (code review)

**Для**: "ревью", "review", "аудит"

```
Step 1: SCOPE
  → Определи что review (branch diff, files, PR)
  → git diff main...HEAD для branch

Step 2: AUDIT
  → [`audit`](../audit/SKILL.md), 4-6 агентов

Step 3: SYNTHESIZE
  → Cross-validate, prioritize Critical > High > Medium > Low

Step 4: DELIVER
  → Present audit report
  → memory_retain key issues

Step 5: CLEANUP
```

### Template E: RESEARCH → BUG HUNT (bug investigation)

**Для**: "баг", "не работает", "investigate"

```
Step 1: RESEARCH (focused на область бага)
  → memory_recall known issues
  → Read KNOWN-ISSUES.md
  → Понять архитектуру вокруг бага

Step 2: BUG HUNT TEAM
  → Spawn 3-5 teammates, каждый — свою гипотезу:
    · hypothesis-input: validation, parsing
    · hypothesis-state: race condition, mutation
    · hypothesis-config: env mismatch
    · hypothesis-timing: async, ordering
  → См. [`team`](../team/SKILL.md), Recipe 3.

Step 3: SYNTHESIZE
  → Какая гипотеза подтверждена? Root cause?

Step 4: FIX (если простой)
  → Apply fix, add test, verify

Step 5: DOCUMENT
  → Update KNOWN-ISSUES.md
  → memory_retain root cause + fix

Step 6: CLEANUP
```

### Template F: LIGHTWEIGHT STATUS CHECK

**Для**: "статус", "что сделано", "прогресс"

**Без team** — параллельные sub-агенты:

```
Step 1: PARALLEL SEARCH (3 sub-agents без TeamCreate):
  → Task(Explore): TODO files for topic
  → Task(Explore): codebase for topic
  → Task(Explore): memory_recall for topic (если memory есть)

Step 2: SYNTHESIZE → status report

Step 3: DELIVER
```

---

## Decision Logic (как выбрать template)

```
1. Парси $ARGUMENTS на сигналы (Phase 1).

2. Несколько категорий?
   - research signals only → A
   - research + doc → B
   - feature → C
   - review → D
   - bug → E
   - status → F
   - feature + doc → C, потом добавь doc step из B
   - research + feature → A, потом C с research как input

3. Если неясно — спроси:
   "Я вижу что ты хочешь {X}. Должен ли я:
    a) только research и report?
    b) research, потом написать doc?
    c) research, plan, и реализовать?
    d) что-то другое?"
```

---

## Approval Checkpoints

Оркестратор работает автономно, но **обязательно** делает паузу:

| Checkpoint | Когда | Что показываем |
|---|---|---|
| **Pipeline approval** | После Phase 3 | Предложенный pipeline + estimated agents |
| **Research review** | После research | Summary findings, proceed? |
| **Draft review** | После doc/RFC | Полный документ, approve/edit/reject? |
| **Implementation plan** | До spawn dev team | File ownership, task breakdown |
| **Final review** | После имплементации | Diff summary, tests passing? |

На каждом — пользователь может:

- **"давай" / "yes"** → continue
- **"стоп"** → abort
- **"пропусти"** → skip step
- **"измени X"** → adjust + retry

---

## Context passing between steps

Output одного шага → input следующего. Правила:

- Передавай **summary**, не raw data — иначе context overflow.
- Каждый шаг сжимает свой output для следующего.
- Если шагов много — сохраняй промежуточные артефакты в файлы (`research/reports/X.md`),
  ссылайся на них вместо встраивания в prompt.

```
RESEARCH output (5 reports → summary)
    ↓
WRITE-DOC (использует summary для контента)
    ↓
WAVE-SPRINT (teammates получают research summary + doc как requirements)
    ↓
MEMORY (retain synthesis)
```

---

## Error handling

| Ситуация | Действие |
|---|---|
| Team agent fails | Retry once. Если опять — partial report, спроси пользователя |
| Research пуст | "Ничего не найдено", спроси расширить keywords |
| Doc draft отклонён | Получи specific feedback, перепиши |
| Implementation fails tests | Report failures, attempt fix, если стоп — попроси user |
| Pipeline затянулся | Repor progress между steps, user может abort |
| Memory save failed | Report error, продолжай pipeline |

---

## Integration со связанными скиллами

Оркестратор не реализует логику сам — делегирует:

| Step | Делегирует | Как |
|---|---|---|
| RESEARCH | [`research`](../research/SKILL.md) | 5-agent team, тот же recipe |
| WRITE-DOC | [`rfc`](../rfc/SKILL.md) | RFC format, индекс, log |
| PLAN+EXECUTE | [`sprint`](../sprint/SKILL.md) | Wave-by-wave |
| BUILD from existing plan | [`build`](../build/SKILL.md) | IMPLEMENTATION-PLAN-driven |
| REVIEW / AUDIT | [`audit`](../audit/SKILL.md) | 4-6 reviewers |
| TEAM ops (foundation) | [`team`](../team/SKILL.md) | Mode A/B, cleanup |
| BRIEFING / RECALL | [`briefing`](../briefing/SKILL.md) / [`restore`](../restore/SKILL.md) | Перед/во время pipeline |

---

## Examples

### "спроектируй webhooks v2 и напиши RFC"

```
Categories: research + documentation
Template: B (research → write-doc)
Pipeline:
  1. research → webhook patterns, наш код, reference (n8n, trigger.dev)
  2. rfc → RFC-XXX-WEBHOOKS-V2.md
  3. SAVE → file + memory + RFC-INDEX
Checkpoints: после research, после draft
```

### "какой статус по SSO SAML?"

```
Categories: status
Template: F (lightweight)
Pipeline:
  1. 3 параллельных Explore sub-agents → TODO + code + memory
  2. SYNTHESIZE → status report
Без team. Быстро.
```

### "добавь SCIM provisioning — полный цикл"

```
Categories: feature + documentation
Template: C + B hybrid
Pipeline:
  1. research → SCIM standards, наш IAM, reference
  2. sprint Step 2 → план
  3. sprint Step 4 → backend-dev + test-writer
  4. rfc → SCIM-INTEGRATION guide
  5. SAVE → файлы + memory + TODO
Checkpoints: research, plan, имплементация, doc
```

### "проведи security ревью текущей ветки"

```
Categories: review
Template: D
Pipeline:
  1. SCOPE: git diff main...HEAD
  2. audit → security + perf + tests focus
  3. SYNTHESIZE → prioritized findings
  4. SAVE → memory + KNOWN-ISSUES если найдены баги
```

---

## Tips

1. **Будь конкретен в задаче** — "спроектируй webhooks для real-time event delivery с retry и DLQ" работает лучше чем "сделай webhooks".
2. **Скажи что хочешь в конце** — "и напиши RFC" говорит оркестратору добавить doc step.
3. **Можно прервать** — на любом checkpoint измени pipeline.
4. **Pipeline всегда виден** — пользователь видит план до execute.
5. **Memory накапливается** — каждый next call по близкой теме быстрее.
6. **Lightweight by default** — status checks не спавнят полные команды.

---

## Связанные скиллы

- [`research`](../research/SKILL.md) — research step.
- [`rfc`](../rfc/SKILL.md) — write-doc step.
- [`sprint`](../sprint/SKILL.md) — implementation step.
- [`build`](../build/SKILL.md) — если research уже завершён и есть IMPLEMENTATION-PLAN.
- [`audit`](../audit/SKILL.md) — review step.
- [`team`](../team/SKILL.md) — фундамент для всех team ops.
- [`restore`](../restore/SKILL.md) — recall перед сложным pipeline.
- [`briefing`](../briefing/SKILL.md) — task-tracker briefing вне кода.

## Anti-patterns

- **Не запускай pipeline без approval** — пользователь должен видеть план.
- **Не передавай raw output между шагами** — сжимай в summary.
- **Не оркеструй тривиальную задачу** — если 1 скилл достаточно, вызывай его напрямую.
- **Не пропускай RECALL** — research часто уже сделан.
- **Не забывай про cleanup** — каждый step должен корректно завершиться (TeamDelete, memory_retain).
