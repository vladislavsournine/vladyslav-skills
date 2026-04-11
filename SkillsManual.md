# Skills Manual

Короткий практичний гайд по встановлених скілах. Формат: **що робить → коли викликати**.

---

## За завданням

### Старт проекту з нуля

- **`/vladyslav:init-project`** — створює повну Claude-friendly структуру (`docs/`, `.claude/`, `CLAUDE.md`, agents). Детектить стек (Python/Go/Flutter/Swift/Kotlin), генерує skeleton документації.
- Після init'а запусти `/superpowers:brainstorming` щоб обговорити MVP, потім `/vladyslav:add-feature` для першої фічі.

### Приєднання Claude до існуючого проекту

- **`/vladyslav:attach-project`** — додає Claude-структуру до існуючого коду **не ламаючи** файли. Auto-detect стеків.
- **`/vladyslav:analyze-project`** — сканує код, заповнює `docs/architecture/system.md`, `api.md`, `db-schema.sql`, оновлює `CLAUDE.md`.
- **`/vladyslav:seed-mempalace`** — ОДНОРАЗОВО записує ключові архітектурні рішення в MemPalace wing проекту. Після цього майбутні сесії не сканують репу наново.

### Додавання фічі

- **`/vladyslav:add-feature`** — повний цикл: `brainstorm → contract → plan → parallel execution (tests + code) → auto-gate (tests + review + security) → merge → docs update`.
- Автоматично діють: Blast Radius Rule (мінімальні зміни), Contract-First (контракт до коду), Mandatory Code Review (чекліст).
- **Два режими** (скіл питає на старті):
  - **Manual** — stop-and-tell після кожної фази. Для нетипових/ризикових фіч.
  - **Auto** — після апрува контракту і плану все виконується без зупинок (parallel agents → auto-gate → commit → merge to dev). Апрув повертається тільки на merge-to-main або на guard rail.
- **Guard rails (auto-mode автоматично зупиняє + питає):**
  - > 2 файли зачеплені поза планом
  - Рефактор файла що був позначений "read-only reference"
  - Контракт змінився під час виконання (hash mismatch)
  - Auto-gate blocker: впав тест / HIGH-severity review / security finding
- **Auto-gate (перед кожним комітом в auto-mode, без апрува):** тести → code review agent → owasp-security. Блокує коміт при помилках.

### Дизайн-система (щоб новий екран не виглядав як чужий проект)

Правильний порядок: **design-sync → design-page → add-feature**

- **`/vladyslav:design-sync`** — сканує існуючий UI-код, витягує канонічні токени (кольори, typography, іконки, spacing, компоненти), виявляє drift, канонізує через питання до тебе, пише `docs/design/system.md` + MemPalace decision records. Для iOS проектів автоматично запускає `apple-hig-expert` аудит і додає HIG-порушення в §8 drift log. Запускай коли:
  - Перший раз помітив що новий екран не схожий на старий
  - Після `init-project` коли вже є 2-3 екрани
  - Перед major design refresh (канонізувати що є → планувати що змінюємо)
  - Періодично на активних проектах щоб ловити дрейф

- **`/vladyslav:design-page`** — після того як `docs/design/system.md` затверджений, проектує **всі екрани в Pencil паралельно** (окремий субагент на кожен екран). Full-auto: зупиняється лише якщо потрібен новий токен або помилка Pencil. Запускай коли:
  - Дизайн-напрямок підтверджений (system.md написаний)
  - Маєш список екранів для проектування
  - Хочеш уникнути переповнення контексту від проектування всіх екранів в одній сесії

  **Як працює паралелізм:**
  1. Оркестратор (Opus) попередньо резервує canvas-координати для кожного екрану
  2. Синхронізує Pencil variables з `docs/design/system.md §1` токенами (один раз)
  3. Диспатчить паралельні субагенти (один на екран) — кожен малює у своїй зарезервованій зоні
  4. Кожен субагент пише `docs/design/pages/<screen-name>.md` з рішеннями
  5. Агрегує результати, виводить звіт

  **Full-auto межа:** єдині тверді стопи — відсутній токен (продуктове рішення) або Pencil API error.

- **`apple-hig-expert`** (з `c-level-skills@claude-code-skills`, вже підключений) — iOS HIG аудит: Liquid Glass (2026), Tab Bar nav, 44pt targets, Dynamic Type, Dark Mode, VoiceOver. Використовується автоматично в `design-sync` і в кожному субагенті `design-page`. Можна викликати окремо для аудиту конкретного екрану.

