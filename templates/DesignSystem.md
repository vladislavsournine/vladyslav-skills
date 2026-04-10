# Design System — <PROJECT_NAME>

> **Цей файл — КОНТРАКТ.** Кожна візуальна зміна в проекті ПОВИННА спиратись на токени з цього файлу. Нові токени додаються тільки через явну згоду користувача і записуються сюди.
>
> AI-assistants (Claude): перед будь-якою UI-задачею читай цей файл ПЕРШИМ. Якщо тут є палітра — використовуй її, не винаходь нові кольори. Якщо тут є іконки — шукай потрібну в списку, не придумуй нові імена SF Symbols. Якщо тобі потрібен новий токен — СТОП і спитай.
>
> Якщо цей файл порожній або вперше створюється — запусти `/vladyslav:design-sync` щоб підтягнути існуючі токени з коду.

---

## Platform & scope

- **Платформа:** <iOS / web / Flutter / Android / cross>
- **Design system source of truth:** `docs/design/system.md` (цей файл)
- **Код source of truth:** <Assets.xcassets / tailwind.config.ts / ThemeData / tokens.css>
- **Останній `design-sync`:** <date>

---

## 1. Palette (колірна палітра)

**Правило:** використовуй ТІЛЬКИ токени з цієї таблиці. Hex-коди в коді (`Color(hex: "#...")`, `rgb(...)`, `Color.blue`) — заборонені.

### Semantic tokens (не використовуй raw кольори — тільки ці)

| Token | Light | Dark | Призначення |
|---|---|---|---|
| `background/primary` | `#FFFFFF` | `#000000` | Основний фон екранів |
| `background/secondary` | `#F2F2F7` | `#1C1C1E` | Групи, картки |
| `background/tertiary` | `#FFFFFF` | `#2C2C2E` | Cells всередині груп |
| `label/primary` | `#000000` | `#FFFFFF` | Основний текст |
| `label/secondary` | `#3C3C43` (60%) | `#EBEBF5` (60%) | Підпис, hint |
| `label/tertiary` | `#3C3C43` (30%) | `#EBEBF5` (30%) | Placeholder |
| `accent/primary` | `<hex>` | `<hex>` | Головний бренд-колір |
| `accent/success` | `<hex>` | `<hex>` | Успіх, confirmation |
| `accent/warning` | `<hex>` | `<hex>` | Попередження |
| `accent/danger` | `<hex>` | `<hex>` | Помилки, destructive |
| `separator` | `#3C3C43` (29%) | `#545458` (65%) | Роздільники |

### Код

- **Swift/SwiftUI:** `Color("background/primary")` — через named color в `Assets.xcassets`
- **Web/Tailwind:** `bg-background-primary` — через `tailwind.config.ts` extend
- **Flutter:** `Theme.of(context).colorScheme.background` — через `ThemeData`

> **Як додати новий колір:** запусти `/vladyslav:design-sync --add-color name=<name> light=<hex> dark=<hex>`. Скіл перевірить що такого ще немає, додасть в Assets і в цю таблицю.

---

## 2. Typography (шрифти)

**Правило:** тільки ці типи тексту. Не вигадуй `.font(.system(size: 17, weight: .semibold))` напряму в коді — використовуй токен.

| Token | Size | Weight | Line height | Приклад |
|---|---|---|---|---|
| `text/largeTitle` | 34 | Bold | 41 | "Settings", splash headers |
| `text/title1` | 28 | Bold | 34 | Screen titles |
| `text/title2` | 22 | Bold | 28 | Section headers |
| `text/title3` | 20 | Semibold | 25 | Subsection |
| `text/headline` | 17 | Semibold | 22 | List item title |
| `text/body` | 17 | Regular | 22 | Основний текст |
| `text/callout` | 16 | Regular | 21 | Secondary body |
| `text/subheadline` | 15 | Regular | 20 | Hints, hints |
| `text/footnote` | 13 | Regular | 18 | Disclaimers |
| `text/caption1` | 12 | Regular | 16 | Caption під фото |
| `text/caption2` | 11 | Regular | 13 | Найдрібніше |

**Font family:** `<System / SF Pro / custom font name>`
**Monospaced (коли треба):** `<SF Mono / JetBrains Mono / ...>`

### Dynamic Type (iOS)

**ОБОВ'ЯЗКОВО** всі текстові токени мають бути Dynamic Type friendly. Використовуй `Font.system(.body)` а НЕ `Font.system(size: 17)`. Accessibility sizes (XXL+) мають працювати без обрізання.

---

## 3. Iconography (іконки)

**Правило:** 
- **Source:** <SF Symbols / Material Icons / Heroicons / custom set>
- **НЕ винаходь нові імена** — якщо потрібна іконка якої немає в списку нижче, додавай через `/vladyslav:design-sync --add-icon`

### Канонічний набір

| Token / role | Symbol name | Використовується в |
|---|---|---|
| `icon/close` | `xmark` | Modals, dismissible sheets |
| `icon/back` | `chevron.left` | Navigation back |
| `icon/settings` | `gearshape` | Settings entry points |
| `icon/search` | `magnifyingglass` | Search fields |
| `icon/add` | `plus` | Create new item |
| `icon/delete` | `trash` | Destructive actions |
| `icon/edit` | `pencil` | Edit mode |
| `icon/share` | `square.and.arrow.up` | Share sheet trigger |
| `icon/info` | `info.circle` | Info tooltips |
| `icon/warning` | `exclamationmark.triangle` | Warnings |
| `icon/success` | `checkmark.circle.fill` | Success states |

