# Final Development Report — Personal OS Roadmap

This report continues from `.ai/reports/overnight-development-report.md` (Habits feature)
and the Goals feature session (commit `1cb4bbd`, `feat(goals): complete Goals feature`).
It covers work performed in this session: completing the Notes feature and continuing
the roadmap.

**Constraint for this session:** per explicit instruction, no build/analyze/test commands
(`flutter analyze`, `flutter test`, `melos ...`, etc.) were run at any point. All
verification below is static: reading every source file in full, tracing imports and
constructor signatures against call sites, and diffing against the Goals reference
implementation field-for-field.

---

## Feature: Notes (completed this session)

### Objective
Notes had domain/data/application/DI/presentation source and app-level wiring already
implemented in commit `9c3fb9c` ("wip(notes): partial Notes feature implementation"),
but was missing the full test suite that Goals/Finance/Habits/Tasks all carry, and had
never been statically reviewed end-to-end. This session added the missing tests and
performed that review.

### Files Added
- `features/notes/test/data/dao/fake_note_database_executor.dart`
- `features/notes/test/data/dao/note_dao_test.dart`
- `features/notes/test/data/mappers/note_mapper_test.dart`
- `features/notes/test/data/migrations/fake_migration_context.dart`
- `features/notes/test/data/migrations/create_notes_table_migration_test.dart`
- `features/notes/test/data/models/note_row_test.dart`
- `features/notes/test/data/repositories/note_repository_test.dart`
- `features/notes/test/di/notes_module_test.dart`
- `features/notes/test/presentation/notes_view_model_test.dart`
- `features/notes/test/presentation/notes_home_view_model_test.dart`
- `features/notes/test/presentation/notes_page_test.dart`

No `features/notes/lib/` or `apps/mobile/lib/` files required changes — the existing
implementation from `9c3fb9c` was already correct and complete on static review.

### Domain implementation (reviewed, unchanged)
`Note` aggregate (id, workspaceId, title, content, tags, status, createdAt, updatedAt)
with title/content length invariants and tag de-duplication enforced in the constructor.
`NoteStatus` is a two-state enum (`active`/`archived`, archived terminal) with an
`allowedNextStatuses`/`canTransitionTo` transition table mirroring `GoalStatusTransitions`.
`NoteId`, `NoteQuery`, `NotePage`, `INoteRepository`, `NotesException` all mirror their
Goals counterparts exactly.

### Data implementation (reviewed, unchanged)
`NoteRow`/`NotesSchema`/`NoteDao`/`NoteMapper`/`NoteRepository`/
`CreateNotesTableMigration` mirror Goals' equivalents field-for-field, with tags
persisted as a pipe-delimited `TEXT` column (`|tag1|tag2|`) rather than a normalized
child table — documented in `NoteRow`'s doc comment as an intentional scope decision
matching Goals/Habits' single-table engine. `InMemoryNoteDatabaseExecutor` /
`FileBackedNoteDatabaseExecutor` and their transaction-runner counterparts exist and
mirror Goals'.

### Presentation implementation (reviewed, unchanged)
`NotesViewModel` (list load/refresh/create/update/archive/delete, workspace-reactive),
`NotesHomeViewModel` (active/archived counts for the dashboard card), `NotesPage` built
from `design_system` (`AppStateSwitcher`, `DocumentTile`, `Dismissible` swipe-to-delete,
`showAppInputSurface` create/edit dialog with Title/Content/Tags fields and an inline
Archive action) — mirrors `GoalsPage` structurally.

### Navigation / Home Dashboard / Demo Mode integration (reviewed, unchanged)
- `apps/mobile/lib/app/navigation/app_router.dart` and
  `apps/mobile/lib/app/shell/shell_branches.dart`: `/notes` route and shell branch
  registered with icon/label, matching the Goals/Tasks pattern.
- `apps/mobile/lib/app/home/home_dashboard_page.dart`: `_NotesModuleCard` wired to
  `NotesHomeViewModel`, added to the dashboard grid and quick-actions row.
