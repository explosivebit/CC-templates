---
name: build
description: Запускает имплементационную команду из готового research-отчёта — читает IMPLEMENTATION-PLAN.md (фазы, file ownership, acceptance criteria) и SUMMARY с ADR, спавнит teammates по фазам (sequential или parallel), верифицирует результат через build/typecheck/tests. Используется, когда research уже завершён (через research или вручную) и осталось «выполнить план». Триггеры (EN/RU) — "build from research", "execute IMPLEMENTATION-PLAN", "implement based on research report", "имплементируй по research", "выполни план", "/build".
---

# Build from Research

Превращает готовый research-отчёт с `IMPLEMENTATION-PLAN.md` в реальный код. Не делает
research сам — ожидает, что артефакты уже есть. Опирается на
[`team`](../team/SKILL.md).

---

## Когда использовать

- Завершился [`research`](../research/SKILL.md) и сохранил `IMPLEMENTATION-PLAN.md`.
- Получили внешний research-pack с готовым планом (фазы, файлы, acceptance criteria).
- Пользователь сказал: «build from research/reports/X», «выполни план», «имплементируй по research-у».

## Когда НЕ использовать

- Research ещё не сделан — сначала [`research`](../research/SKILL.md).
- Плана нет, есть только идея — [`sprint`](../sprint/SKILL.md) (он сам сделает research).
- Нужен код-ревью — [`audit`](../audit/SKILL.md).

---

## Prerequisites

`$ARGUMENTS` = путь к директории research-отчёта. Внутри ОБЯЗАТЕЛЬНО:

| Файл | Назначение |
|---|---|
| `IMPLEMENTATION-PLAN.md` | Фазы + file ownership + LOC estimates + acceptance criteria |
| `00-SUMMARY.md` (или `SUMMARY.md`) | Executive summary + ADR |
| `CONTINUATION-PROMPT.md` | (опционально) Промпты по стадиям, удобно для длинных пайплайнов |

Если `IMPLEMENTATION-PLAN.md` нет — скажи пользователю, предложи:

- Сделать research сначала ([`research`](../research/SKILL.md)).
- Или создать план вручную ([`sprint`](../sprint/SKILL.md), Step 2).

---

## Процесс

### Step 0: Validate input

```bash
# проверь существование директории и обязательных файлов
ls "$ARGUMENTS/"
test -f "$ARGUMENTS/IMPLEMENTATION-PLAN.md" || echo "missing"
test -f "$ARGUMENTS/00-SUMMARY.md" || test -f "$ARGUMENTS/SUMMARY.md" || echo "missing"
```

Если `$ARGUMENTS` не указан — покажи список доступных research-папок:

```bash
find . -maxdepth 4 -name "IMPLEMENTATION-PLAN.md" -path "*/research/*" 2>/dev/null
ls research/reports/ 2>/dev/null
```

### Step 1: Read plan

```
Read("$ARGUMENTS/IMPLEMENTATION-PLAN.md")
Read("$ARGUMENTS/00-SUMMARY.md")
Read("$ARGUMENTS/CONTINUATION-PROMPT.md")  # если есть
```

Извлеки:

- **Фазы**: имя, приоритет (P0/P1/P2), effort, dependencies.
- **Team composition**: какие агенты нужны.
- **File ownership map** — у каждого агента свои файлы.
- **Acceptance criteria** — как поймём, что фаза готова.

### Step 2: Present to user

```markdown
## Build Plan from: {research-dir}

### Available Phases

| Phase | Name | Priority | Effort | Dependencies |
|---|---|---|---|---|
| 1 | {from PLAN} | P0 | 2 weeks | None |
| 2 | {from PLAN} | P0 | 3 weeks | None |
| 3 | ... | P1 | ... | Phase 2 |

### Team Composition

| Role | subagent_type | Phases |
|---|---|---|
| backend-dev | general-purpose | 1, 2 |
| frontend-dev | general-purpose / nextjs-developer | 1, 3 |
| test-writer | general-purpose | All |

### Какие фазы строим?

- "all" — все sequentially
- "1,2" — конкретные
- "parallel 1,2" — параллельные (если нет deps)
- "1" — только одна
```

**Жди выбор пользователя.**

### Step 3: Prepare context

Для каждой выбранной фазы из `IMPLEMENTATION-PLAN.md` извлеки:

- Task list (file paths, LOC estimates, test counts).
- Acceptance criteria.
- File ownership map.
- Dependencies на другие фазы.

Объедини с:

- `00-SUMMARY.md` — ADRs, key decisions.
- Соответствующая стадия из `CONTINUATION-PROMPT.md` (если есть).
- Глубокие отчёты по domain (e.g. `02-architecture.md`, `04-api-design.md`).

### Step 4: Spawn implementation team

`TeamCreate(team_name="build-{topic}")`. Структура — как в [`team`](../team/SKILL.md).

#### Allocation

- **backend-dev**: схема, stores, services, workers.
- **frontend-dev**: pages, hooks, components.
- **agent-dev** (если плановая работа с агентами/orchestration): executor, messaging.
- **test-writer**: тесты для всех слоёв.

