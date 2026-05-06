---
name: briefing
description: Утренний briefing по задачам и сообщениям — собирает overdue, due today, @mentions, unread chats, project stats из доступного task tracker (Orchestra MCP, Linear MCP, Jira MCP, GitHub Issues) или из локальных TODO-файлов. Используется в начале рабочего дня или когда пользователь спрашивает «что у меня сегодня», «что висит», «morning standup». Триггеры (EN/RU) — "daily briefing", "what's on my plate", "morning standup", "что у меня сегодня", "что висит", "брифинг", "standup", "/briefing".
---

# Daily Briefing

10-секундный утренний снимок: overdue, today, @mentions, unread, статистика проектов.
Скилл — task-tracker-agnostic: работает с любым доступным MCP (Orchestra, Linear, Jira,
Asana, GitHub Issues) или, в крайнем случае, с локальными TODO-файлами проекта.

---

## Когда использовать

- Старт рабочего дня — пользователь хочет одной командой увидеть, на что обратить внимание.
- Пользователь спрашивает: «что у меня сегодня», «что висит», «standup», «брифинг», «что нового».
- Опциональный фокус — название проекта или режим `urgent` (только overdue + mentions + unread).

## Когда НЕ использовать

- Нужен code-context, а не task-context — используй [`restore`](../restore/SKILL.md).
- Нет ни одного task tracker'а и нет TODO-файлов — скилл не сможет сделать briefing, скажи об этом и предложи альтернативу.
- Пользователь хочет полный обзор проекта (архитектура, прогресс по RFC) — это [`research`](../research/SKILL.md).

---

## Обнаружение источника данных (mandatory first step)

Перед сбором данных выясни, **какой источник доступен** — перечислены по приоритету:

| Источник | Как обнаружить | Инструменты |
|---|---|---|
| **Orchestra MCP** | `mcp__orch__*` или `mcp__orchestra__*` присутствуют | `get_current_context`, `get_workspace_overview`, `get_unread_chats`, `get_mentions`, `query_entities` |
| **Linear MCP** | `mcp__linear__*` доступен | `list_my_issues`, `list_assigned_issues` |
| **Jira MCP** | `mcp__jira__*` или `mcp__atlassian__*` | `search_issues`, `get_my_issues` |
| **GitHub Issues** | `gh` CLI в PATH (через Bash) | `gh issue list --assignee @me --state open` |
| **Локальные TODO** | Файлы `TODO.md`, `TODO_*.md`, `**/docs/TODO.md` | Read + Grep |

Если ничего не найдено — кратко скажи пользователю и предложи указать источник или использовать [`restore`](../restore/SKILL.md).

---

## Входные данные

`$ARGUMENTS` — опциональный модификатор:

- пусто → полный briefing.
- `urgent` → только overdue + @mentions + unread.
- название проекта → фильтр по проекту.
- `full` → всё включая starred / saved.

---

## Процесс

### 1. Параллельный сбор (источник-зависимый)

#### Если Orchestra MCP доступен:

```
mcp__orch__get_current_context()
mcp__orch__get_workspace_overview()
mcp__orch__get_unread_chats()
mcp__orch__get_mentions()
mcp__orch__get_reminders()
mcp__orch__get_starred_messages()
mcp__orch__query_entities(repoType="folder", repoUid="today")
mcp__orch__query_entities(repoType="folder", repoUid="expired")
mcp__orch__query_entities(repoType="folder", repoUid="assigned_to_me")
mcp__orch__query_entities(repoType="folder", repoUid="recently_completed")
```

Все запросы — в одном tool-call message (они независимы).

#### Если Linear / Jira / GitHub Issues:

Аналогично — параллельные вызовы соответствующих инструментов:

- мои назначенные таски, статус Open
- overdue (фильтр по due date < сегодня)
- recently completed за 7 дней
- упоминания в комментариях (если поддерживается)

#### Если только локальные TODO:

```bash
# найди все TODO-файлы
find . -maxdepth 4 -name "TODO*.md" -not -path "*/node_modules/*" -not -path "*/.git/*"
```

Прочти их и парси:

- `[ ]` без даты → backlog
- `[ ]` с датой `(YYYY-MM-DD)` в прошлом → overdue
- `[ ]` с датой = today → due today
- `[x]` — completed (за последние 7 дней по git blame, если хочешь точно)

### 2. Применение фильтра (`$ARGUMENTS`)

- `urgent` → только Overdue + Unread + Mentions + Recommended Actions.
- название проекта → фильтрация всех секций по проекту.
- пусто/`full` → всё.

### 3. Презентация

Формат вывода — таблицы с фиксированными колонками:

```markdown
# Daily Briefing — $DATE

**Источник**: $SOURCE  | **User**: $USER

---

## Срочное внимание

### Overdue ($COUNT)
| Task | Project | Due | Days Late | Priority |

### Unread ($COUNT)
| Chat | Type | Unread | Last Message |

### @Mentions ($COUNT)
| From | In | Message | When |

---

## Сегодня

### Due Today ($COUNT)
| Task | Project | Status | Priority |

### Assigned to Me ($COUNT)
| Task | Project | Status | Priority |

---

## Project Status
| Project | Total | Backlog | To Do | Doing | Review | Done |

---

## Quick Stats
| Метрика | Count |
| Total active tasks | N |
| Assigned to me | N |
| Due today | N |
| Overdue | N |
| Recently completed (7d) | N |

---

## Recommended Actions

1. **[Priority]** [action] — [reason]
2. **[Priority]** [action] — [reason]
```

Пустые секции (0 items) — **не выводи**, кроме Quick Stats (всегда).

### 4. Recommended Actions — логика

- Overdue → «Update or close: …».
- Unread (>5) → «Read most active chat: …».
- @Mentions → «Reply: …».
- Tasks в "Doing" >3 дней → «Move to Review or close: …».
- Reminders due today → напомни.

---

## Режимы (через `$ARGUMENTS`)

### `urgent`

Только Overdue + Unread + Mentions + Recommended. Идеально, когда пользователь забегает «между делом».

### Имя проекта (e.g. `Development`)

Все секции, но отфильтрованные по проекту. Используй native фильтр источника (Orchestra `repoType="project"`, Linear `team`, Jira `project=`).

### `full`

Всё, включая starred / reminders / saved. По умолчанию — компактный режим без них.

---

## Связанные скиллы

- [`restore`](../restore/SKILL.md) — code-side восстановление контекста (git, memory).
- [`do`](../do/SKILL.md) — после briefing'а часто запускают конкретную задачу.

## Anti-patterns

- **Не выдумывай задачи**, если ни одного источника нет — лучше честно сказать «нет данных».
- **Не выводи 50 строк, когда 5** — режим `urgent` существует для этого.
- **Не рекомендуй действий «вообще»** — рекомендация без конкретного task UID/ссылки бесполезна.
