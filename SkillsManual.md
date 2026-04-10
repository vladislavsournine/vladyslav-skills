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
- **`/vladyslav:pre-release-check`** — фінальна верифікація перед релізом (тести, docs, rollback, translations).

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
3. **Contract-First** — контракт (типи/сигнатури/приклади) перед кодом, тести в паралель з кодом.
4. **Mandatory Code Review** — чекліст перед "done": correctness → security → code smell → minimal change compliance.
5. **LSP over Grep** — для Swift/Python/TS/Kotlin/Lua використовую LSP для пошуку символів, не Grep.

---

## Що працює автоматично (без виклику)

Це відповідь на питання "чому все вимагає апрува?". Ось що вже працює **фонoм**:

| Механізм | Тригер | Що робить |
|---|---|---|
| **Pre-commit hook** (`~/.claude/hooks/pre-commit-review.sh`) | Будь-який `git commit` з Bash tool | Друкує Mandatory Code Review чекліст як нагадування (non-blocking). Вимикається через `NO_COMMIT_REVIEW=1`. |
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
| `help` | — | Список скілів і хелп |

**Architect (Opus)** — для дизайну, планування, архітектурних рішень.
**Engineer (Sonnet)** — для імплементації, генерації бойлерплейту, репетативних задач.

---

*Останнє оновлення: 2026-04-09*
