# Overnight Development Report — Habits Feature

## Executive Summary

Implemented a complete new **Habits** feature for Personal OS, following the frozen
architecture exactly: Tasks' presentation/ViewModel/wiring/navigation/home/demo-mode
patterns, and Finance's domain/data/SQLite/repository/DAO/mapper/migration patterns.
The feature supports creating, updating, completing (logging a completion and advancing
a streak), archiving, and soft-deleting habits, and is fully wired into the app's
navigation shell, Home Dashboard, dependency injection, and Demo Mode.

**Important limitation of this session:** the sandbox this task ran in has no Flutter/Dart
SDK installed (`flutter`, `dart` are not on `PATH`, and no SDK directory exists anywhere
on the filesystem). `flutter analyze` and `flutter test` could not be executed at any
point, despite being required by the workflow. All code was therefore written and
cross-checked by hand (careful reading of every reference file, consistent
find/grep sweeps for stale identifiers after every rename, and manual review of every
generated file) rather than compiler-verified. This is flagged explicitly rather than
fabricating analyze/test output — see "Test Results" and "Recommendations" below for
exactly what must be run before this branch is trusted.

## Timeline (single continuous session)

1. Read `features/tasks` and `features/finance` in full (domain, data, application, DI,
   presentation, tests) plus `apps/mobile` wiring points (`app_bootstrap.dart`,
   `app.dart`, `demo_mode_controller.dart`, `home_dashboard_page.dart`,
   `shell_branches.dart`, `app_router.dart`).
2. Generated `features/habits` as a structural clone of `features/tasks` (file-for-file,
   identifier-for-identifier), then hand-rewrote every file whose fields actually differ
   for the Habit domain (entity, value objects, mapper, row, schema, use cases,
   ViewModels, page, tests).
3. Implemented domain, data, application, DI, and presentation layers in that order,
   committing after each layer.
4. Wired the app layer (storage module, switchable executor/runner pair, demo seed data,
   bootstrap registration, shell branch, router, Home Dashboard module card) and updated
   every `apps/mobile` test that constructs `DemoModeController`, `HomeDashboardPage`,
   or `AppRouter.create` for the new required Habits parameters.
5. Manually swept the whole `features/habits` and `apps/mobile` trees for stale
   Tasks-shaped identifiers (`title`, `dueDate`, `HabitStatus.todo`, etc.) after every
   rewrite pass.
6. Wrote this report.

## Commits

| Hash | Message | Purpose |
|---|---|---|
| `83ff1cd` | `feat(habits): implement domain layer` | `Habit` entity, `HabitId`/`HabitFrequency`/`HabitStatus`/`HabitQuery`/`HabitPage` value objects, `HabitsException`, domain events, `IHabitRepository` |
| `d7c6f37` | `feat(habits): implement data layer` | `HabitDao`, `HabitMapper`, `HabitRow`, `HabitQueryFilter`, `HabitsSchema`, `CreateHabitsTableMigration`, `HabitRepository`, in-memory + file-backed executor/transaction-runner pair |
| `af59abf` | `feat(habits): implement application layer` | `CreateHabitUseCase`, `UpdateHabitUseCase`, `CompleteHabitUseCase`, `ArchiveHabitUseCase`, `DeleteHabitUseCase`, `GetHabitUseCase`, `GetHabitsUseCase`, `SearchHabitsUseCase` |
| `7d3cc64` | `feat(habits): wire dependency injection` | `HabitsModule` (persistence/use-case/ViewModel registration, route registration) |
| `0f14df6` | `feat(habits): implement presentation` | `HabitsViewModel`, `HabitsHomeViewModel`, `HabitsPage`, `HabitsRoutes` |
| `758cef4` | `feat(habits): integrate navigation, DI, home dashboard, demo mode` | `HabitsStorageModule`, `SwitchableHabitDatabaseExecutor`/`Runner`, `DemoHabitSeedData`, `DemoModeController` extended to a third pair, `AppBootstrap` registration, new shell branch/destination, Home Dashboard `ModuleCard`, updated `apps/mobile` tests |

