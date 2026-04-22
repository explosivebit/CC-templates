# Пример: полный bootstrap нового проекта

Демонстрация диалога, в котором пользователь разворачивает базу в свежесозданной папке.

---

**Пользователь:**
> Поставь мои гайды в этот проект.

**Claude (через skill `bootstrap-claude-project`):**

```
Ориентация:
  cwd: /Users/me/Work/new-api-service
  .git: найдена (ветка main, 0 коммитов)
  CLAUDE.md: отсутствует
  guides/: отсутствует

План:
  + CLAUDE.md                          (из шаблона, плейсхолдер <PROJECT_NAME> → new-api-service)
  + guides/                            (создам)
  + guides/CLAUDE-MD-GUIDE.ru.md       (скопирую)
  + guides/GIT-FLOW-GUIDE.ru.md        (скопирую)
  + guides/INDEX.md                    (создам)

Поехали? [y/n]
```

**Пользователь:**
> y

**Claude:**
```
✓ guides/                                   создана
✓ guides/GIT-FLOW-GUIDE.ru.md               скопирован
✓ guides/CLAUDE-MD-GUIDE.ru.md              скопирован
✓ guides/INDEX.md                           создан
✓ CLAUDE.md                                  создан из шаблона

Следующие шаги:
  - Открой CLAUDE.md, заполни блок «Что это за проект» и «Как работать».
  - Если хочешь зафиксировать базу: git add . && git commit -m "chore: add Claude Code baseline scaffold"
```

---

## Пример: добавить блок гайдов в существующий CLAUDE.md

**Пользователь:**
> У меня уже есть CLAUDE.md, но хочу добавить гайды.

**Claude:**
```
Нашёл существующий CLAUDE.md. Режим: append — добавлю только блок «Справочник»
со ссылкой на guides/INDEX.md. Старый контент не трогаю.

  + guides/ (создам)
  + guides/CLAUDE-MD-GUIDE.ru.md
  + guides/GIT-FLOW-GUIDE.ru.md
  + guides/INDEX.md
  ~ CLAUDE.md (append раздела «Справочник» — если его ещё нет)

Proceed? [y/n]
```

---

## Пример: только git-flow

**Пользователь:**
> Мне нужен только git-flow guide, без CLAUDE.md правил писать.

**Claude:**
```
Режим: только git-flow. CLAUDE.md не трогаю.

  + guides/ (создам)
  + guides/GIT-FLOW-GUIDE.ru.md
  + guides/INDEX.md (только строка про git-flow)

Proceed? [y/n]
```
