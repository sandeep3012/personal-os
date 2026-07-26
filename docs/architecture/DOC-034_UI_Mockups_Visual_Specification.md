# DOC-034 — UI Mockups & Visual Specification

**Version:** 1.0
**Status:** Draft — Requires Design Review
**Category:** User Experience / Visual Specification
**Depends on:** DOC-033 (UI Design System — Approved)
**Format note:** This document is deliberately visual-first. Every screen follows: **Wireframe → Why → Spacing → Typography → Color → Interaction**. No new tokens, rules, or architecture are introduced here — every value cited traces back to DOC-033.

---

## How to Read This Document

Legend used in every wireframe:

```
┌─┐  Card / container edge        ●   Filled dot (selected / active)
│ │  Vertical edge                ○   Outline dot (unselected)
━━━  Section divider (hairline)   ▓▓  Filled progress
─── Thin divider (list rows)      ░░  Empty progress
[ X ]  Button                     ★   Accent / hero emphasis
⌂ 💰 ✓ 📅 ⋯  Icons (illustrative only — real icons per DOC-033 §7)
```

Color shorthand used in annotations: `PRI`=Primary, `SUR`=Surface, `SURV`=Surface Variant, `POS`=Positive/Success, `NEG`=Negative, `WARN`=Warning, `NEU`=Neutral/Info, and module accents `FIN` `TSK` `HAB` `GOAL` `NOTE` `CAL` `AST` `DOC`.

---

# PART A — CORE SCREENS

## 1. Splash

### Purpose
Bridge the cold-start gap while `AppBootstrap.boot()` runs. On screen for under a second on a warm device — must never look like a "loading app," only a calm brand moment.

### Wireframe
```
┌──────────────────────────────────┐
│                                   │
│                                   │
│                                   │
│                                   │
│              ┌────┐               │
│              │ ⌂  │   ← app mark  │
│              └────┘               │
│                                   │
│           Personal OS             │
│                                   │
│                                   │
│                                   │
│                                   │
│                                   │
│                                   │
└──────────────────────────────────┘
```

### Why
One centered mark, one wordmark, nothing else. No spinner — a spinner on a sub-second screen reads as "this app is slow," the opposite of "fast."

### Spacing
Mark + wordmark centered as one group; `AppSpacing.md` (16dp) between mark and wordmark.

### Typography
Wordmark: `headlineSmall`, w600. No body text.

### Color
Background = `SUR` (surface). Mark = `PRI`. No accent colors — Splash predates any module context.

### Interaction
No touch targets. Auto-dismisses into Onboarding (first run) or Dashboard (returning user) the instant boot completes.

---

## 2. Onboarding

### Purpose
First-run only. Three screens: Welcome → Feature overview → Get Started, ending in a choice between "Start Fresh" and "Explore with Demo Mode" (already implemented — DOC-034 specifies its visual finish, not new flow).

### Wireframe — Screen 1: Welcome
```
┌──────────────────────────────────┐
│                            [Skip] │
│                                   │
│                                   │
│              ┌────┐               │
│              │ ⌂  │               │
│              └────┘               │
│                                   │
│         Welcome to                │
│         Personal OS               │
│                                   │
│   One calm place for your money,  │
│   tasks, habits, and time.        │
│                                   │
│                                   │
│                                   │
│         ●  ○  ○                   │
│                                   │
│              [ Next → ]           │
└──────────────────────────────────┘
```

### Wireframe — Screen 2: Feature Overview
```
┌──────────────────────────────────┐
│                            [Skip] │
│                                   │
│     ┌────┐  ┌────┐  ┌────┐        │
│     │ 💰 │  │ ✓  │  │ 📅 │        │
│     └────┘  └────┘  └────┘        │
│    Finance   Tasks   Calendar     │
│                                   │
│   Everything you track, in one    │
│   app that stays out of your way. │
│                                   │
│                                   │
│         ○  ●  ○                   │
│                                   │
│              [ Next → ]           │
└──────────────────────────────────┘
```

### Wireframe — Screen 3: Get Started
```
┌──────────────────────────────────┐
│                                   │
│                                   │
│              ┌────┐               │
│              │ ✓  │               │
│              └────┘               │
│                                   │
│        You're all set             │
│                                   │
│   Start with your own data, or    │
│   explore with sample data first. │
│                                   │
│         ○  ○  ●                   │
│                                   │
│      [   Start Fresh   ]          │
│      [ Explore with Demo Mode ]   │
└──────────────────────────────────┘
```

### Why
Three screens max — long onboarding funnels contradict "fast." Screen 2 shows exactly three modules, not all eight, to avoid overwhelming a first-time user before they've seen the app do anything.

### Spacing
`AppSpacing.xl` (32dp) top padding above the icon on every screen. `AppSpacing.lg` (24dp) between the icon group and the headline. `AppSpacing.md` between headline and body copy. Dot indicator sits `AppSpacing.xl` above the primary button.

### Typography
Headline: `headlineMedium`, w600. Body: `bodyLarge`, `onSurfaceVariant`. Module labels under icons (Screen 2): `labelMedium`.

### Color
Background `SUR`. Icon marks on Screen 2 use their real module accents (`FIN` blue, `TSK` purple, `CAL` red) — the only place in Onboarding a module accent appears, intentionally, as a preview. Primary button = `PRI` filled. "Explore with Demo Mode" = outlined, secondary emphasis — Demo Mode is a helpful option, not the default path.

### Interaction
Swipe or tap **Next** to advance. **Skip** (top-right, screens 1–2 only) jumps straight to Get Started's "Start Fresh." Dot indicator is decorative, not tappable.

---

## 3. Dashboard (Home)