- `apps/mobile/lib/app/bootstrap/notes_storage_module.dart` +
  `apps/mobile/lib/app/demo/switchable_note_storage.dart` +
  `apps/mobile/lib/app/demo/demo_note_seed_data.dart`: switchable executor/runner pair
  registered once in `app_bootstrap.dart`, swapped by `DemoModeController` between the
  real file-backed executor and an in-memory demo-seeded one. Zero `isDemoMode`
  branching inside `NoteRepository`/`NoteDao` — confirmed by reading both files in full;
  demo/real switching is entirely an app-layer concern via the Switchable wrapper.
- `features/notes/lib/notes.dart` barrel: exports the persistence leaf interfaces +
  default implementations, `NotesModule`, domain entity/value-objects, `NotesPage`,
  routes, and both ViewModels — complete, matches what `apps/mobile` imports.

### Static verification performed
- Read every file under `features/notes/lib/` in full.
- Cross-checked `NotesModule` registrations (persistence, use cases, ViewModels) against
  constructor signatures of every class it instantiates — no missing or extra
  constructor arguments.
- Verified `features/notes/lib/notes.dart` barrel exports everything `apps/mobile`
  imports from `package:feature_notes/notes.dart` (grepped all `feature_notes` imports
  in `apps/mobile/lib`).
- Verified `apps/mobile/lib/app/bootstrap/app_bootstrap.dart`,
  `apps/mobile/lib/app/demo/demo_mode_controller.dart`, `apps/mobile/lib/app.dart`,
  `apps/mobile/lib/app/navigation/app_router.dart`,
  `apps/mobile/lib/app/shell/shell_branches.dart`,
  `apps/mobile/lib/app/home/home_dashboard_page.dart` all reference Notes symbols
  consistently with Goals' equivalents (same constructor shapes, same registration
  order, same demo-mode seam).
- Wrote 11 new test files mirroring Goals' test suite one-for-one: fake in-memory
  executor recording SQL/args, DAO tests asserting SQL shape (INSERT/UPDATE/SELECT
  column lists, WHERE scoping, soft-delete exclusion, COUNT+paginated query), mapper
  round-trip tests (including archived-status and no-tags round-trips, and the
  unrecognized-status-throws case), migration tests asserting the CREATE TABLE
  column/CHECK/index shape and DROP...IF EXISTS rollback, row toMap/fromMap round-trip
  tests (including the pipe-delimited tag encoding), a repository test exercising the
  real `NoteDao`+`NoteMapper` against the fake executor, a DI test resolving every
  registration through a real `ServiceRegistry`, and ViewModel/page widget tests
  covering load/create/update/archive/delete/refresh and the empty/loading states.
