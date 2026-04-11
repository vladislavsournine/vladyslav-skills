# iOS HIG Quick-Reference (Design Review)

Derived from Apple's Human Interface Guidelines. Use when reviewing or designing iPhone screens.
Source: ehmo/platform-design-skills (MIT) + Apple HIG.

---

## CRITICAL: Layout & Safe Areas

- **44×44pt minimum tap target** for all interactive elements (buttons, toggles, links, custom controls).
- **Never** place interactive or essential content under status bar, Dynamic Island, or home indicator. Only use `.ignoresSafeArea()` for background fills and decorative elements.
- **Primary actions at the bottom** (thumb zone). Secondary actions / navigation at top.
- **Support all iPhone widths**: SE (375pt) through Pro Max (430pt). Use flexible layouts, never hardcode widths.
- **8pt grid**: spacing, padding, and sizes must be multiples of 8pt (8, 16, 24, 32, 40, 48). Use 4pt for fine adjustments.

## CRITICAL: Navigation

- **Tab bar at the bottom** for 3–5 top-level sections. Never use a hamburger/drawer menu.
- **Large titles** (`.navigationBarTitleDisplayMode(.large)`) in primary views; transitions to inline on scroll.
- **Never override the left-edge back swipe** gesture.
- Use `NavigationStack` (not deprecated `NavigationView`). Use `navigationDestination(for:)` with `NavigationPath`.
- Preserve state across tab switches — users should resume where they left off.

## HIGH: Typography & Dynamic Type

- **Always support Dynamic Type** — use semantic text styles (`.body`, `.headline`, `.title`, `.caption`). Never hardcode font sizes.
- Minimum body text: `.body` (17pt at default). Never use `.caption2` (11pt) for important content.
- Maximum 2–3 text sizes per screen. Maintain clear visual hierarchy.

## HIGH: Color & Dark Mode

- **Use semantic system colors** (`Color(.label)`, `Color(.systemBackground)`, etc.) that adapt automatically to Dark Mode.
- All custom colors must be in the asset catalog as `.colorset` with both `Any` and `Dark` appearances.
- **WCAG AA minimum contrast**: 4.5:1 for body text, 3:1 for large text and UI components.
- **One accent color** for interactive elements. Don't use color alone to communicate state — pair with icon or text.
- Never hardcode hex values in view code.

## CRITICAL: Accessibility

- **Every interactive element needs a VoiceOver label**. Image-only buttons must have `.accessibilityLabel()`.
- Use `Image(decorative:)` or `.accessibilityHidden(true)` for purely decorative images.
- Support **Bold Text**, **Reduce Motion** (replace motion animations with opacity), **Increase Contrast**.
- If color differentiates states, also show icons/patterns for colorblind users (`.accessibilityDifferentiateWithoutColor`).
- Never use `onTapGesture()` where a `Button` works — it's invisible to VoiceOver.

## HIGH: Gestures & Input

- Standard gestures (tap, swipe, pinch, long press) must match platform conventions — don't repurpose them.
- Custom gestures always need an alternative (button, menu) for users with motor impairments.
- Swipe-to-delete on list items uses `.swipeActions()` — don't build custom swipe handlers.

## HIGH: Components

- Use `NavigationStack`/`TabView`/`List`/`Form`/`Alert` — standard components come with accessibility, Dynamic Type, Dark Mode for free.
- **Alerts** only for critical information requiring immediate action. Use `.confirmationDialog()` for destructive actions. Never use an alert as a notification.
- Tab bar must always be visible — never hide it on drill-down within a tab.
- Use `.searchable()` for search instead of custom search bars.

## MEDIUM: Patterns

- **Loading**: prefer skeleton views (`.redacted(reason: .placeholder)`) over blocking spinners. Show immediate response to actions.
- **Launch screen** must match the first content screen (same background color, no animated splash).
- **Onboarding**: max 3 screens, always skippable. Request permissions with context, after a value-add moment.
- **Empty states**: use `ContentUnavailableView` with icon + title + action button.
- **Error states**: always explain what went wrong and what the user can do.

## HIGH: Privacy & Permissions

- Request permissions only when needed, with clear explanation of why. Use `.requestWhenInUseAuthorization()` before `.requestAlwaysAuthorization()`.
- Support Sign in with Apple alongside other auth options.
- Never store passwords or sensitive data in `@AppStorage` or UserDefaults — use Keychain.