- **Глобальне правило "Design System Discipline"** (в `~/.claude/CLAUDE.md`) — перед будь-якою UI-задачею я зобов'язаний:
  1. Прочитати `docs/design/system.md` як контракт
  2. Просканувати asset catalog за існуючими токенами
  3. **НЕ винаходити** нові кольори / іконки / шрифти / padding — тільки reuse
  4. Якщо потрібен новий токен — СТОП, питаю дозволу, реєструю в `docs/design/system.md`
  5. Якщо дизайн-системи немає — питаю чи запускати `design-sync` чи діяти ad-hoc (не рекомендовано)

- **Template:** порожній канон живе в `~/.vladyslav-skills/templates/DesignSystem.md` — `init-project` пише його автоматично для UI-проектів (swift/flutter/kotlin/web), скіпає для backend-only.

- **Page decisions:** `docs/design/pages/<screen>.md` — рішення кожного субагента для конкретного екрану (відступи від master, вжиті компоненти, знайдені issues). Інспіровано ui-ux-pro-max-skill MASTER + per-page overrides патерном.

### Product Discovery (перед кодом)

- **`/vladyslav:discover`** — монстр-скіл що запускає повний цикл discovery. Питає scope (full / marketing / valuation / competitors / monetization / apple-check), сам послідовно викликає потрібні саб-скіли, наприкінці пише `docs/product/discovery-summary.md`.
- Саб-скіли можна викликати окремо:
  - **`/vladyslav:discover-competitors`** — `c-level-skills:competitive-intel` → секція 6 `start-project.md` + `docs/product/competitors.md`.
  - **`/vladyslav:discover-monetization`** — `cpo-advisor` + `cfo-advisor` → секція 8 `start-project.md`.
  - **`/vladyslav:discover-valuation`** — PMF scorer + `ceo-advisor` → зелений/жовтий/червоний verdict → секція 9.
  - **`/vladyslav:discover-marketing`** — `cmo-advisor` → channel hypothesis, first-100-users, retention hook → секція 10.
  - **`/vladyslav:discover-apple-check`** — iOS only — підтягує рішення зі swift-calories wing, викликає `apple-appstore-reviewer`, заповнює секцію 11 (rejection-risk checklist).
- **Вхід:** має існувати `docs/product/start-project.md` (створюється автоматично в `/vladyslav:init-project` зі шаблона `templates/StartProject.md`).

### Документування проекту

- **`/vladyslav:write-project-docs`** — README, onboarding guide, deployment docs з коду + PRD.
- **`/vladyslav:analyze-project`** — оновлює архітектурні доки (`docs/architecture/*`).
- **`/vladyslav:write-user-stories`** — генерує `docs/product/user-stories.md` з фактично реалізованих фіч.

### Тестування

- **`/vladyslav:write-test-docs`** — генерує `docs/testing/test-plan.md` (unit/integration/edge cases) і `docs/testing/manual-qa.md` (QA чекліст).
- **`/superpowers:test-driven-development`** — реально пише тести (test-first). Викликається автоматично всередині `add-feature` і `fix-bug`.
- **`/vladyslav:pre-release-check`** — фінальна верифікація перед релізом (тести, docs, rollback, translations). **iOS only:** запускає submission-phase Apple App Store review — hard gate, BLOCKER/HIGH робить весь чек FAIL. Cross-reference з `docs/product/apple-review.md` (pre-dev audit) + свіжі rejection patterns зі `swift-calories` wing. Output → `docs/release/apple-review-submission.md`.

### Перевірка секуріті

- **`/owasp-security`** — OWASP-style аудит на injection, XSS, secrets, auth, CSRF.
- **`/pr-review-toolkit:silent-failure-hunter`** — шукає мовчазні catch-блоки і fallback-и що приховують помилки.
- **`/pr-review-toolkit:code-reviewer`** — загальне code review.
- **Автоматично:** секція "Mandatory Code Review" в `~/.claude/CLAUDE.md` запускає security checklist в кінці кожної задачі.

### Фікс багу

- **`/vladyslav:fix-bug`** — повний цикл: `worktree → systematic-debugging → regression test → minimal fix → code review → merge → docs update`.
- Автоматично використовує `superpowers:systematic-debugging` (не стрибає до висновків).
- Автоматично діє Blast Radius Rule — якщо потрібен більший рефакторинг, спитає дозволу.

### Юзер сторі

- **`/vladyslav:write-user-stories`** — генерує `docs/product/user-stories.md` у форматі `As [role], I can [action], so that [benefit]` з acceptance criteria і статусами (Done / Partial / Not started).
- Джерело: реальний код + PRD + існуючі сторі. Корисно коли QA потрібен registry реалізованих фіч.

---

## Робочі сценарії

### Сценарій A: Новий проект з нуля

