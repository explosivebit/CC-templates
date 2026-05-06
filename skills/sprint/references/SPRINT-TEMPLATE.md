# Sprint Template Reference

**This file is the TEMPLATE for `/sprint` command output.**
The agent MUST follow this structure when generating sprint plans.

---

> **Терминология**: Фича = **Agent Teams**. Создание команды = `TeamCreate` (tool). Удаление = `TeamDelete` (tool). Env: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

> **!!! CRITICAL — IRON RULE — READ BEFORE ANYTHING !!!**
>
> **`TeamCreate` — ЕДИНСТВЕННЫЙ СПОСОБ ЗАПУСКА. БЕЗ ИСКЛЮЧЕНИЙ.**
>
> - `TeamCreate` — ВСЕГДА. `Task()` напрямую — НИКОГДА.
> - **Team-lead** = ТОЛЬКО координация. НЕ ПИШЕТ КОД. НЕ РЕДАКТИРУЕТ ФАЙЛЫ. ТОЧКА.
> - **Teammates** = ВСЯ работа. Каждый в СВОЁМ процессе, СВОЙ контекст.
> - Доп. работа → НОВЫЙ teammate. НЕ нагружай существующих.
> - Перед `TeamCreate` → ПРОВЕРИТЬ старые команды → СПРОСИТЬ пользователя → `TeamDelete`.
> - **НЕ удалять команды молча** — всегда спрашивай пользователя!
>
> **Нарушение этого правила = провал спринта.**

---

## Template Structure

```
# {Title} — Wave {N-M} Sprint

## Контекст
- Ветка: `{branch}`
- RFC: `{rfc-path}` (if applicable)
- TODO: `{todo-path}` (line range if known)

## Что уже сделано
✅ {Phase/item 1} ({summary — LOC, tests, key deliverables})
✅ {Phase/item 2} (...)

## Оставшаяся работа

### {Category 1}: {name} (~{total LOC})
- {sub-task A} (~{LOC}, {N} components/files)
- {sub-task B} (~{LOC}, {N} components/files)

### {Category 2}: {name} (cleanup/bugs/polish)
- [ ] {task} (~{LOC}) — `{file-path}`

## Существующие ресурсы (ИЗУЧИТЬ перед написанием!)

| Файл | Что есть | Переиспользовать |
|------|----------|-----------------|
| `{path}` | {description} | {how to reuse} |
| `{path}` | {description} | {how to reuse} |

## Волны

### Wave {N} — {Name}: {summary} ({M} агентов параллельно)

**Agent {i}: `{kebab-name}`** (subagent_type: `{type}`)
- Файлы: {NEW/MODIFY}
  - `{path}` (~{LOC})
  - `{path}` (~{LOC})
- Задача: {one-line summary}
  - Изучить: {2-4 files to read FIRST}
  - Создать: {what to build — bullet points}
  - Requirements: {constraints — 2-4 items}

### Wave {N+1} — ... (follows same pattern)

## Зависимости

Wave N: [agent-a] [agent-b] [agent-c] — параллельно
                    ↓
Wave N+1: [agent-d] [agent-e] — параллельно
           ↑ depends on {what from previous wave}

## Ключевые файлы

| Файл | Зачем |
|------|-------|
| `{path}` | {reason to study} |

## !!! EXECUTION — ЖЕЛЕЗНОЕ ПРАВИЛО !!!

> **⛔ ЗАПРЕЩЕНО**: Task() напрямую, team-lead пишет код, teammate получает чужие задачи
> **✅ ОБЯЗАТЕЛЬНО**: TeamCreate → team-lead (координация) → teammates (код)

### TeamCreate — ЕДИНСТВЕННЫЙ способ запуска. БЕЗ ИСКЛЮЧЕНИЙ.
1. **Проверить** существующие команды ("sprint-*", "wave-*"):
   - Есть команда → проверить состояние (закончена? зависла? активна?)
   - **СПРОСИТЬ пользователя** перед удалением: "Команда '{name}' — {статус}. Удалить?"
   - Пользователь подтвердил → **TeamDelete** | Отказал → спросить что делать
2. **TeamCreate**: "sprint-{topic}" или "wave-{topic}"
3. **Team-lead** = ТОЛЬКО координация:
   - НЕ пишет код
   - НЕ редактирует файлы
   - НЕ запускает tsc/tests (просит teammates)
   - ТОЛЬКО: spawn → monitor → verify → report → next wave
4. **Teammates** = ВСЯ работа:
   - Каждый в СВОЁМ процессе, СВОЙ контекст
   - ТОЛЬКО свои файлы — никаких конфликтов

### Dynamic Teammates — НОВЫЙ teammate на КАЖДУЮ доп. задачу
- Обнаружен баг, недостающий файл, нужен рефактор? → НОВЫЙ teammate
- **ЗАПРЕЩЕНО** добавлять работу существующему teammate
- Новый teammate = отдельный процесс, свой контекст, свои файлы
- Team-lead ждёт ALL teammates (оригинальные + новые) перед закрытием wave

## Правила

1. Каждый агент ТОЛЬКО свои файлы — никаких конфликтов
2. Follow CLAUDE.md project rules (APIError, getTenantIdStrict, etc.)
3. {sprint-specific rule 1}
4. {sprint-specific rule 2}
5. 0 новых TS ошибок

## Post-Sprint: Insights Extraction (ОБЯЗАТЕЛЬНО!)

**После завершения ВСЕХ волн, team-lead ОБЯЗАН собрать и задокументировать:**

### В RFC файл (секция Implementation Log → "Sprint Insights & Bottlenecks"):
- **Архитектурные решения (ADR)**: union type cascades, local vs cross-package interfaces, DI patterns, config chains
- **Узкие места**: stale dist/, agent context overflow, cascading TS errors, performance bottlenecks
- **Technical Debt**: что не успели, заглушки (stubs), что нужно доделать следующим спринтом

### В TODO_PHASE_TWO.md (секция "Sprint Insights & Technical Debt"):
| # | Задача | RFC | Приоритет | Почему важно |
|---|--------|-----|-----------|-------------|
| 1 | ...    | ... | P1/P2     | ...         |

### В KNOWN-ISSUES.md (если обнаружены баги)

### В Hindsight (memory_retain):
- Все ADR + tech debt + паттерны для переиспользования

### В финальном отчёте пользователю:
- Отдельный блок "Insights & Technical Debt" (НЕ прятать в summary)

**ПРАВИЛО**: Спринт БЕЗ блока инсайтов = НЕЗАВЕРШЁННЫЙ спринт.

## Effort Summary

| Wave | Agents | LOC | Tests | Description |
|------|--------|-----|-------|-------------|
| {N}  | {M}    | ~{X} | {Y}  | {summary}  |
| **Total** | **{M}** | **~{X}** | **{Y}** | {overall} |
```