(A final `docs:` commit for this report follows.)

## Feature: Habits

### Objective
Add a Habits feature with the same architectural rigor as Tasks/Finance: create habits,
log completions, track streaks, archive, and delete — surfaced in the shell, Home
Dashboard, and Demo Mode identically to how Tasks is surfaced.

### Architecture reused
- **Presentation/ViewModel/wiring/navigation/home/demo-mode**: copied Tasks' structure
  exactly — `AsyncState`-driven ViewModels with constructor-injected use cases,
  `WorkspaceContext` listener registered in the constructor and unregistered in
  `dispose()`, a `HabitsPage` built entirely from `design_system` components, a
  `HabitsRoutes` constant, a `HabitsModule` registering routes + services, an
  app-layer `HabitsStorageModule` + switchable executor/runner pair, and a
  `DemoHabitSeedData` seeded the same way `DemoTaskSeedData` is.
- **Domain/data/SQLite/repository/DAO/mapper/migration**: copied Finance's DAO/Mapper/
  Migration/Transaction/Repository split exactly — `HabitDao` (raw SQL only, no
  domain types), `HabitMapper` (pure `Habit` ⇄ `HabitRow` conversion, throws
  `HabitsException` on unrecognized enum values), `CreateHabitsTableMigration`
  (schema-as-code, same as Finance/Tasks — not yet wired to a real migration runner),
  `HabitRepository` (orchestration only, translates all failures to `HabitsException`).