```
cd ~/NewProject
/vladyslav:init-project                    # структура + CLAUDE.md + docs/
                                           # + пише docs/product/start-project.md зі шаблона
/vladyslav:discover                        # сам заповнює секції 6-11 (competitors, monetization,
                                           # valuation, marketing, apple-check якщо iOS)
                                           # verdict GREEN → продовжуємо, RED → реопен ідеї
/vladyslav:add-feature                     # повний цикл першої фічі (auto mode рекомендовано)
# ... наступні фічі через /vladyslav:add-feature ...
/vladyslav:write-test-docs                 # test plan + QA checklist
/vladyslav:write-project-docs              # README + deployment
/vladyslav:pre-release-check               # фінал
```

MemPalace wing створиться автоматично — після кожної задачі глобальне правило "MemPalace strict use" записує рішення в wing проекту.

**Старий (низькорівневий) flow** — якщо хочеш руками кермувати кожним кроком без `add-feature` обгортки:
```
/superpowers:brainstorming → /superpowers:writing-plans →
/superpowers:dispatching-parallel-agents → /superpowers:requesting-code-review →
/superpowers:finishing-a-development-branch
```

MemPalace wing створиться автоматично — після кожної задачі глобальне правило "MemPalace strict use" записує рішення в wing проекту.

### Сценарій B: Існуючий проект — підтягнути найкращі архітектурні рішення

```
cd ~/ExistingRepo
/vladyslav:attach-project            # Claude-структура без перезапису файлів
/vladyslav:analyze-project           # сканує код → docs/architecture/*
/vladyslav:seed-mempalace            # ключові рішення в MemPalace wing
/vladyslav:write-user-stories        # stories з реалізованих фіч
/vladyslav:write-project-docs        # README + deployment docs
```

**Ефект:** кожна наступна сесія починається з `mempalace_search wing=<project>` замість сканування коду. Нові фічі (`/vladyslav:add-feature`) автоматично використовують контекст і глобальні правила.

**Якщо проект ще без product discovery** — після `seed-mempalace` запусти `/vladyslav:discover` з існуючим `start-project.md` (або створи його руками) щоб заповнити competitors/monetization/valuation/marketing.

### Сценарій C: Критичний баг

```
cd ~/Project
/vladyslav:fix-bug                   # worktree + діагностика + regression test + fix
```

Blast Radius Rule застосовується автоматично — якщо фікс вимагає більшого рефакторингу, спитаю дозволу перед розширенням scope.

### Сценарій D: Підготовка до релізу

```
cd ~/Project
/vladyslav:write-test-docs           # test plan + QA checklist
/vladyslav:write-project-docs        # оновити README + deployment
/vladyslav:pre-release-check         # фінальна верифікація
```

### Сценарій E: Рефакторинг (без зміни поведінки)

Рефакторинг — особливий випадок: **тести мають бути НАПИСАНІ ДО початку**, щоб підтвердити що поведінка не змінилась. Blast Radius Rule тут критичний — легко почати з "одного класу" і закінчити переписаним модулем.

```
cd ~/Project
/superpowers:using-git-worktrees     # ізольована гілка refactor/<scope>
mempalace_search wing=<project>      # перевірити чи є попередні рішення по цьому коду
/superpowers:brainstorming           # ЧИ потрібен рефакторинг? Що конкретно болить?
/vladyslav:write-test-docs           # якщо тести відсутні — спочатку написати characterization tests
/superpowers:test-driven-development # покриття того що буде рефакториться
/superpowers:writing-plans           # atomic кроки, кожен залишає код working
/superpowers:dispatching-parallel-agents  # якщо кроки незалежні
/pr-review-toolkit:code-simplifier   # для cleanup після рефакторингу
/superpowers:requesting-code-review  # обов'язково, рефакторинг = високий ризик регресій
/superpowers:finishing-a-development-branch
```

**Ключові правила для рефакторингу:**
- **Ніколи не міксуй рефакторинг з новою поведінкою** — окремі коміти / окремі PR.
- **Тести мають проходити після кожного коміту** — rollback point на кожному кроці.
- **Blast Radius** — якщо "один клас" перетворюється в "переписування модуля", STOP і спитай чи це все ще виправдано.
- **Записати рішення в MemPalace ПІСЛЯ** — майбутні сесії мають знати чому було зроблено саме так.

### Сценарій F: Міграція бази даних

Міграція бази — найвищий ризик в будь-якому workflow: незворотні зміни, downtime, цілісність даних. Contract-First тут обов'язковий — схема це контракт.