---

## Real Example (RFC-080 Wave 9-12)

Below is a REAL example from RFC-080 sprint. Use this as reference for density, detail level, and structure.

```markdown
# RFC-080 Wave 9-12 Sprint — Phase 5 Command Center + Cleanup

## Контекст

Ветка: `feat/RFC-080-chat-agent-platform`
RFC: `apps/pipeline/docs/RFC-080-CHAT-AGENT-PLATFORM.md`
TODO: `apps/pipeline/docs/TODO_PHASE_TWO.md` (строка 2300+)

## Что уже сделано (Wave 1-8)

✅ Phase 0 — Schema + Stores (8 tables, 5 stores, 323 tests)
✅ Phase 1 — Backend Wiring (memory-bridge, provenance, completions, folders)
✅ Phase 1.5 — Frontend Wiring (useGertsChat, transport, gsp-parser, 125 tests)
✅ Phase 2 — Graph Memory (RRF, BM25, SpreadingActivation, 38 tests)
✅ Phase 3 — Agent System (tree, skills, builtins, MCP, 73 tests)
✅ Phase 4 — UI/UX ~95% (Chat, Agent, Memory, Model, Observe wired, 96+ tests)

## Оставшаяся работа

### Phase 5: Command Center (~2,670 LOC)

- 5A: AI Sidebar (~530 LOC, 7 components)
- 5B: Enhanced ⌘K (~360 LOC, 5 components)
- 5C: Full AI Assistant Page (~1,010 LOC, 9 components)
- 5D: Admin Tools Integration (~270 LOC, 4 components)
- 5E: Polish (~300 LOC, 4 components)

### Cleanup:

- [ ] Wire compact views (~60 LOC) — `ContextPanel.tsx`

## Существующие ресурсы

| Файл                                      | Что есть              | Переиспользовать        |
| ----------------------------------------- | --------------------- | ----------------------- |
| `features/ai-chat/ui/ChatLayout.tsx`      | 3-panel chat layout   | Layout pattern          |
| `features/ai-chat/ui/ChatComposer.tsx`    | Input с file uploads  | Composer для sidebar    |
| `features/ai-chat/hooks/useGertsChat.ts`  | GSP streaming hook    | Core chat hook          |
| `features/ai-chat/hooks/useChats.ts`      | CRUD conversations    | Conversation management |
| `features/ai-chat/model/chat-ui-store.ts` | Zustand chat store    | UI state pattern        |
| `shared/ui/command-palette.tsx`           | ⌘K Level 1 (36 items) | Base для enhanced ⌘K    |

## Волны

### Wave 9 — Foundation: Stores + Hooks (3 агента параллельно)

**Agent 1: `foundation-stores`** (subagent_type: `general-purpose`)

- Файлы: NEW
  - `widgets/ai-sidebar/model/store.ts` (~40 LOC)
  - `shared/lib/use-page-context.ts` (~50 LOC)
  - `shared/lib/use-global-search.ts` (~40 LOC)
  - `features/admin/ai/model/preferences.ts` (~40 LOC)
- Задача: Zustand stores + shared hooks
  - Изучить: `chat-ui-store.ts`, `command-palette.tsx`
  - Создать: AI Sidebar Store (isOpen, mode, toggle), usePageContext (route parsing),
    useGlobalSearch (TanStack Query), Chat Preferences (persist)
  - Requirements: No getters in Zustand state. 0 TS errors

**Agent 2: `compact-views-fix`** (subagent_type: `general-purpose`)

- Файлы: MODIFY `ContextPanel.tsx`
- Задача: Wire compact views to existing hooks
  - Изучить: `ContextPanel.tsx`, `useMessageMemory.ts`, `useMessageGraph.ts`, `useMessageTrace.ts`
  - Создать: Wire MemoryContent → facts count, GraphContent → entities count,
    TraceContent → steps count + duration
  - Requirements: ~60 LOC. 0 TS errors

**Agent 3: `assistant-hooks`** (subagent_type: `general-purpose`)

- Файлы: MODIFY `features/admin/ai/hooks.ts`
- Задача: Extend AI hooks for assistant page
  - Изучить: `hooks.ts`, `useGertsChat.ts`, `useChats.ts`
  - Создать: useAIChat (wrapper), useConversationSearch, useRecentConversations,
    useMessageActions (copy, regen, edit, delete)
  - Requirements: TanStack Query + authFetch. ~150 LOC. 0 TS errors

---

### Wave 10 — AI Sidebar + Enhanced ⌘K (3 агента параллельно)

**Agent 4: `ai-sidebar`** (subagent_type: `general-purpose`)

- Файлы: NEW `widgets/ai-sidebar/ui/AISidebar.tsx` (~200 LOC), MODIFY DashboardLayout
- Задача: AI Sidebar widget — fixed right panel, slides in/out
  - Изучить: store from Wave 9, ChatComposer, useGertsChat, MessageList
  - Создать: AISidebar (header + messages + input), wire into DashboardLayout,
    Cmd+Shift+A shortcut, page context badge
  - Requirements: Reuse MessageParts, ModelSelector. Dark theme. 0 TS errors

**Agent 5: `enhanced-cmdk`** (subagent_type: `general-purpose`)

- Файлы: MODIFY `shared/ui/command-palette.tsx`
- Задача: 4 modes for ⌘K (Navigate, Search, Action, AI)
  - Изучить: `command-palette.tsx`, `use-global-search.ts` from Wave 9
  - Создать: Mode detection by prefix (none/`/`/`>`/`?`), mode indicator badge,
    search results, action list, inline AI streaming
  - Requirements: ~360 LOC additions. 0 TS errors

**Agent 6: `chat-components`** (subagent_type: `general-purpose`)

- Файлы: NEW `features/admin/ai/ui/chat-message.tsx` (~100 LOC), `provenance-badge.tsx` (~60 LOC)
- Задача: Shared AI chat UI components
  - Изучить: `MessageParts.tsx`, `ModelSelector.tsx`, `SourcesWide.tsx`
  - Создать: ChatMessage (lightweight bubble), ProvenanceBadge (source count + tooltip).
    Re-export ModelSelector if existing one fits
  - Requirements: THIN wrappers, reuse ai-chat. 0 TS errors

---

### Wave 11 — Full Assistant Page + Admin Tools (4 агента параллельно)

**Agent 7: `assistant-lists`** (subagent_type: `general-purpose`)

- Файлы: NEW `features/admin/ai/ui/conversation-list.tsx` (~200 LOC), `folder-list.tsx` (~80 LOC)
- Задача: Conversation list + Folder management
  - Изучить: `ChatSidebar.tsx`, `useChats.ts`, `useFolders.ts`
  - Создать: ConversationList (grouped by time, search, context menu),
    FolderList (collapsible, drag-drop, count badge)
  - Requirements: Reuse hooks from ai-chat. 0 TS errors

**Agent 8: `assistant-chat-area`** (subagent_type: `general-purpose`)

- Файлы: NEW `features/admin/ai/ui/chat-area.tsx` (~250 LOC), `message-actions.tsx` (~80 LOC)
- Задача: Full chat area + message actions toolbar
  - Изучить: `ChatLayout.tsx`, `MessageList.tsx`, `ChatComposer.tsx`, `useGertsChat.ts`
  - Создать: ChatArea (orchestrator — messages + composer + streaming + header),
    MessageActions (Copy, Regenerate, Edit, Delete hover toolbar)
  - Requirements: MAX reuse from ai-chat (import, NOT copy). 0 TS errors

**Agent 9: `assistant-panels`** (subagent_type: `general-purpose`)

- Файлы: NEW `features/admin/ai/ui/provenance-panel.tsx`, `memory-facts.tsx`,
  `app/(dashboard)/ai/assistant/page.tsx`, `layout.tsx`
- Задача: Side panels + route setup
  - Изучить: `SourcesWide.tsx`, `MemoryWide.tsx`, `useProvenance.ts`
  - Создать: ProvenancePanel (sources with scores), MemoryFacts (timeline),
    Route /ai/assistant (page + layout)
  - Requirements: Panels toggle on/off. Reuse ai-chat hooks. 0 TS errors

**Agent 10: `admin-tools`** (subagent_type: `general-purpose`)

- Файлы: NEW `features/admin/ai/lib/tools.ts` (~100 LOC), `ui/tool-result.tsx`, `ui/tool-confirm.tsx`
- Задача: Admin tools integration (navigate, search, create)
  - Изучить: `ToolCallBlock.tsx`, `command-palette.tsx`, `packages/tools/src/`
  - Создать: Tool Registry (Map<string, AdminTool>), ToolResult renderer,
    ToolConfirm dialog, NavigateTool handler
  - Requirements: Destructive tools require confirmation. 0 TS errors

---

### Wave 12 — Polish + Tests + Docs (3 агента параллельно)

**Agent 11: `keyboard-shortcuts`** (subagent_type: `general-purpose`)

- Файлы: NEW `shared/lib/use-keyboard-shortcuts.ts` (~80 LOC),
  `features/admin/ai/ui/mention-autocomplete.tsx` (~100 LOC)
- Задача: Global shortcuts + @mention autocomplete
  - Изучить: `command-palette.tsx`, `ChatComposer.tsx`
  - Создать: useKeyboardShortcuts (registry, Cmd+K/Cmd+Shift+A/Cmd+Shift+N/Escape),
    MentionAutocomplete (@trigger → fuzzy dropdown)
  - Requirements: No conflicts with browser defaults. 0 TS errors

**Agent 12: `polish-ui`** (subagent_type: `general-purpose`)

- Файлы: MODIFY `observe/cost/page.tsx`, NEW `features/admin/ai/ui/agent-marketplace.tsx`
- Задача: Cost dashboard refinements + marketplace placeholder
  - Изучить: `CostDashboard.tsx`, `features/admin/agents/`
  - Создать: Sparkline charts, model breakdown, budget alert.
    Marketplace placeholder (grid of "coming soon" cards)
  - Requirements: 0 TS errors

**Agent 13: `tests-docs`** (subagent_type: `general-purpose`)

- Файлы: NEW `__tests__/hooks.test.ts`, `__tests__/store.test.ts`,
  MODIFY `TODO_PHASE_TWO.md`, `RFC-080.md`
- Задача: Tests (~26) + docs update
  - Tests: hooks (12), sidebar store (8), preferences (6) — Vitest
  - Docs: mark Phase 5 done, update status to ~98%

---

## Зависимости

Wave 9: [foundation-stores] [compact-views-fix] [assistant-hooks] — параллельно
↓
Wave 10: [ai-sidebar] [enhanced-cmdk] [chat-components] — параллельно
↑ depends on stores from Wave 9
↓
Wave 11: [assistant-lists] [assistant-chat-area] [assistant-panels] [admin-tools] — параллельно
↑ depends on hooks + components from Wave 10
↓
Wave 12: [keyboard-shortcuts] [polish-ui] [tests-docs] — параллельно

## Ключевые файлы

| Файл                                      | Зачем               |
| ----------------------------------------- | ------------------- |
| `features/ai-chat/hooks/useGertsChat.ts`  | Core streaming hook |
| `features/ai-chat/model/chat-ui-store.ts` | Zustand pattern     |
| `shared/ui/command-palette.tsx`           | Existing ⌘K         |
| `app/(dashboard)/layout.tsx`              | Dashboard layout    |

## !!! EXECUTION — ЖЕЛЕЗНОЕ ПРАВИЛО !!!

> **⛔ Task() напрямую = ЗАПРЕЩЕНО. Team-lead пишет код = ЗАПРЕЩЕНО.**

### TeamCreate (ЕДИНСТВЕННЫЙ способ запуска)

1. Проверить существующие команды → если есть:
   - Определить статус (закончена/зависла/активна)
   - **СПРОСИТЬ пользователя**: "Команда '{name}' — {статус}. Удалить через TeamDelete?"
   - Только после подтверждения → **TeamDelete** → **TeamCreate**: "sprint-rfc080-phase5"
2. **Team-lead**: ТОЛЬКО координация — НЕ пишет код, НЕ редактирует файлы, ТОЧКА
3. **Teammates**: ВСЯ работа — каждый в СВОЁМ процессе, СВОЙ контекст
4. Доп. работа → НОВЫЙ teammate (НЕ нагружай существующих)
5. Team-lead ждёт ALL teammates перед закрытием wave

## Правила

1. Каждый агент ТОЛЬКО свои файлы
2. Follow CLAUDE.md rules (APIError, getTenantIdStrict, etc.)
3. ПЕРЕИСПОЛЬЗУЙ из `features/ai-chat/` — import, не copy
4. Zustand: НЕ использовать getters в state (use selectors)
5. Dark theme: bg-[#0a0a0b], border-[#27272a], text-[#ededed]
6. 0 новых TS ошибок. Vitest, не Jest

## Effort Summary

| Wave      | Agents | LOC        | Tests   | Description                              |
| --------- | ------ | ---------- | ------- | ---------------------------------------- |
| 9         | 3      | ~440       | 0       | Foundation: stores, hooks, compact views |
| 10        | 3      | ~790       | 0       | AI Sidebar + Enhanced ⌘K + components    |
| 11        | 4      | ~1,160     | 0       | Full Page + Admin Tools                  |
| 12        | 3      | ~560       | ~26     | Polish + Tests + Docs                    |
| **Total** | **13** | **~2,950** | **~26** | Phase 5 Command Center                   |
```

