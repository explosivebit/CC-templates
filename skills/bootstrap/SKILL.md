---
name: bootstrap
description: Разворачивает авторский стартовый скаффолд Claude Code в новом или существующем проекте — создаёт CLAUDE.md по шаблону, папку guides/ с авторскими гайдами (Git Flow, CLAUDE.md best practices) и guides/INDEX.md. Используется, когда пользователь начинает новый проект и хочет поставить стандартную базу Claude Code, либо добавляет эти гайды в существующий проект. Триггеры (EN/RU) — "bootstrap project", "init claude baseline", "install my guides", "scaffold claude code", "поставь мои гайды", "разверни базу", "установи базовый CLAUDE.md", "подготовь проект под claude", "засетапь проект".
---

# Bootstrap Claude Project

Разворачивает в текущем проекте базовый набор артефактов Claude Code:
`CLAUDE.md`, `guides/` с авторскими гайдами, `guides/INDEX.md`.

Ресурсы skill'а живут рядом с этим SKILL.md, в `resources/`:

```
~/.claude/skills/bootstrap/
├── SKILL.md           ← ты сейчас читаешь
└── resources/
    ├── guides/
    │   ├── CLAUDE-MD-GUIDE.ru.md
    │   ├── GIT-FLOW-GUIDE.ru.md
    │   └── INDEX.md.template
    └── templates/
        └── CLAUDE.md.template
```

Если skill вызван из репо-источника (`CC-templates/skills/bootstrap`),
пути тоже валидны относительно этой же директории — используй абсолютный путь до
директории этого SKILL.md.

---

## Когда использовать

- Пользователь начинает новый проект и просит «развернуть базу», «поставить гайды», «bootstrap».
- Существующий проект без `CLAUDE.md` или без `guides/`, пользователь хочет привести к стандарту.
- Пользователь явно упомянул один из триггеров из `description`.

## Когда НЕ использовать

- Текущий cwd — это сам репозиторий `CC-templates` (он и есть источник, скаффолдить его не надо).
  → Проверь по наличию файлов: `CLAUDE.md` + `skills/bootstrap/` в cwd.
- В проекте уже есть `CLAUDE.md` **и** полная `guides/` — нечего делать.
  → Скажи пользователю и выйди.

---

## Входные данные (уточни перед работой)

Спроси единым вопросом три параметра, если пользователь не указал явно:

1. **Target path** — куда ставить. По умолчанию — текущий `pwd`.
2. **Какие гайды** — `all` (по умолчанию) / `git-flow` / `claude-md`.
3. **Что с существующим `CLAUDE.md`** — `skip` (не трогать) / `append` (добавить блок
   «См. гайды») / `replace` (пересоздать по шаблону, старый сохранить как `CLAUDE.md.bak`).
   По умолчанию — `append`. Если `CLAUDE.md` нет — вопрос не задаём, создаём из шаблона.

---

## Процесс

### 1. Ориентация

Выполни:

```bash
pwd
ls -la
git rev-parse --show-toplevel 2>/dev/null || echo "not a git repo"
test -f CLAUDE.md && echo "CLAUDE.md exists" || echo "no CLAUDE.md"
test -d guides && echo "guides/ exists" || echo "no guides/"
```

Проверки:
- Если **нет `.git`** — предупреди пользователя: «гайды подразумевают git, рекомендую `git init -b main` перед продолжением». Спроси, продолжать ли без git.
- Если cwd == корень `CC-templates` (признак: есть `skills/bootstrap/SKILL.md`) — откажись с сообщением «это сам источник, скаффолдить его не нужно».

### 2. Собери план

Сформируй короткий план (3–6 строк): что будет создано, что перезаписано, что пропущено. Покажи пользователю и жди подтверждения.

Пример:
```
Buy-in:
  + CLAUDE.md (создам из шаблона)
  + guides/CLAUDE-MD-GUIDE.ru.md (скопирую)
  + guides/GIT-FLOW-GUIDE.ru.md (скопирую)
  + guides/INDEX.md (создам)
Proceed? [y/n]
```

### 3. Выполнение

**Резолвь абсолютный путь ресурсов.** Используй:
```bash
SKILL_DIR="$HOME/.claude/skills/bootstrap"
test -d "$SKILL_DIR/resources" || SKILL_DIR="<абсолютный путь до этого skill в CC-templates>"
```

Если skill был установлен через симлинк на `CC-templates/skills/bootstrap/`, `$HOME/.claude/skills/bootstrap` сработает. Если skill запускается напрямую из репо (без установки) — используй абсолютный путь до папки, в которой лежит этот SKILL.md.

**Выполни операции по выбранному сценарию:**

- **CLAUDE.md:**
  - Если файла нет → `cp "$SKILL_DIR/resources/templates/CLAUDE.md.template" ./CLAUDE.md`, заменить плейсхолдер `<PROJECT_NAME>` на имя директории проекта (`basename "$PWD"`).
  - Если есть и режим `append` → дописать в конец блок:
    ```
    ## Справочник

    См. [`guides/INDEX.md`](guides/INDEX.md) — Git Flow, CLAUDE.md best practices.
    ```
    (Дедуплицируй: если блок уже есть, пропусти.)
  - Если режим `replace` → `mv CLAUDE.md CLAUDE.md.bak && cp <template> CLAUDE.md`.
  - Если режим `skip` → ничего не делай.

- **guides/ папка:** создай `mkdir -p guides`.

- **Копирование гайдов:**
  - `all` → скопируй оба `.ru.md` из `$SKILL_DIR/resources/guides/` в `./guides/`.
  - `git-flow` → только `GIT-FLOW-GUIDE.ru.md`.
  - `claude-md` → только `CLAUDE-MD-GUIDE.ru.md`.
  - Если в `./guides/` уже есть такой файл — спроси: overwrite / skip / diff. По умолчанию skip.

- **guides/INDEX.md:** из `resources/guides/INDEX.md.template`, оставь строки только для скопированных гайдов.

### 4. Отчёт

Покажи итог:
```
✓ CLAUDE.md            создан
✓ guides/               создана
✓ guides/INDEX.md      создан
✓ guides/GIT-FLOW-GUIDE.ru.md
✓ guides/CLAUDE-MD-GUIDE.ru.md
```

Напомни:
- «Отредактируй `CLAUDE.md` — раздел "Что это за проект" сейчас плейсхолдер.»
- «Если в репо ещё нет коммита — закомить: `git add . && git commit -m "chore: add Claude Code baseline scaffold"`.»

---

## Идемпотентность и безопасность

- **Никогда не перезаписывай существующие файлы без явного подтверждения.**
- При `replace` для CLAUDE.md — всегда сохраняй `CLAUDE.md.bak`.
- **Не коммить автоматически.** Скаффолд оставляет изменения в рабочем дереве, коммит — решение пользователя.
- Не трогай `.git/`, `node_modules/`, `vendor/` и другие служебные директории.

## Ошибки и восстановление

| Симптом | Диагноз | Действие |
|---|---|---|
| `resources/` не найдена | Skill повреждён или не установлен | Сообщи путь, который пробовал, и попроси переустановить через `scripts/install-skill.sh bootstrap`. |
| `guides/<file>.ru.md` уже существует | Идемпотентный повторный запуск | Покажи diff; по умолчанию skip. |
| cwd — `CC-templates` | Запуск в самом источнике | Отказ с сообщением. |

## Ссылки на примеры

См. `examples/full-setup.md` рядом с этим SKILL.md — пример полного диалога.
