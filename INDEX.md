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

- [bootstrap-claude-project](skills/bootstrap-claude-project/SKILL.md) — разворачивает авторский стартовый скаффолд (CLAUDE.md + guides/) в новом или существующем проекте.

## Агенты (`agents/`)

_Пока пусто. Шаблон и правила — `agents/README.md`._

## Slash-команды (`commands/`)

_Пока пусто. Шаблон и правила — `commands/README.md`._

## Промпты (`prompts/`)

_Пока пусто. Шаблон и правила — `prompts/README.md`._

## Темплейты (`templates/`)

_Пока пусто. Шаблон и правила — `templates/README.md`._

## Сниппеты (`snippets/`)

_Пока пусто. Шаблон и правила — `snippets/README.md`._

## Скрипты (`scripts/`)

- [install-skill.sh](scripts/install-skill.sh) — устанавливает skill в `~/.claude/skills/` (по умолчанию симлинк; флаги `--copy`, `--force`, `--dry-run`).