### Purpose
Orientation + "what needs my attention today" — never a full data browser. Answers: where am I, what's the one thing that matters, what's everything else at a glance.

### Wireframe
```
┌──────────────────────────────────┐
│  Good morning, Rohan        🔍 ⚙ │
│                                   │
│  ★ TODAY                          │
│  ┌───────────────────────────┐   │
│  │ 9:30 AM  Team sync         │   │
│  │ 2 tasks due today          │   │
│  │                    [ View →]│   │
│  └───────────────────────────┘   │
│                                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ┌───────────────────────────┐   │
│  │ 💰 Finance                  │   │
│  │ ₹52,450                     │   │
│  │ +₹250 Today            ›   │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ ✓ Tasks                    │   │
│  │ 3 Active   1 Due Today     │   │
│  │                         ›   │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ ↻ Habits                   │   │
│  │ 75%  ████████░░        ›   │   │
│  └───────────────────────────┘   │
│                                   │
│  More modules                     │
│  ┌───────┐┌───────┐┌───────┐     │
│  │ 🚩Goal ││📝Notes ││📦Asset│     │
│  └───────┘└───────┘└───────┘     │
│  ┌───────┐                       │
│  │📁 Docs │                       │
│  └───────┘                       │
│                                   │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
Reading order top-to-bottom matches DOC-033 §1.4: orientation (greeting + search/settings) → the one thing that matters (Today hero card) → uniform module cards → the long tail (More grid). No card competes with the hero card in size.

### Spacing
`AppSpacing.lg` (24dp) between the greeting row, the hero card, the module-card stack, and "More modules." `AppSpacing.md` (16dp) between individual module cards. Screen margin `AppSpacing.md` on all sides.

### Typography
Greeting: `headlineSmall`, w600. "TODAY" eyebrow label: `labelMedium`, `PRI` tone, letter-spaced. Card titles: `titleSmall`, w600. Stat values: `titleLarge`/`headlineSmall` with tabular figures. Supporting line: `bodyMedium`, `onSurfaceVariant`.

### Color
Background `SUR`. Hero card uses a subtle `primaryContainer` tint to visually outrank the module cards without using a second accent color. Each module card's icon sits in a small tinted circle using **its own module accent** (Finance blue, Tasks purple, Habits orange) — the only accent usage on this screen, per DOC-033 §2.4's three-place rule. `+₹250` uses `POS` green; a negative figure would use `NEG` red — never plain text color for a number's sign.

### Interaction
Tap any card → that module's list screen. Tap **🔍** → global search (Part B). Tap **⚙** → Settings. Pull down anywhere → refresh all cards. Cards load independently (skeleton per card, DOC-033 §13) — one slow module never blocks the others.

---

# PART B — FINANCE

## 4.1 Accounts

### Purpose
"Where is my money right now" — the accounts list is Finance's home screen.

### Wireframe
```
┌──────────────────────────────────┐
│  Finance                    🔍 ⋯ │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  Net Worth                        │
│  ₹1,84,200                        │
│                                   │
│  Accounts                         │
│  ┌───────────────────────────┐   │
│  │ 🏦 HDFC Savings             │   │
│  │    ₹52,450                 │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 💳 ICICI Credit Card        │   │
│  │    −₹8,300                 │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 💵 Cash                     │   │
│  │    ₹2,000                  │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
Net Worth sits above the account list as the screen's own "hero number" — mirroring Wallet by BudgetBakers' pattern of one dominant figure before any list. Accounts are cards, not plain rows, so a negative-balance card (credit card) can carry its own visual weight.

### Spacing
`AppSpacing.lg` between Net Worth block and "Accounts" section header. `AppSpacing.md` between account cards (matches `CardThemeData` margin already in `AppThemeBuilder`).

### Typography
Net Worth: `headlineMedium`, tabular figures. Section header "Accounts": `titleMedium`, w600. Account name: `titleSmall`. Balance: `titleMedium`, tabular.

### Color
Positive balances default `onSurface` (not forced green — a balance is not gain/loss, only transactions are, per DOC-033 §2.3 distinguishing `positive` from plain figures). Credit card negative balance uses `NEG` red — it represents money owed. FAB uses `PRI`.

### Interaction
Tap account card → Account Details (4.4). FAB → Add Account (not detailed here; same form pattern as 4.3). `⋯` → sort/filter menu.

---

## 4.2 Transactions

### Purpose
"Where did it go / where is it coming from" — full transaction history, filterable.

