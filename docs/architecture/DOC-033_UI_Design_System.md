# DOC-033 — UI Design System

**Version:** 1.0
**Status:** Draft — Requires Architecture Approval
**Category:** User Experience / Design Review
**Phase:** Stabilization & UI Polish
**Depends on:** DOC-001 (Vision & Product Philosophy), DOC-018 (Navigation System), DOC-019 (Dashboard Architecture), DOC-020 (Widget Framework), DOC-021 (Design System — Technical Skeleton), DOC-022 (Monorepo Architecture)
**Supersedes (content-wise, not technically):** DOC-021's placeholder token/component lists become concrete under this document. DOC-021 is not deleted — it remains the short architectural pointer; DOC-033 is the filled-in specification it always deferred to.

> **Scope note.** This is a **design review document**. It defines *what the visual language should be* and *why*. It does not implement, modify, or refactor any Flutter code. Every recommendation below is written to be checked against — and where it already matches — the current implementation in `packages/design_system`, so implementers can see at a glance what already conforms and what changing anything downstream would actually cost.

---

## 0. Context: What Already Exists

Before proposing anything new, this section inventories what's already built, since several sections below are recommending *keeping* the existing token values rather than replacing them — Personal OS already has a working, Material-3-based, token-driven design system (`packages/design_system`). The gap this document closes is **specification**, not **implementation**: the code has always cited a "VPS §" (Visual Polish Spec) numbering scheme in its doc comments (e.g. `AppSpacing` cites "VPS §1.1", `AppTypography` cites "VPS §1.2"), but no such document was ever committed. This document **is** that spec, retroactively formalized and, where the existing implementation is already sound, ratified rather than replaced.

Existing, in production today:

| Area | File | Status |
|---|---|---|
| Spacing scale | `packages/design_system/lib/src/tokens/app_spacing.dart` | 4pt scale, 6 steps |
| Corner radius | `.../tokens/app_radius.dart` | 3 tokens |
| Elevation | `.../tokens/app_elevation.dart` | 8 contextual values |
| Motion | `.../tokens/app_motion.dart` | 4 durations + 2 curves + reduced-motion hook |
| Icon sizes | `.../tokens/app_icon_sizes.dart` | 4 tokens |
| Breakpoints | `.../tokens/app_breakpoints.dart` | 3-class M3 window sizing |
| Typography | `.../typography/app_typography.dart` | M3 2021 base, tuned weights |
| Semantic colors | `.../theme/app_semantic_colors.dart` | positive/negative/warning/neutral/success + 9 module accents |
| Theme assembly | `.../theme/app_theme_builder.dart` | Seed-color `ColorScheme.fromSeed`, all component themes |
| Components | `.../lib/src/components/{foundation,display,tiles,forms,input}/` | ~25 shared widgets already built and used by every feature |
| Navigation | `apps/mobile/lib/app/shell/shell_branches.dart` | 4-branch `StatefulShellRoute` (Home, Finance, Tasks, Settings) |

This document's job is to (a) formalize these as the numbered spec code already assumes exists, (b) extend them to cover the modules and states not yet specified (Habits, Goals, Notes, Calendar, Assets, Documents visual identity; empty/loading/error state patterns; navigation for 8 feature modules), and (c) flag the one structural decision that does require a real trade-off: **navigation architecture**, addressed in Section 10.

---

## 1. Design Principles

### 1.1 Visual Philosophy

Personal OS is a **calm productivity surface**, not a dashboard of dashboards. The reference products named in this brief (Google Calendar, TickTick, Notion Mobile, Google Tasks, Wallet by BudgetBakers, Apple Health) share a common visual grammar worth naming explicitly, because "modern and premium" is otherwise unfalsifiable:

1. **Generous negative space over dense information.** Every reference app resists the urge to show everything at once. A screen earns the right to show a number only if that number is the single most important thing on it.
2. **One accent color per context, everything else neutral.** Apple Health uses red only for the activity ring, never for chrome. TickTick uses its accent only for the active tab and primary actions. Personal OS already has this instinct encoded as `moduleAccents` — Section 2.4 formalizes when an accent may vs. may not appear.
3. **Typography carries hierarchy; color is a second signal, never the only one.** A completed task is struck through *and* uses `success` color — never color alone (this rule is already stated in `AppSemanticColors`'s doc comment and is ratified, not invented, here).
4. **Motion explains state change; it does not decorate.** Section 15 formalizes this as a hard boundary.
5. **The product should feel like *one app*, not eight features bolted together.** Every module-specific screen (Finance, Tasks, Habits, Goals, Notes, Calendar, Assets, Documents) uses the exact same card shape, spacing rhythm, empty-state pattern, and app-bar behavior. Only the accent color and the icon change. This is the single most important principle in this document — it is also the one most at risk as more feature teams work in parallel, which is why Section 18 (Rollout) exists.

### 1.2 Consistency Rules

- No feature package defines its own spacing, radius, elevation, or type-scale value. Every numeric UI value traces to a token in `packages/design_system`.
- No feature package defines its own card, list tile, empty state, loading state, or error state widget. If a feature's data doesn't fit an existing component's shape, that is a Design System gap to raise, not a reason to build a one-off.
- A component's states (loading / content / empty / error) are always rendered by the *same* wrapper widget (`AppStateSwitcher`, already implemented) — no feature hand-rolls its own `if (loading) ... else if (error) ...` ladder.

### 1.3 Simplicity

- Every screen should be describable in one sentence of "what is this for." If a screen needs a paragraph, it's doing too much and should be split.
- Prefer one primary action per screen (one FAB, one dominant button) over multiple competing calls to action.
- Settings/configuration is allowed to be denser than content screens — but still token-driven.

### 1.4 Information Hierarchy

A strict three-tier reading order, top to bottom, applies to every content screen:

1. **Orientation** — where am I, what module, what filter/date range is active (AppBar + optional filter row).
2. **The one number or state that matters most** — an account balance, today's task count, this week's habit streak, the next event. This is the "hero" element (Section 9.3).
3. **The list** — everything else, in a scannable, uniformly-styled list/grid.

No screen should make the user hunt for #2 below a fold of unrelated content.

---

## 2. Color System

### 2.1 Principle: Semantic Tokens Only

**No screen, widget, or feature package references a raw `Color(0xFF...)` value or a raw Material color constant.** Every color used anywhere in the app resolves through one of two paths:

1. `Theme.of(context).colorScheme.*` — Material 3's standard roles (primary, secondary, tertiary, surface, error, outline, etc.), seeded once via `ColorScheme.fromSeed` in `AppThemeBuilder`.
2. `Theme.of(context).extension<AppSemanticColors>()!.*` — product-meaning roles that `ColorScheme` doesn't have a slot for (positive/negative/warning/success/neutral, and per-module accents).

This is already how `AppThemeBuilder` and every existing component are written; this document ratifies it as a **hard rule**, not a preference. A `dart analyze` custom lint (or a code-review checklist item, since a new lint rule is implementation, not design) enforcing "no `Color(0x` literal outside `design_system`'s own theme files" is recommended as a follow-up engineering task, not part of this document.

### 2.2 Core Semantic Roles

These map onto Material 3 `ColorScheme` slots, which Personal OS already gets "for free" from `ColorScheme.fromSeed`. No new token type is needed — this table exists so every designer/engineer reads the same names for the same roles.

| Token (design language) | `ColorScheme` role | Usage |
|---|---|---|
| Primary | `primary` / `onPrimary` | Primary actions, active nav indicator, FAB |
| Primary Container | `primaryContainer` / `onPrimaryContainer` | Selected chip, highlighted card |
| Secondary | `secondary` / `onSecondary` | Secondary emphasis, selected nav indicator (already used by `NavigationBarThemeData.indicatorColor` via `secondaryContainer`) |
| Tertiary | `tertiary` / `onTertiary` | A third accent for charts/data-viz only (Finance category charts) — never for chrome or primary actions |
| Surface | `surface` | Screen background |
| Surface Variant / Container tiers | `surfaceContainerLow/Low/High/Highest` | Cards (`surfaceContainerLow`, already used), sheets, dialogs (`surfaceContainerHigh`, already used), input fills (`surfaceContainerHighest`, already used) |
| Background | `surface` (M3 merges background into surface) | No separate "background" token — M3's own guidance deprecates a distinct background role; this avoids a second, redundant token nobody should introduce |
| Outline | `outline` / `outlineVariant` | Borders, dividers between distinct regions |
| Divider | `outlineVariant` at low emphasis | List-item separators — never a hardcoded grey |
| Disabled | `onSurface` at 38% opacity (M3 standard) | Disabled text/icon; disabled containers use `onSurface` at 12% opacity per M3 spec |
| Error | `error` / `onError` / `errorContainer` | Validation errors, destructive-action confirmation accents |

**Decision requiring approval:** whether "Info" (requested in the brief) becomes its own `ColorScheme`/extension role or is folded into `neutral` (already implemented in `AppSemanticColors`). Material 3 has no native "info" role, and introducing a 6th semantic extension color for a use case (informational banners, tips) that `neutral` already covers risks token proliferation. **Recommendation: fold Info into the existing `neutral` token; do not add a 6th semantic color.** Flagged in Section 20.

### 2.3 Semantic Meaning Tokens (Beyond `ColorScheme`)

Already implemented in `AppSemanticColors` — ratified as final:

| Token | Meaning | Current value (light / dark) |
|---|---|---|
| `positive` | Income, gains, on-track figures | `#1E8E3E` / `#81C995` |
| `negative` | Expenses, overdue, off-track | `#C5221F` / `#F28B82` |
| `warning` | Upcoming bills, low-balance cautions | `#9A6800` / `#FDD663` |
| `neutral` | Transfers, pending, informational | `#1A73E8` / `#8AB4F8` |
| `success` | Completed tasks/habits, goals reached | `#1E8E3E` / `#81C995` |

Note `positive` and `success` currently share a value. This is intentional, not a bug: they are semantically distinct concepts (a financial gain vs. a completed action) that happen to warrant the same green in this palette. Keep them as two named tokens (not one) so a future palette change can diverge them without a rename.

### 2.4 Feature Accent Colors

Already implemented in `AppSemanticColors.moduleAccents` — ratified as final, with one addition needed (Notes and AI were added ad hoc; this table is the first complete, intentional pass):

| Module | Light | Dark | Icon pairing (Section 7) |
|---|---|---|---|
| Finance | `#1565C0` (blue) | `#8AB4F8` | `account_balance_wallet` |
| Tasks | `#8430CE` (purple) | `#D7AEFB` | `check_circle` |
| Habits | `#B7590E` (burnt orange) | `#FDBA74` | `repeat` / `loop` |
| Goals | `#00695C` (teal) | `#80CBC4` | `flag` |
| Notes | `#F9A825` (amber) | `#FFF59D` | `sticky_note_2` / `description` |
| Calendar | `#C5221F` (red) | `#F28B82` | `calendar_today` |
| Assets | `#3949AB` (indigo) | `#AEC6FA` | `inventory_2` |
| Documents | `#6D4C41` (brown) | `#BCAAA4` | `folder` |

**Rule for accent usage (formalizing existing but unwritten practice):** a module accent color appears in exactly three places — (1) the module's icon on Home/Nav, (2) the module's `ModuleCard` icon background, (3) a thin left-border or small badge inside that module's own screens for module-identity continuity (e.g. a Finance transaction's category dot). **It never becomes a full-screen background, a full-width banner, or a primary-button color** — that would compete with `ColorScheme.primary` and break the "one app" principle (1.1 #5).

**Observation, not yet a decision:** Calendar's accent (`#C5221F`, red) is identical to `negative`'s semantic red. On a screen that shows both a Calendar accent *and* a negative financial figure (e.g. a Home dashboard combining both cards), these could visually blur. **Recommendation: keep as-is** — they never appear in the same visual context in the current dashboard layout (Section 9), but flag this as a constraint future dashboard layouts must respect: never place a Calendar-accented element directly adjacent to a negative-financial-figure element without a separating card boundary.

---

## 3. Typography

### 3.1 Hierarchy

Personal OS already builds on Material 3's `Typography.material2021` scale via `AppTypography.textTheme()`, tuning specific role weights. This section formalizes the *usage* rules the existing scale didn't yet have written down.

| Role | M3 `TextTheme` slot | Size / weight (M3 default, as tuned) | Usage |
|---|---|---|---|
| **Display** | `displayLarge` / `displayMedium` / `displaySmall` | 57/45/36sp, regular | Reserved for rare full-screen moments only — a goal-achieved celebration screen, onboarding hero text. **Not used in any list/dashboard/form context.** |
| **Headline** | `headlineLarge` / `headlineMedium` / `headlineSmall` | 32/28/24sp; `headlineSmall` tuned to w600 | Screen-level titles when *not* in an AppBar (e.g. a large greeting on Home: "Good morning, Rohan") |
| **Title** | `titleLarge` / `titleMedium` / `titleSmall` | 22/16/14sp, all tuned to w600 | AppBar titles (`titleLarge`, already used), section headers (`titleMedium`), card titles (`titleSmall`) |
| **Body** | `bodyLarge` / `bodyMedium` / `bodySmall` | 16/14/12sp, regular | Primary content text, list-item subtitles, form field values |
| **Label** | `labelLarge` / `labelMedium` / `labelSmall` | 14/12/11sp; `labelLarge` tuned to w600 | Buttons, chips, nav destination labels, form field labels |
| **Caption** | Mapped to `bodySmall` at reduced emphasis (M3 has no separate "caption" slot — this avoids inventing a 7th scale outside the M3 spec) | 12sp, `onSurfaceVariant` color | Timestamps, helper text, metadata rows |

**Decision requiring approval:** whether to introduce a true 7th "Caption" `TextStyle` distinct from `bodySmall`, or keep Caption as a *usage convention* (bodySmall + `onSurfaceVariant` color) rather than a new style object. **Recommendation: usage convention, not a new style** — M3's scale deliberately has no caption slot, and every reference app (Notion Mobile, Google Tasks) achieves "caption" purely via color/opacity on their smallest body size, not a separate font size.

### 3.2 Rules

- No screen sets an inline `TextStyle(fontSize: ...)`. Every text widget references `Theme.of(context).textTheme.*`.
- Weight tuning (the w600 overrides already present in `AppTypography`) exists to create **hierarchy without size jumps** — a title and a subtitle can be the same size but different weight, which reads as calmer than aggressive size jumps (this is a direct match to Notion Mobile and Apple Health's approach).
- Numbers that matter (balances, counts, streaks) may use `FontFeature.tabularFigures()` for alignment in lists — this is a `TextStyle` feature, not a new token, and is a recommendation for the `MoneyText`/`StatCard` component contract, not a new component.

---

## 4. Spacing System

Already fully implemented in `AppSpacing` — **ratified as final, no changes recommended.**

| Token | Value | Usage (as documented in source) |
|---|---|---|
| `xs` | 4dp | Icon-to-label gaps, chip internal padding |
| `sm` | 8dp | Between related inline elements |
| `md` | 16dp | Default screen margin, card internal padding, list-item vertical rhythm |
| `lg` | 24dp | Between distinct sections on a screen |
| `xl` | 32dp | Above/below the first section, empty-state vertical centering |
| `xxl` | 48dp | Major screen-to-screen breathing room on tablet/desktop |

The brief's example scale (4/8/12/16/20/24/32/40/48) includes two steps (12, 20, 40) the current implementation doesn't have. **Recommendation: do not add them.** A 6-step scale is already tight and well-used; adding intermediate steps invites the exact "arbitrary spacing" problem this section exists to prevent — a designer choosing between `md` (16) and a hypothetical `14` because "it looked a little tight" is precisely the failure mode a small, opinionated scale prevents. If a genuine gap is found (a real screen that needs something between two existing tokens), it should be raised as a specific, justified addition — not a wholesale scale replacement.

**Rule:** every `Padding`, `SizedBox`, and `EdgeInsets` value in the entire app is one of these six constants, or a sum/multiple of them (e.g. `AppSpacing.md * 2`). No raw integer literals.

---

## 5. Border Radius

Already implemented in `AppRadius` — ratified as final:

| Token | Value | Usage |
|---|---|---|
| `card` | 16dp | Resting cards, `StatCard`/tile-family components |
| `large` | 28dp | Dialogs and bottom sheets (top corners) |
| `chipStadium` | 9999 (stadium) | Chips — full pill shape |

**Gap identified:** there is no explicit small-radius token for buttons — `AppThemeBuilder`'s `_filledButtonTheme`/`_outlinedButtonTheme` currently hardcode `BorderRadius.circular(AppSpacing.lg)` (i.e. reusing the spacing token `24` as a radius value). This works today but conflates two different token families. **Recommendation:** introduce one more radius token, `AppRadius.button = 24`, purely to stop borrowing a spacing constant for a radius purpose — a one-line addition, flagged here as a decision, not performed by this document.

---

## 6. Elevation

Already implemented in `AppElevation` — ratified as final. Personal OS correctly follows M3's preference for **tonal elevation** (surface color shift) over drop shadows for resting content:

| Surface | Elevation | Rationale |
|---|---|---|
| Cards (resting) | 0 | Tonal only (`surfaceContainerLow`), no shadow — calm, flat reading surface |
| AppBar (resting) | 0 | Flat until content scrolls beneath it |
| AppBar (scrolled) | 2 | Standard M3 scroll-under elevation cue |
| Navigation bar/rail | 2 | Persistent chrome, subtle separation from content |
| Bottom sheet | 1 | Lower than dialogs — sheets are contextual, not blocking |
| Dialog | 3 | Blocking, needs to read as "above everything" |
| FAB | 3 | Matches dialog — both are the most prominent interactive surfaces on their screen |
| Snackbar | 3 | Transient overlay, same prominence tier as dialog/FAB |

No new elevation values are recommended. The existing scale already encodes the correct principle: **flat by default, elevated only for transient/overlay surfaces** — exactly the Apple Health / Notion Mobile visual language this brief asks for.

---

## 7. Iconography

### 7.1 Recommended Icon Family: **Material Symbols (Rounded)**

**Recommendation: standardize on Material Symbols, Rounded variant, weight 400 (regular), as the single icon family for the entire app.**

Why:

1. **Already the de facto family in use.** Every existing component (`TaskTile`, `AccountTile`, `ModuleCard`, `ShellDestination`) uses Flutter's built-in `Icons.*` set, which *is* Material Symbols (Flutter's `Icons` class ships Material Symbols under the hood as of the current Material 3 icon set). Standardizing formalizes existing practice rather than requiring a migration.
2. **Rounded terminals match the brand goals.** The brief asks for "calm," "premium," "minimal." Material Symbols' Rounded variant (soft line terminals, no sharp corners) reads noticeably calmer than the Sharp or the older Outlined-only set — this is the same choice Google Tasks and Google Calendar themselves made in their most recent redesigns.
3. **Filled-vs-outlined state pairing is built in.** Every `ShellDestination` already distinguishes `icon` (unselected, outlined) vs `selectedIcon` (selected, filled) — Material Symbols is the only major icon family with matched outlined/filled pairs for essentially every glyph, which this exact pattern depends on.
4. **No new dependency.** Material Symbols' rounded style is selectable via `IconData` font-family variants already bundled with Flutter's Material package — no new font asset, no new pub dependency, no bundle-size cost.

**Decision requiring approval:** whether to invest in importing the `material_symbols_icons` package (which exposes the full, larger Material Symbols glyph set including many icons not in Flutter's built-in `Icons` class) versus staying within Flutter's built-in set. **Recommendation: stay within Flutter's built-in `Icons` class.** Every icon usage audited across the current `design_system`/feature packages already resolves from `Icons.*`; the built-in set has proven sufficient for all 8 modules to date, and a new font dependency is an implementation cost this design document should flag but not decide.

### 7.2 Icon Sizing

Already implemented in `AppIconSizes` — ratified as final:

| Token | Value | Usage |
|---|---|---|
| `inline` | 20dp | Inside text rows (e.g. a delta arrow next to a stat value) |
| `standard` | 24dp | List leading icons, AppBar actions — the default |
| `avatar` | 32dp | Module/avatar icons (e.g. `ModuleCard`'s leading icon) |
| `empty` | 48dp | Empty-state and large illustrative icons |

No new sizes recommended — four sizes covers every icon context observed across the current component set.

---

## 8. Component Library

This section maps the brief's requested component list onto what already exists in `packages/design_system/lib/src/components/`, and calls out the small number of genuine gaps.

| Requested component | Existing equivalent | Status |
|---|---|---|
| AppCard | `ModuleCard`, `SummaryCard` (display/) | **Exists** — two variants already cover "module summary card" and "generic content card." No new generic `AppCard` needed unless a genuine third shape emerges. |
| SectionHeader | `SectionHeader` (foundation/) | **Exists**, ratified |
| PrimaryButton | `FilledButton` via `AppThemeBuilder._filledButtonTheme` | **Exists as a themed Material widget**, not a custom wrapper — this is the correct approach; a custom `PrimaryButton` wrapper would only be justified if it needed behavior `FilledButton` can't express, which it currently doesn't |
| SecondaryButton | `OutlinedButton` via `_outlinedButtonTheme` | **Exists**, same reasoning |
| FAB | Standard Material `FloatingActionButton`, themed via `AppElevation.fab`; `FloatingActionMenu` (input/) for multi-action cases | **Exists** |
| SearchBar | `AppSearchBar` (input/) | **Exists**, ratified |
| EmptyState | `EmptyState` (foundation/), orchestrated via `AppStateSwitcher` | **Exists** — see Section 12 for the unified pattern |
| LoadingState | `LoadingState`, `SkeletonList` (foundation/) | **Exists** — see Section 13 |
| ErrorState | `ErrorState` (foundation/) | **Exists** — see Section 14 |
| ConfirmationDialog | `ConfirmationDialog` (forms/) | **Exists**, ratified |
| BottomSheet | `AppBottomSheetForm`, `showAppInputSurface` (forms/) | **Exists**, ratified |
| Snackbar | Standard Material `SnackBar`, themed via `_snackBarTheme` | **Exists** |
| TextField | `AppFormField`, themed `InputDecorationTheme` | **Exists** |
| Chips | Themed standard Material `Chip`/`FilterChip` via `_chipTheme`; `StatusChip` (display/) for semantic-colored status chips | **Exists** |
| Tags | No dedicated "Tag" widget distinct from `Chip` today | **Gap — see below** |
| Progress Indicators | `ProgressRing`, `ProportionBar` (display/) | **Exists** |

**Gap identified — Tags.** The brief distinguishes "Chips" from "Tags." Today there is one chip-family widget (themed `Chip`) plus `StatusChip` for status-with-semantic-color. A "Tag" (e.g. a Notes label, a Documents category tag) is visually near-identical to a chip but carries user-assigned, arbitrary-colored metadata rather than a fixed semantic state. **Recommendation: do not create a new `AppTag` widget.** A themed, non-interactive `Chip` (already available) fully covers this need — reusing the existing chip shape. This keeps "one card shape, one chip shape" consistent with Section 1.2, rather than introducing a visually-identical-but-differently-named second widget. **This is a decision requiring approval** since it closes a gap the brief explicitly named — flagged in Section 20.

**Component contract note (applies to all of the above, not a new rule):** every stateful component that has a loading/content/empty/error lifecycle (i.e. anything backed by an `AsyncState<T>`) is expected to compose with `AppStateSwitcher`, not implement its own state branching. This is already true for every ViewModel-backed page in the codebase.

---

## 9. Dashboard

### 9.1 Current State

The Home Dashboard (`apps/mobile/lib/app/home/home_dashboard_page.dart`) already implements: a greeting header, per-module `ModuleCard`s (Finance, Tasks; others pending their own build-out), a "Recent" section, and a "More modules" placeholder grid for modules not yet promoted to a full card. This is the correct shape — Section 9.2–9.4 formalize the rules for extending it to all 8 modules without it becoming cluttered.

### 9.2 Card Layout

- **One `ModuleCard` per module, uniform size** (already the case for Finance/Tasks). No module gets a visually larger or more prominent card than another — module importance is expressed through *position* (higher = more frequently used, user-configurable in a future release, not this phase) not through size.
- Cards render in a single-column list on Compact width, and a responsive grid (2–3 columns) at Medium/Expanded width — this already exists via `AppBreakpoints` and should extend unchanged to every module's card as it's built.
- A `ModuleCard` shows **at most two stat values** (already the pattern: Finance shows one net-balance figure, Tasks shows Active + Completed today). More than two invites the dashboard to become a data-dump, which directly contradicts the "calm" goal.

### 9.3 Hero Card

**Recommendation:** promote exactly one card to "hero" position — full width, taller, above the uniform module grid — showing the single most time-sensitive item across the whole app: **today's agenda** (next Calendar event + due-today Tasks count, once Calendar ships its own ViewModel). This mirrors Google Calendar's and Apple Health's own home-screen pattern (today's ring / today's schedule, always first, always full-width). This is a **new layout decision**, not yet implemented — flagged for approval in Section 20, since it requires a cross-module ViewModel composition (Calendar + Tasks) that doesn't exist yet and is an implementation concern for a future sprint, not this document.

### 9.4 Section Spacing

- `AppSpacing.lg` (24dp) between distinct dashboard sections (greeting → hero card → module grid → "more modules").
- `AppSpacing.md` (16dp) between cards within the same section/grid.
- This matches the existing `home_dashboard_page.dart` structure and should not change.

### 9.5 Statistics Display

Every stat shown on a `ModuleCard` uses the `StatCard` component (already implemented, already used by Tasks' Active/Completed-today pair) — never a raw `Text` + `Icon` row assembled ad hoc per feature. This is the single most important dashboard consistency rule: **if a module needs a new stat, it uses `StatCard`; it never invents a new stat-display shape.**

---

## 10. Navigation

### 10.1 Current State — The Problem

`ShellBranches` currently defines 4 branches: **Home, Finance, Tasks, Settings**. This was correct through Milestone 7 (only Finance and Tasks had real presentation layers). But the architecture list at the top of this brief confirms **8 content modules are now architecturally complete** (Finance, Tasks, Habits, Goals, Notes, Calendar, Assets, Documents) plus Settings — a **9-destination navigation problem**, not a 4-destination one. The brief is correct that "current bottom navigation has too many items" is the wrong-shaped complaint at 4 items, but exactly the right concern to raise **now**, before 8 more branches get added one-by-one the same way Tasks was, which would produce an unusable 9-item bottom bar.

### 10.2 Why a Flat Bottom Nav Fails at This Scale

Material 3's own guidance caps bottom navigation at 3–5 destinations. Every reference app in this brief agrees in practice:

- **Google Calendar**: no bottom nav at all — single-purpose app.
- **TickTick**: 4 bottom destinations (Tasks, Calendar, Habits/Pomodoro tab, Me/Settings) plus a "+" quick-add — everything else lives behind "Me" or a side drawer.
- **Notion Mobile**: 4 bottom destinations (Home, Search, Inbox, "+ New") — every actual workspace/page lives inside "Home," not as its own tab.
- **Google Tasks**: single-purpose, no bottom nav.
- **Wallet by BudgetBakers**: 5 bottom destinations, but 3 of them (Records, Planning, Reports) are all *within* the finance domain — it does not attempt to surface unrelated modules as peers.

The pattern is consistent: **no reference product puts more than 5 unrelated top-level domains in a bottom bar.** Personal OS, with 8 content modules, structurally cannot follow a "one tab per module" approach without violating every product this brief asks it to resemble.

### 10.3 Recommended Navigation Architecture

**Recommendation: 5-destination bottom nav — Home, Finance, Tasks, Calendar, More — matching the brief's own example exactly.**

| Destination | Rationale |
|---|---|
| **Home** | Orientation + cross-module summary (existing) |
| **Finance** | Highest-frequency, most distinct domain (DOC-001 names it a P1 priority); already has the deepest existing feature set (Accounts/Transactions/Categories) |
| **Tasks** | Second-highest-frequency daily-use domain; already fully built |
| **Calendar** | Time-anchored planning is a distinct daily mental mode from task-checking — every reference app that has both (TickTick) keeps them as separate peers, not nested |
| **More** | Habits, Goals, Notes, Assets, Documents, Settings — a single entry point to a secondary navigation surface (Section 10.4) |

This directly matches the brief's own suggested example, arrived at independently from the reference-app analysis above rather than simply accepting the example as given — both paths converge on the same 5 destinations, which is a good sign the recommendation is sound rather than arbitrary.

### 10.4 "More" Surface Design

**Recommendation:** "More" is not a 5th bottom-nav *branch* in the `StatefulShellRoute.indexedStack` sense — it is a **grid/list page** (reusing the existing `ModuleCard` component from Section 8) listing Habits, Goals, Notes, Assets, Documents, and Settings, each navigating to its own top-level route outside the shell's persistent-state branches. This is a **navigation architecture decision requiring approval** since it's a structural change to how `ShellBranches`/`AppRouter` are organized (5 persistent branches → 4 persistent + 1 "hub" page), even though implementing it is out of scope for this document.

Rejected alternative: a `NavigationDrawer` (side drawer) instead of a "More" tab. **Rejected because** none of the calm/minimal reference apps (Notion Mobile, Google Tasks, Apple Health) use a drawer as primary navigation on mobile — drawers read as "desktop navigation ported to mobile" and work against the "modern, premium, minimal" goal. A drawer remains reasonable as a *secondary*, Expanded-width-only affordance (already partially true — `NavigationRail` already exists for wide viewports) but should not replace the bottom nav's "More" entry on Compact width.

### 10.5 Migration Note (Not Performed by This Document)

Moving from today's 4-branch shell (Home, Finance, Tasks, Settings) to the 5-destination model (Home, Finance, Tasks, Calendar, More) requires: adding a Calendar branch (mirroring how Tasks was added), and converting Settings from a persistent branch into a destination reachable from the "More" hub. This is a real, non-trivial navigation refactor and is explicitly **out of scope for this design document** — it is listed here so the decision is visible before any team starts building Calendar's or Habits' presentation layer against the current 4-branch assumption.

---

## 11. Feature Screens

Common layout rules, applicable to Habits, Goals, Notes, Calendar, Assets, Documents as they build out their presentation layers — mirroring the pattern Finance and Tasks already established.

### 11.1 List Screens

- AppBar with the module name as title (`titleLarge`).
- Optional filter/search row directly beneath the AppBar (already the pattern for `AppSearchBar`/`filter_bar.dart`).
- Content area wrapped in `AppStateSwitcher<List<T>>` — loading → skeleton, empty → `EmptyState`, error → `ErrorState`, success → list of the module's tile component (already the exact pattern `TasksPage`/`AccountsPage` use).
- List items use the module's own tile component (`TaskTile`, `AccountTile`, `HabitTile`, `GoalCard`, `TransactionTile`, `EventTile`, `AssetTile`, `DocumentTile` — all already exist in `design_system`), never a raw `ListTile`.
- A single FAB for the primary "create new" action, bottom-right, standard Material position.

### 11.2 Form Screens (Create/Edit)

- Presented as a bottom sheet (`AppBottomSheetForm`/`showAppInputSurface`) for short forms (2–4 fields, e.g. quick task/habit entry) — already the pattern `TasksPage`'s create/edit flow uses.
- Presented as a full-screen page (not a bottom sheet) only when the form has enough fields that a sheet would need internal scrolling *and* still feel cramped (e.g. a Finance transaction with account, category, amount, date, notes, attachment — arguably already at this threshold). **Recommendation:** any form with more than 5 fields is a full-screen route, not a sheet. This is a threshold worth stating explicitly so feature teams don't each independently guess.
- Every form field uses `AppFormField` — consistent label, error, helper-text styling.
- Primary action (Save/Create) is a `FilledButton`, full-width or trailing depending on sheet vs. full-screen context; destructive/cancel actions are `TextButton`, never visually competing with the primary action.

### 11.3 Detail Pages

- Not yet built for any module (Finance/Tasks currently only have list + inline edit, no dedicated detail page). **Recommendation for when they are built:** AppBar with the item's title, a hero section showing the item's most important 1–2 fields at `headlineMedium`/`titleLarge`, then a scrollable body of remaining metadata grouped under `SectionHeader`s — mirroring how Apple Health's detail screens present one big number first, then supporting detail below.

### 11.4 CRUD Screen Consistency

Every module's list → create → edit → delete flow follows the identical interaction shape already established by Tasks (Milestone 7): tap item to edit, swipe to delete (with undo `Snackbar`, already implemented for Finance transactions and worth extending as a pattern), FAB to create. **No module invents a different CRUD interaction pattern** (e.g. long-press-to-delete) unless a component genuinely lacks the affordance Tasks needed to work around (as already documented for `TaskTile`'s missing `onLongPress` in the Milestone 7 report) — and even then, the fallback should be chosen from this document's existing patterns (dialog-embedded secondary action), not invented fresh per feature.

---

## 12. Empty States

**One reusable pattern, already implemented as `EmptyState` (foundation/):** icon (at `AppIconSizes.empty`, 48dp, using the module's own icon at low emphasis — `onSurfaceVariant` tone, not the module accent color, to avoid an empty state looking like an error/alert), a short title (`titleMedium`), an optional one-line supporting sentence (`bodyMedium`, `onSurfaceVariant`), and an optional single action button (e.g. "Add Task").

**Rule:** every module's empty state differs *only* in icon + copy — never in layout, spacing, or button style. This is already how `AppStateSwitcher`'s `emptyIcon`/`emptyTitle`/`emptyActionLabel` parameters are structured, so the rule is a formalization of an existing contract, not a new one.

---

## 13. Loading States

**Rule: skeleton for content the user is about to scan (lists, cards); spinner only for short, single-outcome waits (initial page mount, a form submission).**

- **Skeleton** (`SkeletonList`, already implemented): used for any list/grid screen's initial load — because it previews the *shape* of the content about to appear, which reads as faster and calmer than a spinner (this is precisely why Notion Mobile, LinkedIn, and every modern "feed" app moved away from spinners for lists years ago).
- **Spinner** (`LoadingState`, already implemented; also the bare `CircularProgressIndicator` already used inside `ModuleCard`'s loading branch): used for (a) a `ModuleCard`'s compact loading slot where a skeleton would be visually heavier than the final content, and (b) transient action feedback (submit button shows an inline spinner while saving) — never for a full list.
- **Never both on the same screen simultaneously** — a screen is either in "first load" (skeleton) or "action in flight" (spinner on the specific control), not both at once.

---

## 14. Error States

**One unified pattern, already implemented as `ErrorState` (foundation/) + `ModuleCard`'s inline error branch:**

- **Full-screen error** (a list/detail page's entire content failed to load): icon (error-toned, `onSurface`/`error` pairing per M3 contrast guidance — never a raw red splash), a short human-readable message (never a raw exception string/stack trace), and a "Retry" `FilledButton`/`TextButton`.
- **Card-level error** (a single `ModuleCard` failed while the rest of the dashboard is fine — already implemented): a short inline message only, no retry button inside the card itself (retry happens via the dashboard's own pull-to-refresh, already implemented) — this is what "Loading / Error isolation" in `ModuleCard`'s own doc comment already establishes, and this document ratifies it as the dashboard-wide rule.
- **Never a raw red `Container`/banner as the primary error affordance** — errors are communicated through the same card/page shape as everything else, with color as a secondary signal (consistent with Section 1.1 #3).

---

## 15. Animations

**Principle: motion explains a state change; it never decorates.** Already encoded in `AppMotion`'s tokens and doc comments — ratified, with usage rules made explicit:

| Motion token | Duration | When to use |
|---|---|---|
| `fast` (200ms) | Micro-interactions — chip select, checkbox toggle, swipe-to-reveal |
| `standard` (250ms) | State transitions — Loading ⇄ Content ⇄ Empty ⇄ Error (already the exact use named in the token's own doc comment) |
| `page` (300ms) | Page/shared-axis transitions between routes |
| `celebration` (600ms) | **Explicitly-justified moments only** — goal completion, streak milestone. Already documented as "never used for routine UI feedback," which this document underlines as a hard rule, not a suggestion. |

**Do-not list (formalizing "do not overuse animation"):**
- No animated list-item entrance (items sliding/fading in one-by-one) on ordinary list loads — this is decoration, not explanation, and directly works against the "calm" goal by making every screen load feel like a showcase.
- No bouncy/elastic curves anywhere — `AppMotion` already defines exactly two curves (`standardCurve` = `easeInOutCubic`, `decelerateCurve` = `decelerate`), both calm, neither playful. No component should reach for `Curves.elasticOut` or similar.
- Reduced-motion (`AppMotion.durationOrZero`, already implemented) must be respected by every future animated component exactly as it already is by existing ones — this is an accessibility requirement (Section 17), not optional polish.

---

## 16. Dark Theme

Already implemented — `AppThemeBuilder.build(brightness: ...)` produces a complete dark `ThemeData` via `ColorScheme.fromSeed(brightness: Brightness.dark)`, and `AppSemanticColors` already defines distinct light/dark values for every semantic and module-accent token (Section 2.3–2.4).

**Recommendations (refinement, not replacement):**
- Dark surfaces should stay on M3's tonal surface-container ladder (already the case via `surfaceContainerLow/High/Highest` in `AppThemeBuilder`) rather than pure black — pure black (`#000000`) backgrounds read as "OLED battery-saver mode," not "premium," and none of the reference apps (Notion Mobile, Apple Health) use true black as their default dark theme.
- Elevation in dark mode should lean slightly more on the M3 "lighter surface = higher elevation" tonal convention than in light mode, since drop-shadow cues (already minimal per Section 6) read even less clearly on dark backgrounds — this is already M3's default behavior via `ColorScheme.fromSeed`, requiring no extra work, just confirmation during visual QA (Section 18).
- No change recommended to the module accent colors' dark variants — they were already chosen with dark-mode contrast in mind (Section 2.4 table).

---

## 17. Accessibility

### 17.1 Contrast

- Every semantic/accent color pairing (Section 2.3–2.4) must meet WCAG AA (4.5:1 for body text, 3:1 for large text/icons) against the surface it appears on. This is **already partially enforced**: `AppThemeBuilder`'s own doc comment cites `app_semantic_colors_test.dart`'s "contrast-ratio assertions" as verification, not manual review alone — this document extends that same bar to the two new/refined tokens in Section 5/7 if adopted.
- Module accent colors used as small identity marks (Section 2.4) are exempt from the body-text contrast bar (they're never used *as* text color against a busy background) but must still meet 3:1 as a graphical element per WCAG 1.4.11.

### 17.2 Touch Targets

- Minimum 48×48dp for every tappable control — already enforced in `AppThemeBuilder`'s `FilledButtonThemeData`/`OutlinedButtonThemeData`/`TextButtonThemeData` (`minimumSize: const Size(48, 48)`, already present in all three). This document extends the same minimum as a **hard rule for every new interactive component**, not just themed buttons — swipe-to-dismiss targets, chip taps, and icon-only buttons must all meet it.

### 17.3 Typography

- Every text style resolves through `Theme.of(context).textTheme` (Section 3.2) — this is also what makes system-level dynamic text scaling (17.4) work automatically; no component may hardcode a pixel font size that would resist scaling.

### 17.4 Dynamic Text Scaling

- The app must remain usable up to at least 200% system text scale (Android/iOS accessibility large-text settings) without clipped text or overlapping layout. Since no component in this design language uses fixed-height text containers for content that scales (a rule already implicit in using `TextTheme` roles rather than fixed-size boxes), this should largely fall out of following Section 3 correctly — but it is called out explicitly here as a **required manual QA pass per feature screen**, not an assumption.
- `AppMotion.durationOrZero`'s reduced-motion handling (Section 15) is the equivalent pattern already solved for motion; text scaling has no equivalent single-point token today because Flutter's `MediaQuery.textScaler` is inherited automatically by `Text`/`TextTheme` — no new token is needed, only QA discipline.

---

## 18. Implementation Strategy

### 18.1 Principle

This document changes **zero code**. Rollout is entirely about how feature teams adopt it going forward without regressing the modules that already conform (Finance, Tasks, App Shell, Dashboard).

### 18.2 Phased Rollout

1. **Phase 1 — Ratification (this document).** Architecture review approves DOC-033 as written, or returns specific open decisions (Section 20) for a decision before Phase 2 begins.
2. **Phase 2 — Retrofit the two small gaps identified in Sections 5 and 8** (the `AppRadius.button` token; the explicit "Tags reuse Chip" decision) into `packages/design_system`, if approved — small, additive, non-breaking changes to the existing package, reviewed independently of this document.
3. **Phase 3 — Build remaining modules' presentation layers against this spec from day one.** Habits, Goals, Notes, Calendar, Assets, Documents each follow the exact `AsyncState` + `AppStateSwitcher` + module tile + Section 11 layout pattern Finance/Tasks already established — no new pattern invented per module. Each module's presentation-layer milestone (mirroring how Milestone 7 built Tasks against Finance-as-reference) treats **this document**, not the previous feature, as the reference — preventing pattern drift where each new module copies the *previous* module's small deviations forward.
4. **Phase 4 — Navigation migration (Section 10.5).** Performed as its own dedicated milestone once at least Calendar's presentation layer exists (since the 5-destination model needs a real Calendar branch, not a placeholder) — not bundled into any single feature's milestone, to keep the navigation restructuring reviewable in isolation.
5. **Phase 5 — Dashboard hero card (Section 9.3).** Deferred until both Calendar and Tasks ViewModels can be composed together — explicitly sequenced *after* Phase 4, since it depends on Calendar existing as a real navigation destination first.

### 18.3 Regression Safety

- Every phase above is additive or confined to a single not-yet-built module — **Finance and Tasks' existing screens are never touched by this rollout**, since they already conform to everything in this document (they were, in effects, this document's source material).
- No phase requires a "big bang" visual re-theme. `AppThemeBuilder`/tokens are already correct; rollout is about *discipline in new code*, not *migration of old code*.
- Each new module's presentation-layer milestone should include an explicit self-review checklist item: "confirms every screen traces every color/spacing/radius/motion value to a DOC-033 token, with no local literals" — mirroring the self-review discipline already used in the Tasks Milestone 7 report.

---

## 19. Summary of Recommendations

1. **Ratify, don't replace** the existing token set (`AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`, `AppIconSizes`, `AppTypography`, `AppSemanticColors`) as the formal DOC-033 spec — it was already built correctly; this document is its missing written record.
2. **Do not expand the spacing scale** beyond the existing 6 steps; reject the brief's 9-step example as unnecessarily granular for a system this size.
3. **Add one radius token** (`AppRadius.button`) to stop buttons borrowing a spacing constant.
4. **Do not add a 6th semantic color** for "Info" — fold it into the existing `neutral` token.
5. **Do not create a separate "Tag" widget** — reuse the existing themed `Chip` for tag-like metadata.
6. **Adopt Material Symbols (Rounded), staying within Flutter's built-in `Icons` set** — no new icon-font dependency.
7. **Restructure navigation to 5 top-level destinations** (Home, Finance, Tasks, Calendar, More) — the current 4-branch shell does not scale to 8 modules; "More" is a hub page (reusing `ModuleCard`), not a 6th persistent branch.
8. **Promote a "today" hero card** on the Home Dashboard, sequenced after Calendar exists.
9. **Formalize (not change) existing empty/loading/error patterns** as the single reusable pattern for every module, present and future.
10. **Cap celebratory motion strictly** — `celebration` (600ms) is reserved for goal/streak moments only; no list-entrance animation anywhere.

## 20. Decisions Requiring Approval

| # | Decision | Recommendation | Section |
|---|---|---|---|
| D1 | Fold "Info" into `neutral`, or add a 6th semantic color? | Fold into `neutral` | 2.2 |
| D2 | Add `AppRadius.button` token? | Yes, add | 5 |
| D3 | Build a distinct "Tag" widget, or reuse `Chip`? | Reuse `Chip` | 8 |
| D4 | Add `material_symbols_icons` package for the full glyph set, or stay within Flutter's built-in `Icons`? | Stay built-in | 7.1 |
| D5 | Restructure navigation to 5 destinations with a "More" hub page? | Yes, approve the structural change (implementation deferred — Phase 4) | 10.3–10.4 |
| D6 | Promote a cross-module "today" hero card on Home? | Yes, but only after Calendar's presentation layer exists | 9.3 |
| D7 | Introduce a true 7th "Caption" text style, or keep it a usage convention on `bodySmall`? | Usage convention, no new style | 3.1 |

## 21. Rollout Strategy

See Section 18 in full. Summary: ratify → retrofit two small token gaps (D2, D3) → build remaining 6 modules' presentation layers against this document directly → migrate navigation once Calendar exists → add the dashboard hero card last. No phase touches Finance or Tasks' existing, already-conforming screens.

## 22. Risks

1. **Pattern drift across 6 remaining modules built by different sessions/teams.** Mitigated by Section 18.2's rule that each new module references *this document*, not the previous module, as its pattern source.
2. **Navigation restructuring (D5) is a real, non-trivial refactor** touching `ShellBranches`/`AppRouter`/every existing navigation test — if rushed or combined with a feature milestone, it risks the exact kind of regression Milestone 7's own navigation-test suite was built to catch. Mitigated by sequencing it as its own isolated Phase 4 milestone.
3. **Token proliferation creep.** Every "just this one exception" (a new color, a new spacing value, a new component variant) erodes the calm/consistent goal incrementally rather than all at once, making it hard to notice until the app already feels inconsistent. Mitigated by requiring any new token to be raised and justified explicitly (as D1–D7 are here), never added ad hoc inside a feature PR.
4. **Dark theme is implemented but not yet visually QA'd across all 8 modules' future screens** — the tokens are correct, but real-device contrast/legibility checks (Section 17.1) haven't been run against modules that don't exist yet. Mitigated by making dark-mode QA an explicit checklist item in Section 18.3.

## 23. Final Recommendation Before Implementation

**Approve DOC-033 as the binding visual specification for all remaining Personal OS feature work**, with the seven decisions in Section 20 resolved explicitly (all seven have a stated recommendation above; none require new research, only a yes/no from architecture review). No code should be written against this document until D1–D7 are resolved, since D3, D4, and D7 each affect what a feature team would otherwise build from scratch. D5 (navigation) should be explicitly scheduled as its own milestone — **not** silently folded into Calendar's or Habits' feature work — given its blast radius across `AppRouter`/`ShellBranches`/existing navigation tests.

This document intentionally ratifies more than it changes. The existing `packages/design_system` implementation already reflects strong design discipline; DOC-033's contribution is making that discipline **explicit, numbered, and binding** for the modules not yet built, closing the long-standing gap between the "VPS §" citations already scattered through the codebase and an actual, approved specification they point to.