(Названия — иллюстративные. Реальный набор зависит от того, что в плане.)

#### Teammate prompt

```
You are {role} implementing Phase {N} of "{topic}".

## Required Reading (in this order)

1. {project root}/CLAUDE.md — project rules, conventions, build commands
2. {research-dir}/00-SUMMARY.md — research summary + ADRs
3. {research-dir}/IMPLEMENTATION-PLAN.md — YOUR tasks in Phase {N}
4. {research-dir}/{relevant detail report}.md — domain context (если есть)

## Your Tasks (from PLAN, Phase {N})

{paste task table from IMPLEMENTATION-PLAN}

## Acceptance Criteria

{paste from PLAN}

## Project Rules

Follow CLAUDE.md. Plus, specifically:
- {rule 1 — extracted from PLAN или CLAUDE.md}
- {rule 2}
- {rule 3}

## Your Files (strict ownership)

NEW:
- {paths from PLAN file ownership map}

MODIFY:
- {paths}

READ-ONLY (study, don't edit):
- {paths}

## Verification

After completing all tasks:
- Run project's typecheck (e.g., `npm run typecheck`, `pnpm -r exec tsc --noEmit`, `mypy`, `cargo check`)
- Run project's tests for affected packages
- Run project's build for affected packages

Report failures, do not declare done while red.

## After completion

Report back with:
- Files created / modified (paths + LOC)
- Tests added (count, what they cover)
- Verification results (typecheck/tests/build)
- Any blockers or discovered tech debt
- Updated TODO entries (mark [x] for done, add [ ] for gaps)
```

### Step 5: Monitor & coordinate

- Track task completion (TaskList).
- Когда backend-dev закончил stores → unblock frontend-dev для hooks.
- Когда test-writer'у нужны types → дождись backend.
- Handle blockers, перепланируй задачи если нужно.

### Step 6: Verify

Команды зависят от стека (читай `CLAUDE.md` или `package.json/Cargo.toml/pyproject.toml`):

```bash
# JavaScript/TypeScript monorepo:
pnpm -r exec tsc --noEmit
pnpm --filter "{affected-pkgs}" build
pnpm --filter "{affected-pkgs}" test

# Python:
mypy {affected-modules}
pytest {affected-tests}

# Rust:
cargo check --all
cargo test {affected-crate}

# Adapt under project's actual commands.
```

Все три обязательны: typecheck, build, test. Если что-то red — не объявляй фазу готовой.

### Step 7: Update docs

1. **TODO files** — `[x]` для completed, `[ ]` для gaps.
2. **KNOWN-ISSUES.md** — если найдены баги в процессе.
3. **RFC** (если есть) — `Implementation Log` + `Sprint Insights`. См. [`rfc`](../rfc/SKILL.md).
4. **Memory** (если доступна):

   ```
   memory_retain("# Build: {topic} — Phase {N} Complete (YYYY-MM-DD)
   Implemented: {list}
   Tests: {count} passing
   Gaps remaining: {list}
   Key decisions: {ADRs from research}")
   ```

### Step 8: Cleanup

Shutdown teammates → `TeamDelete()`. См. cleanup checklist в [`team`](../team/SKILL.md).

---

## Phase Selection Strategies

### Parallel phases

Если в `IMPLEMENTATION-PLAN.md` фазы без deps:

```
Phase 1 (frontend) + Phase 2 (backend) → параллельно
Phase 3 (зависит от Phase 2) → sequential после Phase 2
```

### Incremental build

Для больших планов (7+ фаз):

```
Session 1: Phase 1 + 2 (foundation)
Session 2: Phase 3 + 4 (features) — use CONTINUATION-PROMPT Stage 2
Session 3: Phase 5 + 6 (advanced) — Stage 3
Session 4: Phase 7 (UI polish) — Stage 5
```

Каждая сессия — отдельный TeamCreate, чтобы не разрастался token usage.

### Single-phase focus

Быстрая итерация на одну фазу:

```
build research/reports/{dir} --phase 1
```

---

## Anti-patterns

| Anti-Pattern | Почему | Делай иначе |
|---|---|---|
| Build без чтения research | Missing context, wrong patterns | ALWAYS read 00-SUMMARY + relevant detail reports |
| Игнор ADR | Контр-решения research'у | Следуй ADR как закону |
| Все фазы сразу | Context overflow | 2-3 фазы на сессию |
| Не verify после каждой | Cascade failures | typecheck + test после каждой фазы |
| Frontend перед backend types | Типы не сошлись | Backend → types → frontend |
| Не апдейтим TODO/RFC | Знания теряются | Step 7 — обязателен |

---

## Связанные скиллы

- [`research`](../research/SKILL.md) — производит `IMPLEMENTATION-PLAN.md`.
- [`team`](../team/SKILL.md) — фундамент.
- [`sprint`](../sprint/SKILL.md) — альтернатива, когда плана ещё нет.
- [`audit`](../audit/SKILL.md) — после билда.
- [`rfc`](../rfc/SKILL.md) — обновление RFC.
- [`do`](../do/SKILL.md) — чейнит research → build → audit.