### Wireframe
```
┌──────────────────────────────────┐
│  ← Transactions              🔍  │
│  [ All ] [ Income ] [ Expense ]  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  TODAY                            │
│  ┌───────────────────────────┐   │
│  │ 🍽  Lunch                   │   │
│  │    Food · HDFC       −₹250 │   │
│  └───────────────────────────┘   │
│                                   │
│  YESTERDAY                        │
│  ┌───────────────────────────┐   │
│  │ 💼 Salary                   │   │
│  │    Income · HDFC   +₹45,000│   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 🚕 Cab                      │   │
│  │    Transport · Cash  −₹180 │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
Grouped by day (Today / Yesterday / date) not a flat scroll — matches how Wallet by BudgetBakers and most finance apps anchor "when did I spend this," which is how users actually recall transactions.

### Spacing
Filter chip row `AppSpacing.sm` below AppBar. Date-group label `AppSpacing.md` above its first row, `AppSpacing.xs` above subsequent rows within the same group.

### Typography
Date-group label ("TODAY"): `labelMedium`, `onSurfaceVariant`, letter-spaced, all-caps. Transaction title: `bodyLarge`. Category/account subtitle: `bodySmall`, `onSurfaceVariant`. Amount: `titleSmall`, tabular — `POS` green for income, `onSurface` for expense (expenses are the default/expected case, not "bad" — only refunds/overdue would use semantic color).

### Color
Filter chips: selected chip uses `secondaryContainer` fill (theme default), unselected uses outline-only.

### Interaction
Swipe transaction row left → reveals Delete (red) with Undo `Snackbar` — already implemented pattern, ratified here as the model for every list in the app. Tap row → inline edit (opens Add/Edit sheet pre-filled, 4.3). FAB → Add Transaction.

---

## 4.3 Add Transaction

### Purpose
Fast entry — this screen is used dozens of times a week; friction here is the single highest-cost UX mistake Finance could make.

### Wireframe
```
┌──────────────────────────────────┐
│              Add Transaction      │
│  ─────────────────────────────   │
│                                   │
│   [ Expense ]   [ Income ]        │
│                                   │
│   Amount                          │
│   ┌───────────────────────────┐  │
│   │ ₹ 0.00                     │  │
│   └───────────────────────────┘  │
│                                   │
│   Account                         │
│   ┌───────────────────────────┐  │
│   │ HDFC Savings           ▾   │  │
│   └───────────────────────────┘  │
│                                   │
│   Category                        │
│   ┌───────────────────────────┐  │
│   │ Food                   ▾   │  │
│   └───────────────────────────┘  │
│                                   │
│   Note (optional)                 │
│   ┌───────────────────────────┐  │
│   │                            │  │
│   └───────────────────────────┘  │
│                                   │
│   [ Cancel ]      [ Save ]        │
└──────────────────────────────────┘
```

### Why
Presented as a **bottom sheet** (rounded top corners, `AppRadius.large` = 28dp), not a full page — 5 fields, under the "≤5 fields = sheet" threshold set in DOC-033 §11.2. Expense/Income segmented control sits first because it changes the sign of everything below it.

### Spacing
`AppSpacing.lg` between the sheet's title and the segmented control. `AppSpacing.md` between each field group. `AppSpacing.lg` above the Cancel/Save row, separating actions from input.

### Typography
Sheet title: `titleLarge`, w600, centered. Field labels: `labelLarge`. Amount input: `headlineMedium` (deliberately oversized — the number the user is about to commit to is the most important thing in the sheet).

### Color
Expense segmented option (default-selected) has no color coding of its own; Income option, once selected, tints the Amount field's border/label `POS` green. Save button `PRI` filled, disabled (38% opacity, per DOC-033 §17.2) until Amount > 0.

### Interaction
Amount field auto-focuses on open with number keypad. Account/Category are dropdown sheets-within-a-sheet (standard Material). Save closes the sheet with a brief `Snackbar` confirmation ("Transaction added"). Swipe-down or tap outside dismisses without saving (with a discard confirmation only if fields are non-empty).

---

## 4.4 Account Details

### Purpose
Drill-down from Accounts — this account's balance trend and its own transaction history, scoped.

### Wireframe
```
┌──────────────────────────────────┐
│  ← HDFC Savings              ⋯   │
│  ─────────────────────────────   │
│                                   │
│         ₹52,450                   │
│      Current Balance              │
│                                   │
│   ╭─────────────────────────╮    │
│   │     ╱╲    ╱╲              │    │
│   │    ╱  ╲__╱  ╲___╱╲__      │    │
│   ╰─────────────────────────╯    │
│   Jan   Feb   Mar   Apr           │
│                                   │
│  Recent Activity                  │
│  ┌───────────────────────────┐   │
│  │ 🍽 Lunch            −₹250  │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 💼 Salary        +₹45,000  │   │
│  └───────────────────────────┘   │
│                                   │
│              [ See all → ]        │
└──────────────────────────────────┘
```

### Why
Follows the Detail Page pattern from DOC-033 §11.3: hero figure first (`headlineMedium`, the balance), then a supporting visual (trend chart), then a short, capped activity list with a link to the full filtered Transactions view — never an unbounded list on a detail screen.

### Spacing
`AppSpacing.xl` above/below the hero balance block (this is the screen's single most important number, given room to breathe). `AppSpacing.lg` between the chart and "Recent Activity."

### Typography
Balance: `headlineMedium`, tabular. "Current Balance" caption: `bodySmall`, `onSurfaceVariant`. Chart axis labels: `labelSmall`.

### Color
Chart line uses `PRI`, not a module accent — this is a single-account view, not a Finance-module-identity moment (module accent already spent on the AppBar/back-context per DOC-033 §2.4's "three places" rule).

### Interaction
`⋯` → Edit account / Archive account. "See all →" → Transactions (4.2), pre-filtered to this account.

---

# PART C — TASKS

## 5.1 List

### Wireframe
```
┌──────────────────────────────────┐
│  Tasks                       🔍  │
│  [ All ] [ Today ] [ Upcoming ]  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ┌───────────────────────────┐   │
│  │ ○  Finish Q3 report         │   │
│  │    Due today                │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ ○  Call the bank            │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ ●  Buy groceries    (done)  │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Purpose → Why
The daily-use screen. Checkbox-first row layout (not a swipe-only affordance) because completing a task is Tasks' single most frequent action and deserves a one-tap, always-visible control — this is already `TaskTile`'s existing shape, ratified.