### Domain model
- `Habit` entity: `id`, `workspaceId`, `name`, `frequency` (`HabitFrequency.daily` /
  `.weekly`), `status` (`HabitStatus.active` / `.archived`, two-state — simpler than
  Tasks' four-state workflow since a habit has no "in progress"/"done" concept), plus
  `currentStreak`, `longestStreak`, `completionLog` (`List<DateTime>`, date-only), and
  `lastCompletedAt`.
- Business rules on the entity (not in use cases or ViewModels):
  - `name` must be non-empty and ≤ 200 characters (constructor invariant, mirrors Task's
    title).
  - `transitionTo` enforces `active → archived` as the only legal transition (archived is
    terminal).
  - `recordCompletion(date, {now})` is the streak engine: rejects a second completion on
    the same calendar day; rejects completion on an archived habit; continues the streak
    (`currentStreak + 1`) if the gap since the last completion is within
    `HabitFrequency.maxGapInDays` (1 for daily, 7 for weekly), otherwise resets to `1`;
    `longestStreak` only ever rises.
- Use cases mirror Tasks' naming convention 1:1: `CreateHabitUseCase`,
  `UpdateHabitUseCase` (name/description/frequency only — status and streak are
  reachable through dedicated use cases, mirroring `UpdateTaskUseCase` rejecting
  status), `CompleteHabitUseCase` (the "log completion" use case — calls
  `Habit.recordCompletion`), `ArchiveHabitUseCase`, `DeleteHabitUseCase` (soft delete),
  `GetHabitUseCase`, `GetHabitsUseCase`, `SearchHabitsUseCase`.

### Data / persistence
- Single `habits` table (`HabitsSchema`) — one aggregate, one table, mirroring Tasks
  rather than Finance's two-table (Account/Transaction) split, since Habits has no
  second independent entity with its own identity/lifecycle. `completionLog` is
  persisted as a JSON array of `YYYY-MM-DD` strings in a single TEXT column on the same
  row, rather than a second `habit_completions` table — documented as a deliberate,
  scope-appropriate deviation from Finance's multi-table pattern (see "Technical debt").
- Indexes: `idx_habits_workspace_id`, and a partial `idx_habits_workspace_status`
  excluding soft-deleted rows (mirrors Tasks' indexes exactly).
- Soft delete via nullable `deleted_at`, identical convention to Finance/Tasks.
- Executor/transaction-runner split: `IHabitDatabaseExecutor`/`IHabitTransactionRunner`
  interfaces, `InMemoryHabitDatabaseExecutor`/`InMemoryHabitTransactionRunner` (a real
  minimal in-memory relational engine, scoped to the single `habits` table — no JOIN
  handling needed, unlike Finance's transfer-pair logic), and
  `FileBackedHabitDatabaseExecutor`/`FileBackedHabitTransactionRunner` (JSON-file
  persistence). `HabitsModule` does **not** self-register these — the app layer binds
  them, exactly like Finance/Tasks.

### Presentation
- `HabitsViewModel` (full list page): `AsyncState<List<Habit>>`, `load`/`refresh`,
  `createHabit`/`updateHabit`/`completeHabit`/`archiveHabit`/`deleteHabit`, all
  delegating to use cases and reloading on success. Reloads automatically on
  `WorkspaceContext` switch; unregisters that listener in `dispose()`.
- `HabitsHomeViewModel` (dashboard summary): computes `activeCount` and
  `completedTodayCount` presentation-side from `GetHabitsUseCase`'s result — no new
  summary use case, mirroring `TasksHomeViewModel`/`FinanceDashboardData`.
- `HabitsPage`: built from `AppStateSwitcher`, `showAppInputSurface`, and — notably —
  the **existing, frozen** `design_system` `TaskTile` component (a generic
  checkbox-row tile), not a new Habits-specific widget, since Design System must not
  be touched. The habit's current streak and frequency are surfaced via `TaskTile`'s
  `subtitle`. A `SegmentedButton<HabitFrequency>` inside the create/edit form (an
  ordinary Material widget, not a new design-system component) picks daily/weekly.

### Navigation
- New `HabitsRoutes.root` (`/habits`) registered by `HabitsModule.registerRoutes`.
- New shell branch (`ShellBranches.habitsPath`/`habitsName`) with a
  `local_fire_department` icon, inserted between Tasks and Settings in both the bottom
  `NavigationBar` and the `NavigationRail`.
- `AppRouter.create` and `_buildHabits` in `app.dart` follow the exact same
  DI-resolve-and-build pattern as `_buildTasks`.

### Home Dashboard integration
- Reused the existing `ModuleCard`/`StatCard`/`SummaryCard` extension mechanism exactly
  as Tasks does — no changes to Home's architecture. Added `_HabitsModuleCard`/
  `_HabitsCardBody` (new private widgets local to `home_dashboard_page.dart`, not new
  design-system components) showing Active / Completed-today stats, wired through
  `HabitsHomeViewModel`. Removed Habits from the static placeholder grid (it previously
  showed a "coming soon" `SummaryCard`) since it now has real data — Goals, Documents,
  Assets, and AI Assistant remain placeholders, untouched.

### Demo Mode
- No demo-specific repository/DAO/ViewModel, no `if (isDemoMode)` branching anywhere in
  `feature_habits`. Followed the exact switchable-storage pattern: `DemoModeController`
  now owns a third `SwitchableHabitDatabaseExecutor`/`SwitchableHabitTransactionRunner`
  pair alongside its Finance and Task pairs, swapped together on
  `enableDemoMode`/`exitDemoMode`/`resetDemoData`. `DemoHabitSeedData` seeds five active
  habits (mixed daily/weekly, varying streak lengths) and one archived habit via raw
  `INSERT INTO habits ...` — the same seam `DemoTaskSeedData` uses, since
  `feature_habits`'s DAO/schema classes aren't part of its public barrel.

### Files Added
- `features/habits/` — full package (`lib/`, `test/`, `pubspec.yaml`): 26 `lib` files,
  24 `test` files.
- `apps/mobile/lib/app/bootstrap/habits_storage_module.dart`
- `apps/mobile/lib/app/demo/switchable_habit_storage.dart`
- `apps/mobile/lib/app/demo/demo_habit_seed_data.dart`

### Files Modified
- `pubspec.yaml` (workspace package list)
- `apps/mobile/pubspec.yaml` (added `feature_habits` dependency)
- `apps/mobile/lib/app/bootstrap/app_bootstrap.dart` (Habits storage open + module
  registration, `habitsStorageFile` override parameter, `_defaultHabitsStorageFile`)
- `apps/mobile/lib/app/demo/demo_mode_controller.dart` (third switchable pair)
- `apps/mobile/lib/app.dart` (`_buildHabits`, `habitsBuilder`, `onOpenHabits`,
  `habitsViewModel`)
- `apps/mobile/lib/app/navigation/app_router.dart` (`habitsBuilder` parameter threaded
  through to `ShellBranches.build`)
- `apps/mobile/lib/app/shell/shell_branches.dart` (new branch + destination)
- `apps/mobile/lib/app/home/home_dashboard_page.dart` (Habits module card, quick
  action, placeholder grid entry removed)
- `apps/mobile/test/bootstrap/app_bootstrap_test.dart`,
  `apps/mobile/test/demo/demo_mode_controller_test.dart`,
  `apps/mobile/test/home/home_dashboard_page_test.dart`,
  `apps/mobile/test/navigation/app_router_test.dart`,
  `apps/mobile/test/settings/settings_page_test.dart` — updated for the new required
  constructor/factory parameters and added Habits-specific assertions.

### Testing
Wrote a full test suite mirroring Tasks' structure and, at equivalent coverage,
Finance's data-layer depth:
- `test/domain/` — entity (construction invariants, `transitionTo`, `recordCompletion`
  streak-continuation/reset math for both frequencies, duplicate-day rejection,
  archived-habit rejection, `copyWith`, equality), value objects
  (`HabitFrequency.maxGapInDays`, `HabitStatus` transition table), domain events.
- `test/data/` — `HabitRow` round-trip, `HabitMapper` (`toRow`/`toEntity`/round-trip,
  including completion-log JSON encoding and unrecognized-enum-value failures),
  `HabitDao` (every SQL shape it emits, against a fake executor), migration
  (`CreateHabitsTableMigration` schema assertions), `HabitRepository` (against the real
  DAO/mapper with a fake executor boundary, including failure translation).
- `test/application/use_cases/` — one test file per use case, covering success paths,
  validation failures, and not-found/already-archived/already-completed-today failure
  paths.
- `test/di/habits_module_test.dart` — resolves every registered type against a real
  `ServiceRegistry`, verifies route/feature registration and factory-vs-singleton
  semantics.
- `test/presentation/` — `HabitsViewModel`/`HabitsHomeViewModel` (loading state,
  workspace-switch reload, dispose unsubscribing, every CRUD operation) and
  `HabitsPage` widget tests (loading/empty states, create/edit/complete/archive/delete/
  refresh flows).
- `apps/mobile` test updates described above, plus a new "Habits persistence binding"
  group in `app_bootstrap_test.dart` mirroring the existing Finance one.

### Regression
No architectural changes were made to Platform Core, Runtime, Storage, Application,
Navigation, Design System, or Demo Mode internals — every touched file in those layers
was touched only at the exact registration/extension points Tasks itself already uses
(module registration list in `AppBootstrap`, route builder parameters in
`AppRouter.create`/`ShellBranches.build`, the `ModuleCard` extension point on
`HomeDashboardPage`, the switchable-pair extension point on `DemoModeController`).

### Technical debt / deviations (flagged explicitly, not hidden)
1. **Not compiler-verified.** See "Test Results" — this is the most important open item.
2. **Single-table completion log instead of a second `habit_completions` table.** Finance
   splits Account/Transaction into two tables because they are two independent
   entities; Habits has only one aggregate, so its completion history is stored as a
   JSON column on the habit's own row (mirroring Tasks' single-table shape). This keeps
   `HabitDao`/`HabitMapper` simple but means completion history cannot be queried
   independently of its owning habit (e.g., "all completions across all habits on date
   X") without loading every habit row. If cross-habit completion queries become a real
   product requirement, a follow-up should extract a proper `habit_completions` table
   + `HabitCompletionDao`, mirroring `TransactionDao` exactly.
3. **`SearchHabitsUseCase` and `HabitQuery`/`HabitPage` exist (mirroring Tasks) but no
   page in `HabitsPage` currently exercises pagination/search UI** — `HabitsPage` lists
   all non-archived habits directly via `GetHabitsUseCase`, exactly like `TasksPage`
   does. The search use case is available for a future search UI, consistent with how
   Tasks ships `SearchTasksUseCase` without a dedicated search page today either.
4. `CreateHabitsTableMigration` is declared for parity/documentation only and is not
   wired into a runtime migration runner — this mirrors Finance's and Tasks' identical
   current status, not a Habits-specific gap.

## Architecture Verification

Confirmed unchanged (no edits) in this session:
- **Platform Core** (`packages/platform_core`) — untouched.
- **Runtime** (`packages/platform_runtime`) — untouched (only consumed via
  `RuntimeModule`/`FeatureModule` base classes, exactly as Tasks does).
- **Storage** (`packages/platform_storage`) — untouched (only consumed via
  `Migration`/`MigrationContext` base classes).
- **Application** (`packages/application`) — untouched (only consumed via
  `AsyncUseCase`, `Result`, `DomainEvent`, `WorkspaceContext`, `AsyncState`,
  `FeatureModule`, `RouteRegistry`/`RouteDefinition`).
- **Design System** (`packages/design_system`) — untouched. `HabitsPage` reuses the
  existing `TaskTile`, `AppStateSwitcher`, `AppFormField`, `showAppInputSurface`,
  `ModuleCard`, `StatCard`, `SummaryCard` components as-is.
- **Demo Mode mechanism** — the switchable-executor pattern and `DemoModeController`
  class itself are unchanged in shape; only a third instance of the existing pattern
  (one more constructor parameter pair + one more `switchTo` call site) was added,
  exactly as instructed.
- **Home Dashboard architecture** — `ModuleCard`'s loading/error-isolation contract is
  unchanged; Habits plugs into it as a third card the same way Tasks plugs in as a
  second one.

## Test Results

**Not run.** This sandbox has no Flutter or Dart SDK installed anywhere on the
filesystem (`flutter`/`dart` are not on `PATH`, `apps/mobile/{linux,windows,macos,ios}`
only contain the Flutter *engine's* embedded platform folders, not a toolchain). Every
attempt to invoke `flutter analyze` / `flutter test` failed with "command not found"
before running a single check. Consequently:
- `flutter analyze` (features/habits, apps/mobile, repo-wide) — **not run**.
- `flutter test` (features/habits, apps/mobile, repo-wide) — **not run**.

All code was written and cross-checked manually: every renamed/rewritten file was
re-read after editing, and the whole `features/habits` + touched `apps/mobile` trees
were repeatedly grepped for stale Tasks-shaped identifiers (`title`, `dueDate`,
`HabitStatus.todo`/`.inProgress`/`.completed`, `titleContains`, etc.) until none
remained. This substantially reduces but does not eliminate the risk of a compile error
or a subtly wrong test assertion (e.g. widget-test text-finder counts after adding a
third dashboard card) slipping through. This must be the first thing verified before
merging.

## Remaining Work

1. **Run `flutter pub get`, `flutter analyze`, and `flutter test` for
   `features/habits`, `apps/mobile`, and the full workspace**, and fix whatever surfaces.
   Given the scope of hand-written/hand-edited code in this session, budget real time
   for this — it is very likely something small (an import, a parameter order, a widget
   text-finder count) needs a fix.
2. Consider extracting a `habit_completions` table if/when cross-habit completion
   queries become a requirement (see Technical debt #2).
3. No integration test equivalent to Finance's `test/integration/` /
   `test/runtime/finance_runtime_integration_test.dart` was written for Habits — Tasks
   itself doesn't have one either, so this matches the mirrored feature's actual
   coverage, but a `HabitsRuntimeIntegrationTest` would be a reasonable follow-up if one
   is ever added for Tasks.

## Recommendations

- Treat this branch as **implementation-complete but unverified**. Before it is
  considered done, a session (or the same session, resumed in an environment with the
  Flutter SDK) must run the full analyze/test suite and fix any resulting issues.
- If any analyzer/test failures turn out to be more than trivial fixes, prioritize
  re-reading this report's "Domain model", "Data / persistence", and "Presentation"
  sections against the actual code — the intent is documented precisely enough here to
  make a fix faithful to the original design rather than a quick patch.
