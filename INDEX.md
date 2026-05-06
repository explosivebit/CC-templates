# INDEX — карта всех артефактов

Этот файл — «оглавление» репозитория. Добавляешь новый артефакт — добавляешь
сюда одну строку в формате:
`- [название](путь) — одна строка о сути и когда это брать`

Держи строки до ~150 символов, списки отсортированы по алфавиту.

---

## Гайды (`guides/`)

- [CLAUDE-MD-GUIDE](guides/CLAUDE-MD-GUIDE.ru.md) — как писать `CLAUDE.md` с учётом слабостей LLM (U-кривая, cry-wolf, dilution).
- [GIT-FLOW-GUIDE](guides/GIT-FLOW-GUIDE.ru.md) — Git Flow + Conventional Commits + PR + SemVer + safety-правила против AI-деструкции.

## Скиллы (`skills/`)

Каждый скилл автоматически даёт slash-команду `/<имя-папки>`.

- [audit](skills/audit/SKILL.md) — multi-expert review кода/архитектуры (≥4 агента: логика, SOLID, типы, безопасность; синтез + verdict). `/audit`.
- [bootstrap](skills/bootstrap/SKILL.md) — разворачивает авторский стартовый скаффолд (CLAUDE.md + guides/) в новом или существующем проекте. `/bootstrap`.
- [briefing](skills/briefing/SKILL.md) — утренний briefing задач/сообщений из task-tracker (Orchestra/Linear/Jira/GitHub) или локальных TODO-файлов. `/briefing`.
- [build](skills/build/SKILL.md) — запускает имплементационную команду из готового research-отчёта (IMPLEMENTATION-PLAN.md → wave-by-wave). `/build`.
- [do](skills/do/SKILL.md) — мета-оркестратор: парсит задачу, строит pipeline из других скиллов (research → write-doc → sprint → audit), исполняет с approval-чекпойнтами. `/do`.
- [research](skills/research/SKILL.md) — глубокий research 5 параллельными агентами (code, docs, status, reference, knowledge). `/research`.
- [restore](skills/restore/SKILL.md) — восстанавливает контекст сессии: git + рабочая копия + (опц.) persistent memory. `/restore`.
- [rfc](skills/rfc/SKILL.md) — создание/чтение/обновление RFC и ADR: meta header, phase progress, implementation log, ADR. `/rfc`.
- [setup](skills/setup/SKILL.md) — интерактивный wizard для конфигурации проекта: issue tracker / build-команды / paths / domain glossary → пишет в `docs/agents/*.md` (+ создаёт `CONTEXT.md`, `LANGUAGE.md`). Backbone дегерцификации. `/setup`.
- [sprint](skills/sprint/SKILL.md) — волновое исполнение фичи (full sprint с research / lightweight wave из контекста чата) с TeamCreate, file ownership, insights extraction. `/sprint`.
- [team](skills/team/SKILL.md) — фундамент многоагентных команд: TeamCreate vs sub-agents, file ownership, recipes, cleanup. База для других мульти-агентных скиллов. `/team`.

## Агенты (`agents/`)

_Пока пусто. Шаблон и правила — `agents/README.md`._

## Slash-команды (`commands/`)

> ⚠️ **Все команды ниже — старые дубликаты одноимённых скиллов из `skills/`**
> (срезы под gerts.ai до унификации skills/commands в Claude Code 2026).
> Скиллы автоматически дают slash-команды — отдельные файлы здесь не нужны.
> Будут удалены после переноса оставшейся универсальной логики в скиллы.

- [audit](commands/audit.md) — _дубль skill `audit`_, удалить после миграции.
- [briefing](commands/briefing.md) — _дубль skill `briefing`_, удалить после миграции.
- [build](commands/build.md) — _дубль skill `build`_, удалить после миграции.
- [do](commands/do.md) — _дубль skill `do`_, удалить после миграции.
- [recall](commands/recall.md) — _дубль skill `restore`_, удалить после миграции.
- [research](commands/research.md) — _дубль skill `research`_, удалить после миграции.
- [sprint](commands/sprint.md) — _дубль skill `sprint`_, удалить после миграции.
- [team-up](commands/team-up.md) — _дубль skill `team`_, удалить после миграции.
- [wave](commands/wave.md) — _часть skill `sprint`_ (lightweight mode), удалить после миграции.
- [sprint-template](commands/sprint-template.md) — _не команда_, а reference-шаблон; будет перенесён в `skills/sprint/references/`.

## Промпты (`prompts/`)

- [forgeplan-phase-5/](prompts/forgeplan-phase-5/README.md) — пакет брифов для закрытия Phase 5 ForgePlan: engine-brief (Rust), marketplace-brief (контент), daily-usage.

## Темплейты (`templates/`)

_Пока пусто. Шаблон и правила — `templates/README.md`._

## Сниппеты (`snippets/`)

_Пока пусто. Шаблон и правила — `snippets/README.md`._

## Скрипты (`scripts/`)

- [install-skill.sh](scripts/install-skill.sh) — устанавливает skill в `~/.claude/skills/` (по умолчанию симлинк; флаги `--copy`, `--force`, `--dry-run`).