```
cd ~/Project
/superpowers:using-git-worktrees     # ізоляція гілки migration/<description>
mempalace_search wing=<project>      # попередні міграції, gotchas, rollback patterns
/superpowers:brainstorming           # схема + стратегія (online/offline, backfill, shadow writes)
# Contract-First: write the schema change as explicit contract
/superpowers:writing-plans           # має включати rollback plan і data validation step
/superpowers:test-driven-development # міграційні тести: up, down, data integrity, concurrent writes
/vladyslav:add-feature               # якщо міграція пов'язана з новою фічею
/owasp-security                      # перевірка на injection в нових queries
/pr-review-toolkit:code-reviewer     # code review з фокусом на data safety
/vladyslav:pre-release-check         # ОБОВ'ЯЗКОВО перед релізом міграцій
/superpowers:finishing-a-development-branch
```

**Ключові правила для міграцій:**
- **Zero-downtime за замовчуванням** — експансивні зміни (додати колонку nullable, backfill, зробити not-null) замість руйнівних.
- **Завжди writable rollback** — `down` міграція має бути перевірена на реальних даних, не тільки на schema.
- **Shadow writes / dual-read** для критичних змін — міграція даних через період "обидві колонки живі".
- **Тести на concurrent writes** — міграція під навантаженням ≠ міграція на dev.
- **Backup перед запуском** — очевидно, але записати в плані явно.
- **Записати повний migration record в MemPalace** як `problem` + `decision`: що мігрували, чому такий підхід, які виникли gotchas, скільки займе rollback.

---

## Глобальні правила (з `~/.claude/CLAUDE.md`, завжди діють)

1. **Blast Radius Rule** — найменша оправдана зміна. Більший рефакторинг = STOP і питаю дозволу.
2. **MemPalace strict use** — шукаю в MemPalace ПЕРЕД скануванням коду, записую в MemPalace ПІСЛЯ виконаного.
   - **Path validation (завжди):** після `mempalace_search` перевіряю кожен абсолютний шлях у результатах. Якщо шлях не існує на диску → drawer `[STALE]`, не використовую.
   - **Wing naming:** канонічна назва wing = `basename(pwd)` → lowercase → hyphens → platform prefix. Ніколи не пишу у wing з великими літерами.
3. **Contract-First** — контракт (типи/сигнатури/приклади) перед кодом, тести в паралель з кодом.
4. **Mandatory Code Review** — чекліст перед "done": correctness → security → code smell → minimal change compliance.
5. **LSP over Grep** — для Swift/Python/TS/Kotlin/Lua використовую LSP для пошуку символів, не Grep.
6. **MCP Tool Discipline** — ніколи не читаю `~/.claude/projects/*/tool-results/*.txt` через Bash/Grep. Це внутрішній кеш Claude Code. Для повторного отримання даних — викликаю MCP tool напряму (заблоковано hook-ом автоматично).

---

## Що працює автоматично (без виклику)

Це відповідь на питання "чому все вимагає апрува?". Ось що вже працює **фонoм**:

| Механізм | Тригер | Що робить |
|---|---|---|
| **Pre-commit hook** (`~/.claude/hooks/pre-commit-review.sh`) | Будь-який `git commit` з Bash tool | Друкує Mandatory Code Review чекліст як нагадування (non-blocking). Вимикається через `NO_COMMIT_REVIEW=1`. |
| **Tool-results block hook** (`~/.claude/hooks/block-tool-results-grep.sh`) | Будь-який Bash що чіпає `~/.claude/projects/*/tool-results/` | **Блокує** з поясненням. Примусовий — обходу немає. |
| **MemPalace session-end indexing** | Кінець сесії | Індексує сесію в MemPalace (wing detection + room classification). |
| **Mandatory Code Review чекліст** | Кінець будь-якої задачі | Я сам проходжу корректність → секюріті → код-смел → мінімальність. Прописано в `~/.claude/CLAUDE.md`. |
| **Blast Radius Rule** | Перед будь-яким edit | Я сам декларую scope і не виходжу за нього без дозволу. |
| **Auto-gate в `add-feature` (auto mode)** | Перед кожним комітом | Тести → code review agent → owasp-security. Блокує коміт при помилках. Апрув не потрібен. |
| **Contract hash baseline в `add-feature` (auto mode)** | Під час виконання плану | Перевіряю що контракт не змінився з моменту апруву. |
| **File-scope guard rails в `add-feature` (auto mode)** | Після кожного batch'а | Перевіряю що агенти не зачепили файли поза планом. |
| **Parallel agents в `add-feature`** | Коли план розбитий на незалежні задачі | Два subagent'и в worktree паралельно пишуть тести і код. |

**Що НЕ автоматично і завжди потребує виклику** (`disable-model-invocation: true` у всіх `vladyslav:*` скілах):

- `write-project-docs`, `write-test-docs`, `write-user-stories` — документація
- `owasp-security` (standalone повний аудит — автоматичний тільки в auto-gate)
- `pre-release-check` — фінальна верифікація
- `discover*` сімейство — product research
- `analyze-project`, `seed-mempalace` — одноразові операції
- `fix-bug`, `add-feature` — навмисно explicit, бо запускають повний цикл