---

## Agent Description Guidelines

Each agent description should follow this compact format (80-120 words):

```
**Agent {i}: `{name}`** (subagent_type: `{type}`)
- Файлы: {NEW/MODIFY} `{path}` (~{LOC})
- Задача: {one-line what}
  - Изучить: {2-4 files — comma separated}
  - Создать: {what to build — comma separated items}
  - Requirements: {2-4 constraints — comma separated}
```

### DO:

- Use comma-separated lists (not bullet sub-points)
- Reference specific file paths (not vague "the auth module")
- Include LOC estimate per file
- Mark files as NEW or MODIFY
- Include "0 TS errors" in every requirements

### DON'T:

- Don't repeat rules from CLAUDE.md (just say "Follow CLAUDE.md")
- Don't describe implementation details (agent will figure it out from the files)
- Don't write >3 lines for "Создать"
- Don't include API schemas or type definitions in the description

---

## Scaling Guidelines

| Sprint Size        | Waves                | Agents/Wave | Total Agents | Approach                                     |
| ------------------ | -------------------- | ----------- | ------------ | -------------------------------------------- |
| Small (~500 LOC)   | 1-2                  | 2-3         | 2-4          | TeamCreate ОБЯЗАТЕЛЬНО (даже для маленьких!) |
| Medium (~1-2K LOC) | 2-3                  | 2-4         | 5-8          | TeamCreate with team-lead                    |
| Large (~3-5K LOC)  | 3-5                  | 3-4         | 10-15        | TeamCreate, verify between waves             |
| XL (>5K LOC)       | Split into 2 sprints | —           | —            | `/sprint` twice                              |

## Wave Pattern Cheat Sheet

| Task Type          | Wave Pattern                                   |
| ------------------ | ---------------------------------------------- |
| Full-stack feature | Stores/Types → Backend → Frontend → Tests      |
| UI-only feature    | Stores/Hooks → Components → Pages → Tests      |
| Backend-only       | Schema/Types → Services → Actions → Tests      |
| Refactor           | Foundation → Migration → Integration → Cleanup |
| Bug sprint         | Research → Fixes → Verification → Docs         |