### Spacing
`AppSpacing.sm` between filter chips and the divider. `AppSpacing.xs` vertical rhythm between task rows (dense, since tasks are scanned quickly, not read like Finance's transaction list).

### Typography
Task title: `bodyLarge`; strikethrough + `onSurfaceVariant` tone once complete (not color alone — text decoration is the primary signal, color is secondary, per DOC-033 §1.1). "Due today" subtitle: `bodySmall`, `WARN` tone only if overdue, otherwise `onSurfaceVariant`.

### Color
Checkbox uses `TSK` (Tasks purple) when checked — the one place a module accent legitimately appears inside its own list, matching DOC-033 §2.4's "module's own screens" allowance.

### Interaction
Tap checkbox → complete (with a brief `success` color flash + `AppMotion.fast` scale, no `celebration` motion — that's reserved for Goals/Habits milestones only). Tap row body → Task Details (5.2). Swipe → Delete (with Undo). FAB → Add Task (5.3).

---

## 5.2 Details

### Wireframe
```
┌──────────────────────────────────┐
│  ← Task                     ⋯    │
│  ─────────────────────────────   │
│                                   │
│  ○  Finish Q3 report               │
│                                   │
│  Due          Today, 6:00 PM      │
│  Status       In Progress         │
│                                   │
│  Notes                            │
│  ┌───────────────────────────┐   │
│  │ Include the Finance module │  │
│  │ metrics section.            │  │
│  └───────────────────────────┘   │
│                                   │
│  [ Mark Complete ]                │
│  [ Archive ]                      │
└──────────────────────────────────┘
```

### Purpose → Why
Same Detail Page pattern as Finance's Account Details (hero item first, metadata grouped below) — one shared shape across modules, not a Tasks-specific layout.

### Spacing
`AppSpacing.lg` between the title row and the metadata rows. `AppSpacing.md` between each metadata row (Due/Status pair reads as a definition list).

### Typography
Task title: `titleLarge`, w600 — larger than in the list, since this is now the screen's sole subject. Metadata labels: `labelLarge`, `onSurfaceVariant`; values: `bodyLarge`.

### Color
"In Progress" status uses `NEU` (neutral/info blue); "Complete" would use `success` green; "Archived" uses `onSurfaceVariant` (deliberately desaturated — archived is a terminal, unremarkable state, per the Tasks domain's own no-reopening rule).

### Interaction
"Mark Complete" only shown when status permits (per Tasks' domain transition rules — never shown on an already-archived task). "Archive" is a secondary/outlined action, never same-weight as Complete.

---

## 5.3 Add / Edit

### Wireframe
```
┌──────────────────────────────────┐
│              Add Task             │
│  ─────────────────────────────   │
│                                   │
│   Title                           │
│   ┌───────────────────────────┐  │
│   │                            │  │
│   └───────────────────────────┘  │
│                                   │
│   Due date (optional)             │
│   ┌───────────────────────────┐  │
│   │ 📅  Select date        ▾   │  │
│   └───────────────────────────┘  │
│                                   │
│   Description (optional)          │
│   ┌───────────────────────────┐  │
│   │                            │  │
│   └───────────────────────────┘  │
│                                   │
│   [ Cancel ]      [ Save ]        │
└──────────────────────────────────┘
```

### Purpose → Why
Bottom sheet, 3 fields — well under the 5-field sheet threshold. Title auto-focused; everything else optional, since the fastest possible "just capture the thought" flow matters more for Tasks than for Finance (a task can be refined later, an amount cannot).

### Spacing / Typography / Color
Identical field rhythm to Add Transaction (4.3) — `AppSpacing.md` between fields, `labelLarge` labels — intentionally, so the "add something" motion feels the same across every module.

### Interaction
Save is enabled as soon as Title is non-empty (everything else optional) — the lowest-friction Save-button gate in the app.

---

# PART D — HABITS

### Purpose
Daily-check-in and streak visibility — modeled on Apple Health's ring language, adapted to a list rather than a full-screen ring dashboard.

### Wireframe
```
┌──────────────────────────────────┐
│  Habits                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  This Week                        │
│  M  T  W  T  F  S  S              │
│  ●  ●  ●  ○  ○  ○  ○              │
│                                   │
│  ┌───────────────────────────┐   │
│  │ 💧 Drink water               │   │
│  │    ●●●●●○○   5/7 today      │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 🏃 Morning run               │   │
│  │    🔥 12-day streak          │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 📖 Read 20 min               │   │
│  │    ○ Not done today          │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
The week strip at the top answers "how am I doing overall" in one glance before any per-habit detail — same "hero-first" reading order as every other module.

### Spacing
`AppSpacing.lg` between the week strip and the habit card list. `AppSpacing.md` between habit cards.

### Typography
Habit name: `titleSmall`. Streak/progress line: `bodySmall`, `onSurfaceVariant`, except the flame streak count which uses `WARN` amber tone to read as "hot streak, don't break it."

### Color
Filled week-strip dots use `HAB` (Habits orange). Progress dots on each card use `success` green once a habit's daily target is met, `outline` grey otherwise — never the module accent for individual progress dots (accent is reserved for the week-strip/identity level, per DOC-033 §2.4).

### Interaction
Tap a card's progress row → mark today's check-in (single tap, no confirmation — habits should be frictionless). Long-press or `⋯` → edit habit. FAB → new habit.

---

# PART E — GOALS

### Purpose
Longer-horizon progress tracking — deliberately calmer and less frequent-use than Tasks/Habits, so its card language uses fuller progress bars rather than daily dot streaks.

### Wireframe
```
┌──────────────────────────────────┐
│  Goals                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ┌───────────────────────────┐   │
│  │ 🚩 Save ₹1,00,000            │   │
│  │    ₹62,000 of ₹1,00,000     │   │
│  │    ██████████░░░░░  62%    │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 🚩 Run a 10K                 │   │
│  │    ████████████████  100%  │   │
│  │    ✓ Achieved               │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
Each `GoalCard` shows exactly one progress bar + one percentage — no secondary chart, no dense metadata. Goals are checked in on rarely; the card must communicate status in under a second.

### Spacing
`AppSpacing.md` between the progress-figure line and the bar itself. `AppSpacing.md` between goal cards.

### Typography
Goal title: `titleSmall`, w600. Progress figures: `bodyMedium`, tabular. Percentage: `labelLarge`, right-aligned to the bar.

### Color
Progress bar fill uses `GOAL` (teal) while in progress, switches to `success` green once 100% — the one card state in the app where a module accent and a semantic color intentionally hand off from one to the other, marking "this is no longer a goal in progress, it's an achievement."

### Interaction
Tap card → Goal detail (mirrors Task Details' pattern — hero progress, metadata, milestones list). Reaching 100% triggers the one `celebration` (600ms) motion moment permitted by DOC-033 §15 — a brief, single confetti-free scale/glow pulse on the card, never a full-screen takeover.

---

# PART F — NOTES

### Purpose
Fast capture and scanning — modeled closest on Notion Mobile's card-grid density.

### Wireframe
```
┌──────────────────────────────────┐
│  Notes                      🔍   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ┌───────────┐ ┌───────────┐     │
│  │ Meeting     │ │ Recipe:    │     │
│  │ notes       │ │ Pasta      │     │
│  │ Discussed…  │ │ Boil water │     │
│  │ 2h ago      │ │ 3d ago     │     │
│  └───────────┘ └───────────┘     │
│  ┌───────────┐ ┌───────────┐     │
│  │ Gift ideas  │ │ Book list  │     │
│  │ Mom: scarf  │ │ Atomic     │     │
│  │ 1w ago      │ │ Habits     │     │
│  └───────────┘ └───────────┘     │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
Two-column grid, not a single-column list — Notes are scanned visually (like a corkboard), not read sequentially like Transactions. This is the one module screen that departs from the single-column list default, and it's justified because Notion Mobile/Google Keep both converge on the same grid for the same content type.

### Spacing
`AppSpacing.sm` gutter between grid columns/rows — tighter than the `md` rhythm used elsewhere, since these are compact preview cards, not full-width list rows.

### Typography
Note title: `titleSmall`, w600. Preview snippet: `bodySmall`, `onSurfaceVariant`, 2-line clamp. Timestamp: `labelSmall`, `onSurfaceVariant`.

### Color
No accent tint on note cards by default — `surfaceContainerLow` like every other card. If/when user-assigned note colors ship (future), they'd appear as a thin top edge stripe, not a full card background, to preserve reading contrast.

### Interaction
Tap card → full note editor (full-screen, not a sheet — free-text content has no field-count ceiling). FAB → new blank note.

---

# PART G — CALENDAR

### Purpose
Time-anchored planning — Calendar's own home screen, and the reason DOC-033 §10.3 promotes it to a top-level nav destination.

### Wireframe
```
┌──────────────────────────────────┐
│  April 2026                  🔍  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  M   T   W   T   F   S   S        │
│  1   2   3   4   5   6   7        │
│  8   9  10  11  12  13  14        │
│ 15  16 (17) 18  19  20  21        │
│ 22  23  24  25  26  27  28        │
│ 29  30                            │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  Thu, 17 April                    │
│  ┌───────────────────────────┐   │
│  │ 9:30 AM   Team sync         │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 1:00 PM   Lunch with Priya  │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
Month grid on top, selected-day agenda below — matches Google Calendar's own default mobile view exactly, which is the explicit reference for this module. Today's date circled by default on open.

### Spacing
`AppSpacing.md` between the month grid and the divider. `AppSpacing.sm` between agenda event cards (denser than Finance's transaction rhythm — a day can have many short events).

### Typography
Month/year header: `titleLarge`, w600. Weekday initials: `labelSmall`, `onSurfaceVariant`. Selected-day label ("Thu, 17 April"): `titleMedium`. Event time: `labelLarge`, tabular; event title: `bodyLarge`.

### Color
Today's date: outlined circle in `CAL` (Calendar red). Selected date (if different from today): filled circle in `PRI`. Event cards carry a thin left-border in `CAL` — the module's one "own screen" accent touch, per DOC-033 §2.4.

### Interaction
Tap a date → agenda below updates (no page transition, `AppMotion.standard` cross-fade). Swipe left/right on month grid → previous/next month. FAB → new event.

---

# PART H — ASSETS

### Purpose
"What do I own" — a lighter-weight cousin of Finance's Accounts, tracking non-liquid value (property, vehicles, valuables) rather than cash flow.

### Wireframe
```
┌──────────────────────────────────┐
│  Assets                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  Total Value                      │
│  ₹28,50,000                       │
│                                   │
│  ┌───────────────────────────┐   │
│  │ 🚗 Honda City                │   │
│  │    ₹8,50,000                │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 🏠 Apartment                 │   │
│  │    ₹20,00,000                │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
Deliberately mirrors Accounts (4.1)'s "hero total + card list" shape exactly — Assets and Accounts are the same mental model (things of value I own/hold), so their screens should look like siblings, reinforcing "one app," not "eight apps."

### Spacing / Typography
Identical rhythm to Accounts (4.1): `AppSpacing.lg` below the hero total, `titleSmall` names, `titleMedium` tabular values.

### Color
Asset icon backgrounds use `AST` (Assets indigo) — same "module identity" placement as every module card.

### Interaction
Tap card → asset detail (same Detail Page shape as Account Details, showing value history if tracked). FAB → add asset.

---

# PART I — DOCUMENTS

### Purpose
File/document reference storage — the one module whose primary content is a file, not structured data.

### Wireframe
```
┌──────────────────────────────────┐
│  Documents                   🔍  │
│  [ All ] [ PDF ] [ Images ]      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ┌───────────────────────────┐   │
│  │ 📄  Rental Agreement.pdf     │   │
│  │     2.1 MB · 3 Mar 2026     │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ 🖼  Insurance Card.jpg       │   │
│  │     840 KB · 1 Feb 2026     │   │
│  └───────────────────────────┘   │
│                                   │
│                              [+]  │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
File-type icon + filename + size/date metadata — the same three-piece row shape as every list module, just with file metadata instead of a monetary/status value on the right, keeping `DocumentTile` visually part of the same tile family (per DOC-033 §11.1: "never a raw ListTile").

### Spacing / Typography
Same list rhythm as Notes/Assets. Filename: `bodyLarge`. Size/date: `bodySmall`, `onSurfaceVariant`.

### Color
File-type icon tinted `DOC` (Documents brown) circle background — identical treatment to every other module's list icon.

### Interaction
Tap row → preview (native file viewer / in-app preview depending on type). FAB → upload/attach new document.

---

# PART J — MORE

### Purpose
The navigation hub for every module that isn't in the 5-item bottom bar (DOC-033 §10.3–10.4) — Habits, Goals, Notes, Assets, Documents, plus Settings.

### Wireframe
```
┌──────────────────────────────────┐
│  More                            │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ┌───────┐ ┌───────┐ ┌───────┐   │
│  │  ↻     │ │  🚩    │ │  📝    │   │
│  │ Habits │ │ Goals  │ │ Notes  │   │
│  └───────┘ └───────┘ └───────┘   │
│  ┌───────┐ ┌───────┐             │
│  │  📦    │ │  📁    │             │
│  │ Assets │ │ Docs   │             │
│  └───────┘ └───────┘             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ┌───────────────────────────┐   │
│  │ ⚙  Settings              › │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ ●  Demo Mode: Off        › │   │
│  └───────────────────────────┘   │
│                                   │
│  ⌂    💰    ✓    📅    ⋯          │
└──────────────────────────────────┘
```

### Why
A grid of `ModuleCard`-family tiles (icon + label, same shape as Onboarding Screen 2's preview icons) — not a plain settings-style list — because these are still full content modules, not configuration options, and deserve the same visual weight as Finance/Tasks/Calendar got in the bottom bar. Settings/Demo Mode sit below a divider as the one genuinely "configuration, not content" section of this page.

### Spacing
`AppSpacing.md` grid gutter, 3 columns on Compact width (matches Dashboard's "More modules" preview grid — same component, full list here instead of a 4-item teaser).

### Typography
Module label under each icon: `labelLarge`. "Settings"/"Demo Mode" rows: `bodyLarge`.

### Color
Each grid icon uses its own module accent — this page is, along with Dashboard, one of the two places all 8 module accents legitimately appear together on one screen.

### Interaction
Tap any module tile → that module's list screen (same navigation result as if it had its own bottom-nav tab — "More" is a router, not a dead end). Tap Settings → Settings screen (Part L).

---

# PART K — SETTINGS

### Purpose
Configuration, account, and Demo Mode management.

### Wireframe
```
┌──────────────────────────────────┐
│  ← Settings                      │
│  ─────────────────────────────   │
│  APPEARANCE                       │
│  ┌───────────────────────────┐   │
│  │ Theme          System   ▾ │   │
│  └───────────────────────────┘   │
│                                   │
│  DEMO MODE                        │
│  ┌───────────────────────────┐   │
│  │ Demo Mode           ○ Off  │   │
│  │ See sample data without    │   │
│  │ affecting your real data.  │   │
│  └───────────────────────────┘   │
│  [ Reset Demo Data ]              │
│                                   │
│  ABOUT                            │
│  ┌───────────────────────────┐   │
│  │ Version              0.6.0 │   │
│  └───────────────────────────┘   │
└──────────────────────────────────┘
```

### Why
Grouped sections with all-caps eyebrow labels (APPEARANCE / DEMO MODE / ABOUT) — a denser layout than content screens is explicitly permitted here per DOC-033 §1.3 ("Settings is allowed to be denser... but still token-driven").

### Spacing
`AppSpacing.lg` between section groups. `AppSpacing.sm` between the section label and its first row.

### Typography
Section labels: `labelMedium`, `onSurfaceVariant`, all-caps, letter-spaced. Row labels: `bodyLarge`. Helper text under Demo Mode toggle: `bodySmall`, `onSurfaceVariant`.

### Color
Demo Mode toggle uses standard `Switch` theming (`PRI` when on). "Reset Demo Data" is a `TextButton` in `NEG`-adjacent tone only when Demo Mode is active (it's a destructive-ish action on demo data specifically) — disabled/hidden when Demo Mode is off.

### Interaction
Toggling Demo Mode on triggers a full shell remount (existing `generation`-keyed behavior) with a brief `Snackbar`: "Demo Mode enabled." "Reset Demo Data" opens a Confirmation Dialog (Part N) before acting.

---

# PART L — NAVIGATION

## Bottom Navigation (5 destinations, per DOC-033 §10.3)

### Wireframe — Compact width (phone)
```
┌──────────────────────────────────┐
│                                   │
│         (screen content)          │
│                                   │
├──────────────────────────────────┤
│  ⌂      💰      ✓      📅      ⋯  │
│ Home  Finance  Tasks  Calendar More│
│  ●                                │
└──────────────────────────────────┘
```

### Wireframe — Expanded width (tablet/desktop rail)
```
┌───┬──────────────────────────────┐
│ ⌂ │                              │
│Home│                              │
│───│                              │
│ 💰 │       (screen content)        │
│Fin.│                              │
│───│                              │
│ ✓ │                              │
│Task│                              │
│───│                              │
│ 📅 │                              │
│Cal.│                              │
│───│                              │
│ ⋯ │                              │
│More│                              │
└───┴──────────────────────────────┘
```

### Why
Exactly 5 items, matching DOC-033 §10.3's approved recommendation — Home for orientation, Finance + Tasks as the two highest-frequency modules, Calendar as the third daily-use peer, More as the hub for everything else. Rail at Expanded width is the same 5 items, just laid out vertically (already existing `AppBreakpoints`-driven behavior, unchanged shape here).

### Spacing
Standard Material `NavigationBar` height (80dp) / `NavigationRail` width — token-governed via `AppElevation.navigationBar`, no custom sizing.

### Typography
Nav labels: `labelMedium`. Selected item's label may bump to w600 (Material default "selected label emphasis") — no separate token needed.

### Color
Selected item: icon filled + `secondaryContainer` pill indicator (existing `NavigationBarThemeData`). Unselected: outlined icon, `onSurfaceVariant`. **No module accent color appears in the nav bar** — deliberately neutral chrome, so accent colors stay meaningful signals inside each module rather than becoming wallpaper.

### Interaction
Tap → switch branch (state preserved per `StatefulShellRoute.indexedStack`, already implemented). Tapping the already-active tab scrolls that screen to top (standard convention, recommended addition).

---

## Search (Global)

### Wireframe
```
┌──────────────────────────────────┐
│  ←  🔍 Search everything          │
│  ─────────────────────────────   │
│                                   │
│  RECENT                           │
│  Lunch                            │
│  Team sync                        │
│                                   │
│  RESULTS                          │
│  ┌───────────────────────────┐   │
│  │ 💰 Lunch          −₹250     │   │
│  │    Transaction              │   │
│  └───────────────────────────┘   │
│  ┌───────────────────────────┐   │
│  │ ✓ Lunch with client         │   │
│  │    Task                     │   │
│  └───────────────────────────┘   │
└──────────────────────────────────┘
```

### Why
One search surface across every module (matches the platform's cross-cutting Search capability) — results show a small module icon + type label so cross-module results never look ambiguous about where they'll navigate.

### Spacing/Typography
`AppSpacing.md` grouping. "RECENT"/"RESULTS" as `labelMedium` eyebrow labels, matching Settings' section-label treatment for consistency.

### Color
Each result row's leading icon uses its source module's accent — search is the one place mixed accents in a single list is correct, since it's explicitly cross-module.

### Interaction
Opens full-screen (not a sheet — search needs full keyboard + results real estate). Tapping a result navigates directly into that module's detail screen.

---

# PART M — CARDS, LISTS, SECTION HEADERS

## Generic Card
```
┌──────────────────────────┐
│  Finance                   │
│  ₹52,400                   │
│  +₹400 Today                │
└──────────────────────────┘
```
`surfaceContainerLow` fill, `AppRadius.card` (16dp) corners, no shadow (flat, tonal — DOC-033 §6).

## Section Header
```
Recent Activity                 See all →
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
`titleMedium` label, optional trailing text-link action, hairline divider using `outlineVariant` beneath.

## List Item (standard row)
```
┌───────────────────────────┐
│ 🍽  Lunch                    │
│     Food · HDFC      −₹250 │
└───────────────────────────┘
```
Leading icon in tinted circle, title + subtitle stack, trailing value right-aligned — the one shape every tile family (`AccountTile`, `TaskTile`, `HabitTile`, etc.) shares.

---

# PART N — DIALOGS, SHEETS, SNACKBARS

## Confirmation Dialog
```
┌────────────────────────────┐
│  Delete Transaction?        │
│                              │
│  This can't be undone.      │
│                              │
│         [Cancel]  [Delete]  │
└────────────────────────────┘
```
`AppRadius.large` corners, `surfaceContainerHigh` fill, `AppElevation.dialog` (3). Destructive action (`Delete`) rendered in `NEG` red text, Cancel neutral — destructive action is never the pre-focused default.

## Bottom Sheet (generic)
```
┌────────────────────────────┐
│         ▬▬▬  (drag handle)  │
│  Sheet Title                 │
│  ─────────────────────────  │
│  (form fields / content)     │
└────────────────────────────┘
```
Rounded top corners only (`AppRadius.large`), drag handle centered `AppSpacing.sm` from the top edge.

## Snackbar
```
┌────────────────────────────┐
│  Transaction deleted   [Undo]│
└────────────────────────────┘
```
`inverseSurface` background (already themed), floats `AppSpacing.md` above the bottom nav, auto-dismisses after ~4s, `Undo` in `inversePrimary`.

---

# PART O — FAB, CHIPS, PROGRESS

## FAB
```
        ╭───╮
        │ + │
        ╰───╯
```
Bottom-right, `AppElevation.fab` (3), `PRI` fill. One per screen, never two competing FABs.

## Filter Chips
```
[ ● All ]  [ Income ]  [ Expense ]
```
Selected chip: `secondaryContainer` fill. Unselected: outline only, transparent fill.

## Progress — Linear (Habits/Goals)
```
████████░░  75%
```
## Progress — Ring (future Apple-Health-style summary)
```
   ╭───╮
  │ 75% │
   ╰───╯
```
Both variants already implemented (`ProportionBar`, `ProgressRing`) — filled portion uses the relevant semantic/module color; track uses `outlineVariant`.

## Statistics Row (Dashboard-style)
```
₹52,450
+₹250 Today
```
Value at `titleLarge`/`headlineSmall`, delta line at `bodySmall` with `POS`/`NEG` tone — the shared shape for every `StatCard` in the app.

---

# PART P — EMPTY / LOADING / ERROR STATES

## Empty State (universal pattern)
```
           📄

      No Notes Yet

  Create your first note

      [ New Note ]
```
Icon at `AppIconSizes.empty` (48dp) in `onSurfaceVariant` tone (never the module accent — an empty state is not an alert). Title `titleMedium`, supporting line `bodyMedium`, one optional action button.

## Loading State — Skeleton (lists)
```
┌───────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓▓▓▓               │
│  ▓▓▓▓▓▓                     │
└───────────────────────────┘
┌───────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓                  │
│  ▓▓▓▓                       │
└───────────────────────────┘
```
Shimmer-toned card shapes previewing the content about to appear — used for every list/grid first load.

## Loading State — Spinner (compact contexts)
```
┌──────────────────────────┐
│  Finance                   │
│        ⟳                    │
└──────────────────────────┘
```
Used only inside a `ModuleCard`'s compact slot or an in-flight form submit — never for a full list (DOC-033 §13).

## Error State (universal pattern)
```
           ⚠

    Couldn't load Finance

  Check your connection and
       try again.

        [ Retry ]
```
Same layout skeleton as Empty State (icon → title → supporting line → button) so the two never look like unrelated screens — only the icon/copy/action differ, per DOC-033 §14.

---

# PART Q — CHARTS

## Line Chart (Account balance trend)
```
╭─────────────────────────╮
│     ╱╲    ╱╲              │
│    ╱  ╲__╱  ╲___╱╲__      │
╰─────────────────────────╯
 Jan   Feb   Mar   Apr
```
Single `PRI`-colored line, no gridlines (calm over precise) — axis labels only, `labelSmall`.

## Bar Chart (Spend by category — future Finance report screen)
```
Food      ████████████  ₹4,200
Transport ██████         ₹1,800
Bills     ████████████████ ₹6,500
```
One bar per category, category's own tag color if user-assigned, otherwise `secondary` tone — no more than 6 categories shown before collapsing into "Other."

---

# FINAL SECTION

## 1. Overall Design Language

Personal OS reads as **one calm surface with eight rooms**, not eight apps sharing a login screen. Every screen is built from the same seven shapes — hero figure, card, list row, section header, sheet, dialog, empty/loading/error triad — with only icon, accent color, and copy changing per module. Nothing in this document introduces a ninth shape. The visual mood is closest to **Notion Mobile's restraint + Apple Health's single-hero-number confidence + Google Calendar's grid clarity** — deliberately avoiding Wallet by BudgetBakers' denser chart-heavy screens except where Finance specifically needs them (trend chart, category bars).

## 2. UI Consistency Rules

1. Every list screen: AppBar → optional filter row → `AppStateSwitcher`-wrapped content → one FAB.
2. Every card: `surfaceContainerLow`, `AppRadius.card`, no shadow, `AppSpacing.md` internal padding.
3. Every module accent appears in at most three places per screen: nav/icon, card icon background, thin identity accent inside its own module — never as a full background or primary-button color.
4. Every create/edit flow with ≤5 fields is a bottom sheet; more than 5 fields is a full page.
5. Every destructive action is confirmed via the same Confirmation Dialog shape, red-text on the destructive option only.
6. Every empty/error state shares one skeleton: icon → title → one line → one button.
7. Motion is explanatory only; `celebration` (600ms) is reserved for Goals-reached / Habit-streak-milestone moments — nowhere else.

## 3. Screen Flow

```
Splash
  └─▶ Onboarding (first run only) ──▶ Dashboard
  └─▶ Dashboard (returning user)

Dashboard ──▶ [Finance | Tasks | Calendar] (bottom nav)
Dashboard ──▶ More ──▶ [Habits | Goals | Notes | Assets | Documents | Settings]

Finance:  Accounts ⇄ Account Details
          Accounts ──▶ Transactions ──▶ Add/Edit Transaction (sheet)

Tasks:    List ⇄ Details
          List ──▶ Add/Edit Task (sheet)

Calendar: Month + Agenda ──▶ Add Event (sheet)

Habits/Goals/Notes/Assets/Documents: List ⇄ Detail, each with its own Add flow

Any screen ──▶ Search (global) ──▶ any module's Detail screen
Any screen ──▶ Settings (via More)
```

## 4. Recommended Implementation Order

1. **Navigation restructure** (Home/Finance/Tasks/Calendar/More) — foundational; every other screen's entry point depends on it (per DOC-033 §10.5, its own milestone).
2. **Calendar** — needed both as a nav destination and as an input to the future Dashboard hero card.
3. **Habits, Goals** — daily/near-daily use, highest user-facing value after Calendar.
4. **Notes, Assets, Documents** — lower-frequency, can ship inside the "More" hub without navigation risk.
5. **Dashboard hero card + global Search** — cross-module features, sequenced last since they depend on every module above already existing.
6. **Settings/Demo Mode polish** — lowest risk, can happen in parallel with any phase above.

## 5. Potential UX Improvements Before v1.0

- **Quick-add from anywhere**: a single "+" affordance reachable from Dashboard that offers "Add Transaction / Add Task / Add Event" without navigating into that module first — reduces the "which tab do I need" decision for fast capture.
- **Dashboard hero card personalization**: once Calendar + Tasks are both live, let the hero card's content adapt (e.g. show the next Finance bill due if nothing else is time-sensitive today) rather than always defaulting to agenda-only.
- **Notes ↔ Tasks linking**: Notion Mobile's biggest strength is cross-referencing; a lightweight "mention a task in a note" affordance would differentiate Personal OS from single-purpose competitors — flagged as a *future* cross-module feature, not v1.0 scope.
- **Habits weekly summary notification**: a calm, once-a-week digest (not daily nagging) matching Apple Health's "weekly summary" tone rather than push-heavy competitors.
- **Search result ranking by recency + frequency**, not just text match — most "search everything" apps under-invest here and it's a cheap, high-value differentiator once Search ships.

---

**This document defines visuals only. No Flutter code, widget, or Design System file was created or modified in producing it.**