Причина: всі vladyslav-скіли мають `disable-model-invocation: true` щоб я не запускав їх випадково. Запуск — завжди твоя команда. Всередині скіла моя автономія вища (auto mode в `add-feature`).

---

## Коли апрув обов'язковий (auto mode в `add-feature`)

1. Опис фічі (Step 2)
2. Brainstorm output (Step 4)
3. Contract (Step 4.5)
4. Plan (Step 5)
5. Merge в `main` (Step 8 кінець)
6. Будь-який guard rail trigger
7. Фінальний `/vladyslav:pre-release-check`

Між 4 і 5 — все виконується без зупинок: parallel agents → auto-gate (tests/review/security) → commit → наступний batch → ... → merge в `dev`.

---

## Довідка по зовнішніх бібліотеках (LSP / Context7 / WebFetch)

Три різних джерела знань — кожне вирішує свою задачу. Використовую **перший ліворуч що відповідає питанню**:

| Задача | Інструмент | Чому саме цей |
|---|---|---|
| Де визначена функція/клас/символ у **моєму** коді? | **LSP** (`getDefinition`) | Миттєво, точно, без текстового шуму |
| Хто викликає цю функцію? | **LSP** (`getReferences`) | Розуміє scope, не матчить рядки і коментарі |
| Який тип/сигнатура? | **LSP** (`getHover`) | Повна type info, дешево по токенах |
| Є компіл-помилки? | **LSP** (`getDiagnostics`) | Без запуску білда |
| Як правильно викликати функцію з **зовнішньої** бібліотеки (React, SwiftUI, FastAPI, Ktor)? | **Context7** | Актуальна документація навіть якщо моє training data застаріло |
| Який синтаксис в конкретній версії (Prisma 6, AI SDK v6, Vercel config)? | **Context7** | Version-специфічний контент |
| Apple DocC / Human Interface Guidelines / WWDC tutorials | **WebFetch** на `developer.apple.com/...` | Context7 тонкий по цьому контенту |
| Android developer guides (Material 3, Jetpack best practices) | **WebFetch** на `developer.android.com/...` | Те саме — бібліотечні API в Context7 є, довгі гайди частково |
| Рішення які я вже приймав в цьому проекті | **MemPalace** (`mempalace_search wing=<project>`) | Внутрішня пам'ять, не зовнішні доки |
| Загальні блоги, StackOverflow, обговорення | **WebSearch** | Остання лінія — коли решта не допомагає |

**LSP встановлено для:** Swift, Python, TypeScript/JavaScript, Kotlin, Lua. Для інших мов (Dart, Shell) — Grep.

**Context7 вже увімкнений** (`context7@claude-plugins-official`) — працює через MCP tools `resolve-library-id` + `query-docs`. Не плутай з vladyslav-скілами.

**Правило бренда:** якщо я збираюсь Grep по всій репі щоб "зрозуміти як працює X" — STOP. Якщо X — мій код → LSP. Якщо X — зовнішня бібліотека → Context7. Якщо X — рішення минулого → MemPalace.

---

## Допоміжні скіли (викликаються автоматично з `vladyslav:*`)

| Superpowers | Для чого |
|---|---|
| `brainstorming` | Структуровані ідеї перед плануванням |
| `writing-plans` | Розбивка на bite-sized задачі |
| `dispatching-parallel-agents` | Паралельне виконання (тести + код) |
| `subagent-driven-development` | Послідовне виконання в одній сесії |
| `test-driven-development` | Test-first розробка |
| `systematic-debugging` | Debug без гіпотез навмання |
| `requesting-code-review` | Запит ревю |
| `receiving-code-review` | Обробка фідбеку з верифікацією |
| `finishing-a-development-branch` | Merge / PR / cleanup |
| `using-git-worktrees` | Ізоляція роботи |
| `verification-before-completion` | Не казати "готово" без доказів |

---

## Повний список vladyslav скілів