- Confirmed every use case constructor called in test harnesses (in particular
  `CreateNoteUseCase`'s required `idGenerator` parameter) matches the actual source
  signature, not an assumed one.
- Ran `git status --porcelain` after adding tests: only the three new test directories
  appear untracked; no `.dart_tool`, golden `failures/`, or other generated artifacts
  were staged.

### Commit
`feat(notes): complete Notes feature` — see commit hash in the summary below.

### Technical debt (carried over, not introduced by this session)
- Tags are stored as a delimited string column rather than a normalized join table;
  acceptable per Goals/Habits precedent but will need revisiting if tag-based querying
  grows beyond substring `LIKE`.
- `CreateNotesTableMigration` is schema-as-code only — not wired to a runtime migration
  runner, same status as Goals/Finance/Tasks/Habits today (the active executor is the
  hand-rolled in-memory/file-backed engine, not a real SQL engine).

---

## Remaining roadmap (not started prior to Calendar)

Assets, Documents, and AI Assistant remain queued per the task instructions; Calendar
(previously queued) is now complete — see the Calendar section below.

1. **Assets** — name, category, value, acquisition date, status.
2. **Documents** — scope depends on reading `docs/architecture/DOC-031_Finance_Domain_Design.md`
   first to determine whether metadata-only storage is the right call (Storage is frozen
   and must not be extended).
3. **AI Assistant** — requires reading `docs/architecture/DOC-014_AI_Architecture.md`
   first; very likely an architecture-approval stop (new Platform capabilities — LLM
   integration, external API calls — outside the frozen Application/Platform layers) per
   the task's own framing. No shim should be built.

## Summary

- **Features completed:** Notes (test suite + static review; source was already
  implemented) and Calendar (implemented end-to-end this session — see below).
- **Commits created:** see `git log` for `feat(notes): complete Notes feature` and
  `feat(calendar): complete Calendar feature`.
- **Remaining roadmap:** Assets, Documents, AI Assistant (AI Assistant expected to end
  as a documented architecture-approval stop, not an implementation).
- **Blockers encountered:** none for Notes or Calendar.

---

# Calendar Feature

## Objective

Implement a complete "Calendar" feature end-to-end (domain, data, application,
presentation, navigation, Home Dashboard, Demo Mode, DI, tests), mirroring the Notes
and Goals feature verticals file-for-file, per the frozen Personal OS architecture.

## Domain

- `Event` aggregate root: `id`, `workspaceId`, `title`, `timeRange` (`EventTimeRange`),
  `location`, `description`, `status` (`EventStatus`), `createdAt`, `updatedAt`. Same
  title/description length invariants as `Note`; `location` capped at 200 characters.
- `EventStatus`: `active`/`archived`, mirroring `NoteStatus`'s simpler active/archived
  lifecycle rather than Habits' streak-tracking complexity, per the task's own guidance.
  `EventStatusTransitions` extension defines the single `active -> archived` transition
  (archived is terminal).
- `EventTimeRange` value object: wraps `start`/`end` `DateTime`s, reusing Tasks'
  `TaskDueDate`-style domain-owned wrapper pattern (not a new date-handling engine) —
  the one business invariant enforced is `end` strictly after `start`, thrown as
  `CalendarException` on violation.
- `EventId`, `EventPage`, `EventQuery` value objects mirror `NoteId`/`NotePage`/
  `NoteQuery` exactly.
- Domain events: `EventCreatedEvent`, `EventUpdatedEvent`, `EventArchivedEvent`,
  `EventDeletedEvent` (declared for parity with Notes/Goals; not yet published by any
  use case, matching the existing features' current status).
- `CalendarException` extends `AppException`, mirroring `NotesException`.
- `IEventRepository` interface: `findById`, `findAll`, `findByStatus`, `search`, `save`,
  `softDelete` — all workspace-scoped, soft-delete only.

## Data

- `EventsSchema`, `EventRow`, `EventQueryFilter` — persistence-layer shapes distinct
  from domain types, mirroring Notes' `NotesSchema`/`NoteRow`/`NoteQueryFilter`.
- `CreateEventsTableMigration` — schema-as-code only, same non-wired status as every
  other feature's migration (the active executor is the hand-rolled in-memory/
  file-backed engine, not a real SQL engine).
- `EventDao` — direct SQL access to the `events` table; no business logic.
- `EventMapper` — pure `Event` <-> `EventRow` conversion, including
  `EventTimeRange` construction/decomposition.
- `IEventDatabaseExecutor` / `IEventTransactionRunner` persistence-leaf interfaces, with
  `InMemoryEventDatabaseExecutor`/`InMemoryEventTransactionRunner` (a genuine hand-rolled
  relational engine understanding `EventDao`'s exact SQL shapes) and
  `FileBackedEventDatabaseExecutor`/`FileBackedEventTransactionRunner` (JSON-file-backed,
  for restart persistence) — mirrors Notes' pair exactly.
- `EventRepository` — pure orchestration over `EventDao`/`EventMapper`, translating all
  failures into `CalendarException`.

## Application

Seven use cases, orchestration only (all business rules live in `Event`/
`EventTimeRange`): `CreateEventUseCase`, `UpdateEventUseCase` (status excluded — use
`ArchiveEventUseCase`), `ArchiveEventUseCase`, `DeleteEventUseCase` (soft-delete,
idempotent), `GetEventUseCase`, `GetEventsUseCase`, `SearchEventsUseCase`.

## Presentation

- `CalendarViewModel` — drives `CalendarPage`; `AsyncState<List<Event>>`, constructor
  injection of use cases + `WorkspaceContext`, reloads on workspace switch,
  `dispose()` unregisters its `WorkspaceContext` listener. Zero business logic.
- `CalendarHomeViewModel` — drives the Home Dashboard's `ModuleCard`;
  `AsyncState<CalendarDashboardSummary>` computed presentation-side from
  `GetEventsUseCase` (upcoming-active-count, archived-count) — no new use case
  introduced, mirroring `NotesHomeViewModel`.
- `CalendarPage` — reuses `AppStateSwitcher`, `DocumentTile`, `Dismissible` (swipe to
  delete), `showAppInputSurface`/`AppFormField` (create/edit), exactly as `NotesPage`
  does; start/end pickers use Flutter's standard `showDatePicker`/`showTimePicker`
  (no new design-system component introduced for that, since the Design System is
  frozen).

## Navigation

- `CalendarRoutes.root` (`/calendar`) registered by `CalendarModule.registerRoutes`.
- `ShellBranches`: added `calendarPath`/`calendarName`, a `ShellDestination`
  (calendar icon), and a new `StatefulShellBranch`, positioned after Notes.
- `AppRouter.create` / `apps/mobile/lib/app.dart`: added `calendarBuilder` parameter
  and `_buildCalendar` wiring, threaded through exactly like `notesBuilder`.

## Home Dashboard

`_CalendarModuleCard`/`_CalendarCardBody` added to `home_dashboard_page.dart` via the
existing `ModuleCard`/`StatCard` extension mechanism (Upcoming/Archived counts), using
the theme's pre-existing `'calendar'` `moduleAccent` key (no new color added). The
static "Upcoming" placeholder previously in `_PlaceholderModuleGrid` was removed since
Calendar now has real data — mirrors how Notes/Goals were promoted from placeholder to
real module cards. A "Add Event" `QuickActionButton` was added alongside the others.

## Demo Mode

`CalendarStorageModule` (binds `IEventDatabaseExecutor`/`IEventTransactionRunner`),
`SwitchableEventDatabaseExecutor`/`SwitchableEventTransactionRunner`, and
`DemoCalendarSeedData` (5 sample events: 4 upcoming active, 1 archived) — all mirror
the Notes pattern exactly and are wired into `DemoModeController.enableDemoMode`/
`exitDemoMode` and `AppBootstrap.boot`. Zero `isDemoMode` branching inside
`EventRepository`/`EventDao`/use cases — the swap happens entirely at the
switchable-executor seam.

## DI

`CalendarModule` (persistence, use cases, ViewModels — `feature_calendar` package) and
`CalendarStorageModule` (app-layer persistence-leaf binding) registered in
`AppBootstrap.boot`, positioned after `NotesModule`/before `DemoModule`, matching the
existing module-registration order convention.

## Files Added

- `features/calendar/` — full feature package (pubspec, `lib/calendar.dart` barrel,
  domain/data/application/presentation/di source, full test suite).
- `apps/mobile/lib/app/bootstrap/calendar_storage_module.dart`
- `apps/mobile/lib/app/demo/switchable_calendar_storage.dart`
- `apps/mobile/lib/app/demo/demo_calendar_seed_data.dart`

## Files Modified

- `pubspec.yaml` (workspace member), `apps/mobile/pubspec.yaml` (dependency)
- `apps/mobile/lib/app.dart`, `apps/mobile/lib/app/navigation/app_router.dart`,
  `apps/mobile/lib/app/shell/shell_branches.dart`
- `apps/mobile/lib/app/home/home_dashboard_page.dart`
- `apps/mobile/lib/app/bootstrap/app_bootstrap.dart`,
  `apps/mobile/lib/app/demo/demo_mode_controller.dart`
- Existing app-layer tests updated for the new required `DemoModeController`
  calendar parameters and `AppRouter.create`/`HomeDashboardPage` calendar wiring:
  `apps/mobile/test/navigation/app_router_test.dart`,
  `apps/mobile/test/settings/settings_page_test.dart`,
  `apps/mobile/test/demo/demo_mode_controller_test.dart`,
  `apps/mobile/test/bootstrap/app_bootstrap_test.dart` (added a Calendar persistence
  binding test group),
  `apps/mobile/test/home/home_dashboard_page_test.dart`.

## Static verification performed

- Traced every import in every new `features/calendar/` file and every edited
  app-layer file to confirm the referenced symbol is actually exported from that
  package's public barrel (`application.dart`, `platform_core.dart`,
  `design_system.dart`, `platform_storage`, `feature_calendar/calendar.dart`).
- Cross-checked constructor signatures against every call site (`CalendarModule`
  registrations, `CalendarViewModel`/`CalendarHomeViewModel` constructors,
  `DemoModeController`'s new calendar parameters, `AppBootstrap.boot`'s new
  `calendarStorageFile` parameter and executor/runner wiring).
- Verified DI registrations in `CalendarModule` are complete (mapper, DAO, repository,
  all 7 use cases, both ViewModels) and non-duplicated, and that
  `IEventDatabaseExecutor`/`IEventTransactionRunner` are deliberately *not*
  self-registered (bound instead by `CalendarStorageModule`, matching
  `NotesStorageModule`).
- Verified `CalendarRoutes.root` is registered in `CalendarModule.registerRoutes` and
  threaded through `ShellBranches.build`/`AppRouter.create`/`app.dart` consistently
  with Notes' `notesBuilder` wiring, and that `ShellBranches.destinations` ordering
  matches the branch list ordering.
- Verified `features/calendar/lib/calendar.dart` barrel exports every symbol the app
  layer imports (`CalendarModule`, `Event`/`EventStatus`/`EventTimeRange`/etc.,
  `CalendarPage`, `CalendarRoutes`, both ViewModels, the executor/runner pair).
- Confirmed zero `isDemoMode` branching inside `EventRepository`, `EventDao`, or any
  Calendar use case — the demo/real swap is entirely isolated to
  `SwitchableEventDatabaseExecutor`/`Runner` and `DemoModeController`.
- Confirmed naming conventions (file names, class names, variable names) are
  consistent with the Notes/Goals precedent throughout.
- Checked `git status` before committing — no `.dart_tool`, golden-test `failures/`,
  or other stray generated files were staged.
- Did not run `flutter analyze`/`flutter test`/`flutter pub get`/any build or test
  command, per instructions — verification is static/manual only, as described above.

## Commit hash

`ee50b3dcc61e6396b4d3464df81d4214e59abe1b` — `feat(calendar): complete Calendar feature`

## Technical debt (carried over / introduced)

- Same schema-as-code-only migration status as every other feature
  (`CreateEventsTableMigration` not wired to a runtime migration runner).
- `EventTimeRange` performs no timezone handling and no recurrence modeling —
  explicitly out of scope per the task framing ("recurrence explicitly out of scope").
- Calendar's demo seed data uses relative dates (`DateTime.now() + Duration(...)`)
  rather than fixed dates, so "upcoming" events stay upcoming regardless of when Demo
  Mode is enabled — intentional, but worth noting as a deviation from Notes/Goals'
  fixed-content seed data.

---

# Assets Feature (this session)

## Objective

Implement a complete "Assets" feature — tracking owned items of value (name, category,
monetary value, acquisition date, lifecycle status) — mirroring the Calendar/Notes/Goals
reference implementations file-for-file across Domain, Data, Application, Presentation,
Navigation, Home Dashboard, Demo Mode, and DI layers, with a full test suite at the same
depth as Calendar's.

## Domain design decisions

- **Category**: plain `String` field (validated non-empty, ≤100 chars in the `Asset`
  constructor), mirroring Finance's plain-string category pattern per
  `DOC-031_Finance_Domain_Design.md` rather than a closed enum.
- **Status**: `AssetStatus { active, disposed, archived }` — an extension of the
  Notes/Calendar active/archived pattern with a third, business-meaningful terminal
  state (`disposed`, for assets that are sold/given away/scrapped). Both `disposed` and
  `archived` are terminal; only `active -> disposed` and `active -> archived` are
  permitted transitions, enforced by `AssetStatusTransitions.canTransitionTo` and
  `Asset.transitionTo`.
- **Value**: `double value`, validated non-negative in the constructor (zero permitted,
  negative rejected) — mirrors Goals' `targetValue` validation style but allows zero
  since a free/fully-depreciated asset is a legitimate business case.
- **Fields**: `name`, `category`, `value`, `acquisitionDate`, `status`, plus optional
  `notes` (≤20,000 chars, mirrors `Note.content`) — no `EventTimeRange`-equivalent value
  object; acquisition is a single `DateTime`, not a range.

## Files Added

- `features/assets/` — full feature package (pubspec, `lib/assets.dart` barrel,
  domain/data/application/presentation/di source, full `test/` suite at the same
  layer/file depth as `features/calendar/test/`):
  - Domain: `Asset` entity, `AssetId`/`AssetStatus`/`AssetPage`/`AssetQuery` value
    objects, `AssetsException`, `IAssetRepository`, domain events
    (`AssetCreatedEvent`/`AssetUpdatedEvent`/`AssetArchivedEvent`/
    `AssetDisposedEvent`/`AssetDeletedEvent`).
  - Data: `AssetDao`, `AssetMapper`, `AssetRow`, `AssetQueryFilter`, `AssetsSchema`,
    `CreateAssetsTableMigration`, in-memory + file-backed executor/transaction-runner
    pairs, `AssetRepository`.
  - Application: `CreateAssetUseCase`, `UpdateAssetUseCase`, `ArchiveAssetUseCase`,
    `DisposeAssetUseCase`, `DeleteAssetUseCase`, `GetAssetUseCase`, `GetAssetsUseCase`,
    `SearchAssetsUseCase`.
  - Presentation: `AssetsViewModel`, `AssetsHomeViewModel` (+ `AssetsDashboardSummary`),
    `AssetsPage`, `AssetsRoutes`.
  - DI: `AssetsModule`.
- `apps/mobile/lib/app/bootstrap/assets_storage_module.dart` — `AssetsStorageModule`,
  mirrors `CalendarStorageModule`.
- `apps/mobile/lib/app/demo/switchable_asset_storage.dart` —
  `SwitchableAssetDatabaseExecutor`/`SwitchableAssetTransactionRunner`, mirrors
  `switchable_calendar_storage.dart`.
- `apps/mobile/lib/app/demo/demo_asset_seed_data.dart` — `DemoAssetSeedData`, five
  realistic sample assets (four active, one archived), mirrors `DemoCalendarSeedData`.

## Files Modified

- `pubspec.yaml` — added `features/assets` to the workspace package list.
- `apps/mobile/pubspec.yaml` — added `feature_assets: any` dependency.
- `apps/mobile/lib/app/bootstrap/app_bootstrap.dart` — opens the file-backed Assets
  executor/runner, builds the switchable pair, passes it into `DemoModeController`,
  registers `AssetsStorageModule`/`AssetsModule` after Calendar's, adds
  `assetsStorageFile` param and `_defaultAssetsStorageFile()`.
- `apps/mobile/lib/app/demo/demo_mode_controller.dart` — added Assets
  executor/runner/real-executor/real-runner constructor params and fields, seeds
  `DemoAssetSeedData` in `enableDemoMode`, switches back in `exitDemoMode`.
- `apps/mobile/lib/app/navigation/app_router.dart` — added `assetsBuilder` param,
  threaded into `ShellBranches.build`.
- `apps/mobile/lib/app/shell/shell_branches.dart` — added `assetsPath`/`assetsName`
  constants, an Assets `ShellDestination` (between Calendar and Settings), the
  `assetsBuilder` param, and the corresponding `StatefulShellBranch`.
- `apps/mobile/lib/app.dart` — added `assetsBuilder: _buildAssets`, wired
  `AssetsHomeViewModel`/`onOpenAssets` into `_buildHome`, added `_buildAssets()`.
- `apps/mobile/lib/app/home/home_dashboard_page.dart` — added `assetsViewModel`/
  `onOpenAssets`, load/refresh/Listenable wiring, `_AssetsModuleCard`/`_AssetsCardBody`
  (using the pre-existing `'assets'` theme color key), `onOpenAssets` quick-action
  button, and removed the static Assets placeholder card from `_PlaceholderModuleGrid`
  now that Assets has real data (module doc comment updated accordingly).
- `apps/mobile/test/navigation/app_router_test.dart`,
  `apps/mobile/test/settings/settings_page_test.dart`,
  `apps/mobile/test/demo/demo_mode_controller_test.dart`,
  `apps/mobile/test/bootstrap/app_bootstrap_test.dart`,
  `apps/mobile/test/home/home_dashboard_page_test.dart` — updated to construct the new
  required Assets constructor params (`DemoModeController`, `AppBootstrap.boot`,
  `HomeDashboardPage`), added an "Assets persistence binding" test group to
  `app_bootstrap_test.dart` mirroring Calendar's, updated dashboard content assertions
  for the new Assets card and its removal from the placeholder grid.

## Implementation notes

- **Domain/Data/Application**: produced by copying `features/calendar` wholesale, then
  mechanically renaming (`Event*` → `Asset*`, `feature_calendar` → `feature_assets`,
  package/class/file names), then hand-rewriting every entity/value-object/mapper/DAO/
  use-case/test file's *content* for Assets' actual field shape (`name`/`category`/
  `value`/`acquisitionDate`/`notes`/`status` instead of `title`/`timeRange`/`location`/
  `description`). The mechanical rename pass initially mis-renamed `DomainEvent` (a real
  `application` package base class) to `DomainAsset` and doubled up the `Event` suffix
  on the domain-event classes (e.g. `AssetCreatedEvent` → `AssetCreatedAsset`); both
  were caught and fixed during the static review pass by rewriting the four domain-event
  files by hand.
- **Presentation**: `AssetsPage` reuses `AppStateSwitcher`, `DocumentTile`,
  `AppFormField`, and `showAppInputSurface` exactly as Calendar/Notes do — an
  acquisition-date picker uses Flutter's stock `showDatePicker` (no new design-system
  component). Both Archive and Dispose actions are exposed as buttons inside the edit
  sheet.