> Додай свої проект-специфічні ролі (`icon/board`, `icon/piece`, ...). Один role = одна іконка. Не дозволяй двом кнопкам "налаштування" використовувати різні SF Symbols.

### Icon sizes

| Size token | Pt | Коли |
|---|---|---|
| `icon/size/xs` | 12 | Inline в тексті |
| `icon/size/sm` | 16 | List cells |
| `icon/size/md` | 20 | Tab bar, toolbar |
| `icon/size/lg` | 24 | Primary actions |
| `icon/size/xl` | 32 | Feature highlights |

---

## 4. Spacing & layout

**Правило:** тільки множники 4pt. Не пиши `.padding(13)` — використовуй токен.

| Token | Pt | Використовується |
|---|---|---|
| `space/xs` | 4 | Tight inline gaps |
| `space/sm` | 8 | Between related items |
| `space/md` | 16 | Default padding |
| `space/lg` | 24 | Section separation |
| `space/xl` | 32 | Major section breaks |
| `space/xxl` | 48 | Hero spacing |

### Corner radius

| Token | Pt | Де |
|---|---|---|
| `radius/sm` | 4 | Small chips, tags |
| `radius/md` | 8 | Buttons, input fields |
| `radius/lg` | 12 | Cards |
| `radius/xl` | 16 | Sheets, modals |
| `radius/full` | 999 | Pills, circle avatars |

### Screen margins

- **iPhone portrait:** `space/md` (16) left/right
- **iPhone landscape / iPad:** `space/lg` (24)
- **Max content width (iPad/web):** 680pt для reading, 1024pt для dashboards

---

## 5. Component patterns

Шаблони компонентів які вже **канонізовані** в цьому проекті. Якщо потрібен компонент якого тут немає — запропонуй додати через `design-sync`, не роби одноразово inline.

### Primary Button

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .default).weight(.semibold))
                .foregroundStyle(Color("label/onAccent"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14) // space/md minus 2 for optical balance
                .background(Color("accent/primary"))
                .clipShape(RoundedRectangle(cornerRadius: 8)) // radius/md
        }
        .buttonStyle(.plain)
    }
}
```

### Secondary Button
<заповнити>

### Card
<заповнити>

### List Row
<заповнити>

### Modal / Sheet
<заповнити>

---

## 6. Motion (анімації)

| Token | Curve | Duration | Для |
|---|---|---|---|
| `motion/fast` | easeOut | 0.15s | Hover, tap feedback |
| `motion/standard` | easeInOut | 0.3s | Navigation, reveal |
| `motion/slow` | easeInOut | 0.5s | Onboarding, hero |
| `motion/spring` | `.spring(response: 0.4, dampingFraction: 0.7)` | — | Drag-and-drop, card flip |

**Reduce Motion:** якщо `UIAccessibility.isReduceMotionEnabled` (iOS) або `prefers-reduced-motion` (web) — ВСІ non-essential анімації стають instant або cross-fade.

---

## 7. Accessibility (обов'язково для iOS)

- **Dynamic Type:** підтримуємо до accessibility sizes (XXL+) — жоден текст не обрізається
- **VoiceOver:** кожен кастом-компонент має `.accessibilityLabel()`, interactive — має `.accessibilityHint()`
- **Contrast:** мінімум WCAG AA (4.5:1 для body, 3:1 для large text). Перевіряй через Xcode Accessibility Inspector або https://webaim.org/resources/contrastchecker/
- **Tap targets:** мінімум 44×44pt (Apple HIG)
- **High Contrast mode:** `UIAccessibility.isDarkerSystemColorsEnabled` → посилена палітра
- **VoiceOver rotor:** headings (`.accessibilityAddTraits(.isHeader)`), landmarks де доречно

### Dark mode rules (обов'язково для iOS — Apple HIG)

- **Всі semantic tokens мають light + dark варіанти** (див. секцію 1)
- **Ніяких hard-coded `.white` / `.black`** — завжди через token
- **Elevation** в dark mode — світліший фон, а не тінь (inverted)
- **Accent кольори** можуть бути однакові в обох, якщо contrast достатній в обох. Якщо ні — два варіанти.
- **Перевірка:** всі екрани мають бути скріншотнуті в обох режимах перед merge в main

---

## 8. Drift log — виявлені порушення

Сюди пише `/vladyslav:design-sync` коли знаходить inconsistency. Приклади:

- `[<date>] Button "Save" в SettingsView використовує Color(hex: "#4A90E2"), а канон — Color("accent/primary"). Fix: замінити → done / pending`
- `[<date>] 3 місця використовують .padding(13), канон — space/sm (8) або space/md (16). Fix: → done / pending`

---

## Підтримка інших платформ

Якщо проект кросплатформовий (iOS + web, Flutter, etc.) — додай окремі секції після 8:

- **Web tokens** (`tailwind.config.ts` extend)
- **Flutter tokens** (`ThemeData` extension)
- **Android tokens** (Material 3 token set)

Mapping "platform → token" має бути 1:1 де можливо.

---

**Останнє оновлення шаблону:** 2026-04-10