| Скіл | Модель | Коли |
|---|---|---|
| `init-project` | Engineer | Новий проект з нуля (+ пише `start-project.md` зі шаблона) |
| `attach-project` | Engineer | Приєднання Claude до існуючого коду |
| `analyze-project` | Architect | Скан коду, заповнення architecture docs |
| `seed-mempalace` | Architect | Одноразовий bootstrap MemPalace wing |
| `design-sync` | Architect | Сканує UI-код, канонізує токени, пише `docs/design/system.md` + MemPalace. iOS: автоматичний HIG аудит через `apple-hig-expert` |
| `design-page` | Architect | Паралельні субагенти для кожного екрану в Pencil. Full-auto. Читає `docs/design/system.md` як контракт, пише `docs/design/pages/<screen>.md` |
| `discover` | Architect | Оркестратор product discovery (запускає саб-скіли) |
| `discover-competitors` | Architect | Конкурентний аналіз → start-project.md §6 |
| `discover-monetization` | Architect | Моделі монетизації → start-project.md §8 |
| `discover-valuation` | Architect | PMF + CEO оцінка → start-project.md §9, verdict |
| `discover-marketing` | Architect | Канали, first-100-users, retention → §10 |
| `discover-apple-check` | Architect | iOS App Store rejection-risk check → §11 |
| `add-feature` | Architect | Повний цикл нової фічі (manual / auto mode) |
| `fix-bug` | Architect | Повний цикл фіксу багу |
| `write-user-stories` | Engineer | Генерація user stories |
| `write-test-docs` | Engineer | Test plan + QA checklist |
| `write-project-docs` | Engineer | README + deployment + onboarding |
| `pre-release-check` | Engineer | Фінальна верифікація перед релізом |
| `swiftui-pro` | Engineer | Ревю SwiftUI/Swift коду: deprecated API, accessibility, HIG, Swift concurrency (iOS 26 / Swift 6.2). Автоматично викликається в `add-feature` Step 6.5 для iOS проектів. |
| `help` | — | Список скілів і хелп |

**Architect (Opus)** — для дизайну, планування, архітектурних рішень.
**Engineer (Sonnet)** — для імплементації, генерації бойлерплейту, репетативних задач.

---

## Інтегровані зовнішні скіли

### `vladyslav:swiftui-pro` — Paul Hudson's SwiftUI Agent Skill

**Джерело:** [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) (MIT)
**Розміщення:** `~/.vladyslav-skills/skills/swiftui-pro/`

Перевіряє SwiftUI/Swift код за 9 категоріями:

| Reference | Що перевіряє |
|---|---|
| `api.md` | Deprecated API → сучасний еквівалент (iOS 26 / Swift 6.2) |
| `views.md` | Структура view, composition, анімації |
| `data.md` | Data flow, `@Observable`, property wrappers |
| `navigation.md` | NavigationStack, alerts, sheets |
| `design.md` | Flexible layout, ContentUnavailableView, системні компоненти |
| `accessibility.md` | Dynamic Type, VoiceOver, Reduce Motion |
| `performance.md` | AnyView, lazy stacks, `task()` vs `onAppear()` |
| `swift.md` | Modern Swift, concurrency, актори |
| `hygiene.md` | Keychain, LocalizedStrings, SwiftLint |
| `ios-hig.md` | Apple HIG compact checklist (layout, nav, a11y, color, components) |

**Автоматичний виклик:** `add-feature` Step 6.5 — якщо diff містить `.swift` файли.
**Ручний виклик:** `/vladyslav:swiftui-pro` для окремого ревю.

---

### iOS HIG Rules (ehmo/platform-design-skills)