- **Home Dashboard**: `_AssetsModuleCard`/`_AssetsCardBody` follow the
  `_CalendarModuleCard`/`_CalendarCardBody` pattern exactly, showing active-asset count
  and total value via two `StatCard`s, using `ModuleCard<AssetsDashboardSummary>` and
  the pre-existing `'assets'` `AppSemanticColors.moduleAccent` key.
- **Demo Mode**: zero `isDemoMode` branching in `AssetRepository`/`AssetDao`/any use
  case — the demo/real swap lives entirely in `SwitchableAssetDatabaseExecutor`/
  `SwitchableAssetTransactionRunner` and `DemoModeController`, exactly like every other
  feature.

## Static verification performed

- Read every file in `features/assets/lib` and `features/assets/test` after the
  mechanical rename + hand-rewrite passes; confirmed no leftover `Event`/`Calendar`
  identifiers, `title`/`location`/`timeRange` fields, or `EventTimeRange`/
  `AssetAcquisitionInfo` references remain (`grep` swept for all of the above; the only
  matches left were legitimate AppBar/dialog `title:` widget params and doc-comment
  substrings like "title invariant").
- Verified `Asset`'s constructor validation (`name`, `category`, `value`, `notes`) and
  `AssetStatus`'s transition table match what `asset_test.dart`/`asset_status_test.dart`
  assert, and that `AssetMapper.toEntity`/`toRow` round-trip every field including the
  three-state status.