**Джерело:** [ehmo/platform-design-skills](https://github.com/ehmo/platform-design-skills) (MIT)
**Розміщення:** вбудовано в `skills/swiftui-pro/references/ios-hig.md` + `design-page` subagent prompt

HIG правила по 10 категоріях (CRITICAL/HIGH/MEDIUM) з Correct/Incorrect прикладами Swift кодe. Перевіряються на двох рівнях:
- **Design time** (`design-page`): subagent робить HIG audit перед малюванням в Pencil, блокує CRITICAL порушення
- **Code review time** (`swiftui-pro`): `ios-hig.md` входить у Step 6 ревю SwiftUI коду

---

### Android Agent Skills (defer до появи Android проекту)

**Джерело:** [krutikJain/android-agent-skills](https://github.com/krutikJain/android-agent-skills) (MIT)
**Статус:** задокументовано, не інтегровано — немає Android проектів

34 скіли для Android/Compose розробки:

| Категорія | Скіли |
|---|---|
| Compose | compose-foundations, compose-state-effects, compose-performance, compose-accessibility, compose-xml-interoperability |
| Архітектура | architecture-clean, state-management, modularization, navigation-deeplinks |
| DI & Storage | di-hilt, room-database, local-persistence-datastore |
| Мережа | networking-retrofit-okhttp, serialization-offline-sync |
| Тести | testing-unit, testing-ui |
| Дизайн | material3-design-system, mobile-frontend-design |
| CI/CD | ci-cd-release-playstore, gradle-build-logic, gradle-build-performance |
| Інше | kotlin-core, coroutines-flow, security-best-practices, performance-observability, workmanager-notifications |

**Коли інтегрувати:** при старті першого Android проекту — клонувати репо, створити `skills/android-pro/` аналогічно `swiftui-pro`, зареєструвати команди.

---

## Приклади повних флоу

### Приклад 1: Новий проект — "chess-duel" (iOS шахи з ШІ-тренером)

```
$ mkdir ~/chess-duel && cd ~/chess-duel && claude
```

**Крок 1 — структура (Engineer Sonnet).**
```
> /vladyslav:init-project
```
Я питаю стек — ти: "Swift + SwiftUI, iOS 17+". Я створюю `docs/`, `.claude/agents/`, `CLAUDE.md`, Swift skeleton, і пишу порожній `docs/product/start-project.md` зі шаблона `templates/StartProject.md`. Report: "Заповни секції 1–4 і запусти `/vladyslav:discover`".

**Крок 2 — заповнюєш руками секції 1–4** в `docs/product/start-project.md`:
- §1 Ідея: "iOS шахи з ШІ що пояснює кожен твій хід українською"
- §2 Проблема: "Новачки не розуміють чому хід поганий"
- §3 Аудиторія: "1200–1800 ELO, українськомовні"
- §4 MVP scope: "Дошка + ходи + один простий бот + post-move пояснення"

**Крок 3 — discovery (Architect Opus).** Перемикаєш: `/model opus`
```
> /vladyslav:discover
```
Я питаю: "Full чи subset?" → ти: "full". Я послідовно запускаю під-скіли (manual mode — зупиняюсь після кожного, ти запускаєш наступний):
- `discover-competitors` → §6: Chess.com, Lichess, Chess Kid, Play Magnus → `docs/product/competitors.md`
- `discover-monetization` → §8: freemium + premium пояснення ШІ
- `discover-valuation` → §9: **YELLOW** (ніша насичена, диференціатор = укр ШІ-тренер)
- `discover-marketing` → §10: Reddit r/chess_ua, YouTube chess-укр канали, TikTok short games
- `discover-apple-check` → §11: **GREEN** (немає UGC, IAP стандартний, privacy manifest простий)

Пишу `docs/product/discovery-summary.md`. Ти читаєш YELLOW verdict → вирішуєш що диференціатор OK → продовжуєш.

**Крок 4 — перша фіча (Architect Opus).**
```
> /vladyslav:add-feature
```
Я: "Manual чи Auto mode?" → ти: "Auto". Я: "Яка фіча?" → ти: "Ядро гри: дошка, фігури, move generation, check/checkmate detection, SwiftUI board view".

Я читаю `CLAUDE.md` + `docs/architecture/` + `docs/product/start-project.md`. Запускаю `mempalace_search wing=chess-duel` (перший раз — порожньо). Викликаю `superpowers:brainstorming`.

- **Approval #1** — ти затвердив brainstorm output (board representation = matrix Int8, move gen = pseudo-legal потім legality filter, SwiftUI + Observation)
- **Approval #2** — ти затвердив контракт: `Piece`, `Board`, `Move`, `makeMove()`, `isLegal()`, `isCheckmate()`
- **Approval #3** — ти затвердив план: 6 задач, з файл-листом кожна

**Далі БЕЗ зупинок** (це і є auto mode):
1. Batch 1 (Piece + Board) → launch 2 subagents (tests + code) в worktree → обидва готові → guard rails pass → auto-gate: `swift test` → code review agent → `owasp-security` → commit
2. Batch 2 (move generation) → ... → commit
3. ... (5–15 хвилин без тебе)
4. Merge `feature/core-chess-game` → `dev`

- **Approval #4** — "Merge в main?" — ти: "yes"

Я оновлюю `docs/product/user-stories.md`, `docs/plans/tasks.md`, пишу MemPalace decision record: `[WHAT] chess core, [DECISIONS] matrix board, pseudo-legal gen, [FILES] Sources/Chess/*.swift`. Architect report.

**Крок 5 — наступна сесія, додаємо "Move history panel":**
```
> /vladyslav:add-feature
```
Я на старті автоматично роблю `mempalace_search wing=chess-duel` → знаходжу decision record про board representation → знаю що `Move` вже існує → НЕ винаходжу нові типи. Далі звичайний add-feature flow.

---

### Приклад 2: Приєднання до існуючого проекту — "python-tax"

Проект вже існує, працює, але без Claude-структури.

```
$ cd ~/python-tax && claude
```

**Крок 1 — attach без руйнування коду (Engineer Sonnet).**
```
> /vladyslav:attach-project
```
Я детекчу стек (Python/Django 5 + Postgres). Пишу `CLAUDE.md`, створюю `docs/` з порожніми файлами, `.claude/agents/`. НЕ торкаюся коду. Report: "Далі — `/vladyslav:analyze-project`".

**Крок 2 — аналіз коду (Architect Opus).** `/model opus`
```
> /vladyslav:analyze-project
```
Я сканую репо, заповнюю `docs/architecture/system.md` (модулі, потоки), `docs/architecture/api.md` (endpoints), `docs/architecture/db-schema.sql` (скелет схеми з моделей). Оновлюю `CLAUDE.md` з конвенціями які я побачив (naming, layering, test patterns).

**Крок 3 — seed MemPalace (ОДИН РАЗ).**
```
> /vladyslav:seed-mempalace
```
Я читаю всі `docs/architecture/*`, витягую ключові рішення (~20–40 штук), записую в `wing=python-tax` як `decision` records. **Після цього майбутні сесії не скануть репу наново** — вони будуть робити `mempalace_search wing=python-tax` і отримувати ці рішення миттєво.

**Крок 4 — user stories з реалізованого (Engineer Sonnet).** `/model sonnet`
```
> /vladyslav:write-user-stories
```
Я читаю код + роутинг + тести, пишу `docs/product/user-stories.md` зі статусами (Done / Partial / Not started).

**Крок 5 — якщо треба discovery заднім числом:**
```
> /vladyslav:discover
```
Я помічу що в `start-project.md` секції 1–4 порожні (бо init не запускали), питаю: "Заповниш вручну чи скіпаємо discovery?" Ти вирішуєш.

**Крок 6 — нова фіча (як у Прикладі 1).**
```
> /vladyslav:add-feature
```
Тепер весь контекст вже є: CLAUDE.md auto-loaded, MemPalace має архітектурні decisions, юзер сторі відомі. Фіча йде швидше.

---

### Приклад 3: Як виглядає розмова — хто коли викликається

Це розбивка "за лаштунками", щоб ти розумів що автоматично, а що ні.

**На старті сесії (`claude` в директорії проекту):**
- ⚙ SessionStart hook → завантажує Remember (`.remember/`), Vercel-контекст, memory index з `MEMORY.md`
- ⚙ Я бачу CLAUDE.md (глобальний + проектний) як context
- ⚙ MCP сервери підключаються (MemPalace, Context7, Pencil, etc.)
- ❌ Я НЕ роблю mempalace_search автоматично — тільки коли задача потребує

**Ти: "подивись що тут за проект"**
- ✅ Я можу зробити `mempalace_search wing=<project>` (коштує дешево, вартує спробувати)
- ✅ Я читаю `CLAUDE.md`, `docs/architecture/system.md`, `docs/product/prd.md`
- ❌ Я НЕ Grep-аю всю репу — це порушує LSP-over-Grep rule

**Ти: "додай екран налаштувань"** (UI задача в swift-sudoku)
- ✅ Я ПОВИНЕН `mempalace_search wing=swift-sudoku "settings screen"` — раптом вже обговорювали
- ✅ Я ПОВИНЕН прочитати `docs/design/system.md` як контракт (глобальне правило "Design System Discipline") — без нього не починаю UI задачі
- ✅ Якщо якогось токена бракує — зупиняюсь і питаю, не винаходжу
- ✅ Я питаю: "Manual чи Auto mode?" (якщо це через `add-feature`)
- ✅ Всередині add-feature — brainstorm → contract → plan → parallel agents → auto-gate → commit

**Ти: "що ми вирішили про кольори в календарі?"**
- ✅ Я одразу `mempalace_search wing=<project> "кольори календар"`
- ✅ Якщо знаходжу — цитую і перевіряю що воно все ще актуальне в коді
- ❌ Я НЕ перечитую увесь code щоб "згадати" — це втрата часу

**Ти: "запам'ятай що ми вибрали PostgreSQL замість MySQL"**
- ✅ Я явно викликаю `mempalace_check_duplicate` → `mempalace_add_drawer` з room=`decision`
- ✅ Повертаю ID запису

**Ти пишеш код, я роблю git commit:**
- ⚙ Pre-commit hook (`~/.claude/hooks/pre-commit-review.sh`) автоматично друкує Mandatory Code Review чекліст — **без мого виклику, без твого дозволу**
- ⚙ Коміт йде далі (hook non-blocking)

**Кінець сесії:**
- ⚙ SessionEnd hook (`~/.claude/scripts/mempalace-mine-session.sh`) автоматично індексує цю розмову в MemPalace (wing detection + room classification) — **асинхронно, ти можеш закривати термінал**

**Легенда:**
- ⚙ = автоматично, системою, без тебе і без мене
- ✅ = я роблю згідно правил з CLAUDE.md
- ❌ = я НЕ роблю (анти-паттерн)

---

*Останнє оновлення: 2026-04-10 (design-sync + Design System Discipline)*