- Verified `AssetsSchema.assetColumns` (11 columns) matches `AssetRow.toMap()`/
  `fromMap()` key-for-key, matches `CreateAssetsTableMigration`'s `CREATE TABLE` column
  list, and matches `DemoAssetSeedData`'s raw `INSERT INTO assets (...)` column list and
  placeholder count.
- Verified `AssetsModule.registerServices` registers `AssetMapper`, `AssetDao`,
  `IAssetRepository`, all 8 use cases (including the new `DisposeAssetUseCase`, absent
  from Calendar's 7), and both ViewModels — no duplicate registrations, and
  `IAssetDatabaseExecutor`/`IAssetTransactionRunner` are deliberately *not*
  self-registered (bound instead by `AssetsStorageModule`, matching
  `CalendarStorageModule`/`NotesStorageModule`).
- Verified `AssetsRoutes.root` is registered in `AssetsModule.registerRoutes` and
  threaded consistently through `ShellBranches.build` → `AppRouter.create` → `app.dart`
  (`_buildAssets`, `onOpenAssets`), and that `ShellBranches.destinations` ordering
  matches the branch list ordering (Assets between Calendar and Settings in both).
- Verified `features/assets/lib/assets.dart` barrel exports every symbol the app layer
  imports (`AssetsModule`, `Asset`/`AssetStatus`/`AssetId`/`AssetPage`/`AssetQuery`,
  `AssetsPage`, `AssetsRoutes`, both ViewModels + `AssetsDashboardSummary`, the
  executor/runner pair) and does not export the deleted `AssetAcquisitionInfo`/
  `asset_time_range.dart`.
- Confirmed zero `isDemoMode` branching inside `AssetRepository`, `AssetDao`, or any
  Assets use case.
- Cross-checked every constructor call site touched by this session's app-layer edits:
  `DemoModeController`'s four new Assets params against all four call sites
  (`app_bootstrap.dart`, `app_router_test.dart`, `settings_page_test.dart`,
  `demo_mode_controller_test.dart`), `AppBootstrap.boot`'s new `assetsStorageFile`
  param against its three call sites (`app_bootstrap.dart` production default,
  `app_bootstrap_test.dart`, `home_dashboard_page_test.dart`), and
  `HomeDashboardPage`'s new required `assetsViewModel` param against its two call sites
  (`app.dart`, `home_dashboard_page_test.dart`).
- Checked `git status` before committing — no `.dart_tool`, golden-test `failures/`, or
  other stray generated files were staged; only intended source/test files.
- Did not run `flutter analyze`/`flutter test`/`flutter pub get`/`melos`/any build or
  test command, per instructions — verification above is static/manual only.

## Commit hash

`0c41f99` — `feat(assets): complete Assets feature`

## Technical debt (carried over / introduced)

- Same schema-as-code-only migration status as every other feature
  (`CreateAssetsTableMigration` not wired to a runtime migration runner).
- Domain events (`AssetCreatedEvent` etc.) are declared for parity with Calendar/Notes
  but are not actually raised/dispatched anywhere — this mirrors Calendar's own
  (pre-existing) gap, not a new one introduced here.
- `DemoAssetSeedData` uses relative dates (`DateTime.now() - Duration(...)`) rather than
  fixed dates, mirroring `DemoCalendarSeedData`'s same deviation from Notes/Goals' fixed
  seed content.
