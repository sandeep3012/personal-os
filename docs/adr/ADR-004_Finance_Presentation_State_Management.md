# ADR-004 — Finance Presentation Architecture: State Management Decision

**ADR ID:** ADR-004
**Title:** UI State Management Framework Selection (Page → ViewModel → UseCase Binding)
**Status:** Proposed — Awaiting Approval
**Date:** 2026-07-18
**Approved:** —
**Author:** Architecture Review
**Related Documents:** DOC-001, DOC-008, DOC-018, DOC-023, DOC-031, ADR-001, ADR-002, ADR-003
**Supersedes:** ADR-002 §2 ("UI State Management Framework: DEFERRED to ADR-004")

---

## Context

ADR-002 approved `AsyncState<T>` as a pure Dart domain state type but explicitly deferred the UI-binding decision:

> "Which framework (Riverpod, Bloc, Signals, custom ViewModel, or retain AsyncState for UI) is used to bind `AsyncState<T>` to Flutter widgets remains intentionally deferred. This decision will be made via ADR-004 after a feature spike, before Feature Framework sprint scaffolding begins."

ADR-002 further recommended: *"Spike one feature screen using Option 1 [retain AsyncState] and one using Option 2 [Riverpod]. Evaluate testability, boilerplate, and runtime behaviour. Decide before Feature Framework sprint begins."*

In practice, the spike happened as a real feature rather than a throwaway prototype: Sprint 8C Step 4 implemented the Accounts feature end-to-end (`AccountsPage` → `AccountsViewModel` → five Account use cases → `IAccountRepository`) using:

- `AsyncState<T>` for load/success/error state (ADR-002 Option 1, already approved at the domain layer)
- A plain `ChangeNotifier`-based ViewModel (ADR-002 Option 5) exposing that `AsyncState<T>` plus an orthogonal `isRefreshing` flag
- `ListenableBuilder` (Flutter SDK) to rebuild the page in response to ViewModel changes

This ran ahead of ADR-004's approval, which DOC-031 §12 identifies as a prerequisite for any Finance presentation work. This ADR now formalizes that decision retroactively, using the completed Accounts implementation as the empirical evidence ADR-002 asked for, before Transactions (or any further Finance feature) repeats the pattern.

---

## Review of the Existing Application

**Current UI architecture:** One real screen exists (`AccountsPage`), one reference screen (`SamplePage`, static/stateless — no state management need). No other Flutter screen in the repository predates this decision.

**Existing presentation patterns:** None beyond what Accounts introduced. `packages/application`'s `AppState`/`AsyncState<T>` were designed as pure-Dart domain types (ADR-001, ADR-002) — deliberately Flutter-independent.

**Dependency injection style:** Constructor injection only, via `IDependencyRegistrar`/`IServiceLocator` (`ServiceRegistry`). `FeatureModule.registerServices` registers ViewModels with `registerFactory` (fresh instance per resolution) — the same convention already used for use cases. No service-locator calls occur inside widgets; the app-layer composition root (`apps/mobile/lib/app.dart`) resolves a ViewModel once per `GoRoute` builder and passes it into the page's constructor.

**Navigation:** ADR-003 already settled this. `RouteRegistry`/`ApplicationRouter` are platform-independent; `apps/mobile`'s `AppRouter`/`app.dart` bridge to `go_router`. Feature packages never import `go_router`. This ADR does not revisit ADR-003 — it only defines how a resolved ViewModel reaches the page `go_router` builds.

**`AsyncState<T>` usage:** Already approved at the domain layer (ADR-002 §1). Accounts is the first case of it appearing in a ViewModel's public API and being pattern-matched (`.when(...)`) inside a widget's `build()`.

**Existing Flutter SDK usage:** `StatefulWidget`, `ChangeNotifier`, `ListenableBuilder` — all Flutter SDK, zero third-party packages. `apps/mobile/pubspec.yaml` and `features/finance/pubspec.yaml` list no state-management package (no `provider`, `flutter_riverpod`, `flutter_bloc`, `signals_flutter`, or similar).

**Existing third-party state-management packages:** None. Introducing one now would be the first such dependency in the entire monorepo.

---

## Decision

**Adopt the ViewModel pattern: `AsyncState<T>` (domain) + `ChangeNotifier` + `ListenableBuilder` (Flutter SDK only). No third-party state-management package.**

This formalizes ADR-002 Option 1 (retain `AsyncState<T>`) combined with Option 5 (custom ViewModel), exactly as already implemented for Accounts. No code changes are required by this ADR — it ratifies the existing implementation as the standing pattern for all subsequent Finance (and future feature) presentation work.

### Why Chosen

1. **Zero new dependencies.** Every other architectural layer in this project (`platform_core`, `platform_runtime`, `application`) is built with a stated bias toward minimal dependencies and Flutter-independence (ADR-001 explicitly forbids `application` from importing Flutter). A pure-SDK presentation layer is the only option consistent with that bias without requiring its own separate justification.
2. **`AsyncState<T>` is already the approved domain vocabulary.** Reusing it at the UI boundary means a ViewModel's public state type is identical to what its use cases already return — no adapter layer, no second state type to keep in sync (unlike Riverpod's `AsyncValue<T>`, which would require a mapping step from `AsyncState<T>`).
3. **`ChangeNotifier`/`ListenableBuilder` require no code generation, no `Ref` threading, and no provider tree wiring.** A ViewModel is a plain Dart object; DI already resolves it via the existing `registerFactory` convention. This is the smallest possible addition on top of infrastructure that already exists.
4. **Empirically validated, not merely theorized.** Accounts already demonstrates the full lifecycle (loading/success/error/refreshing, create/update/delete, specification-failure surfacing) working end-to-end with 31 passing tests (14 ViewModel, 12 widget, 5 navigation) and zero framework-specific test scaffolding beyond standard `flutter_test`.

### Why Alternatives Were Rejected

| Option | Verdict | Reason |
|---|---|---|
| **Riverpod** | Rejected | Requires `AsyncValue<T>` ↔ `AsyncState<T>` translation at every ViewModel boundary, or replacing `AsyncState<T>` outright (re-opening an already-approved ADR-002 decision). Adds `Ref` objects, provider scoping, and code generation (`riverpod_generator`) — meaningful boilerplate and a build_runner dependency for a monorepo that currently has none. |
| **Bloc/Cubit** | Rejected | More ceremony per feature (events, states, `Emitter`) than the problem currently justifies. `bloc_test` is a second testing framework alongside `flutter_test`, which the Accounts test suite (14+12+5 tests) demonstrates isn't necessary. |
| **Signals** | Rejected | Smaller ecosystem/community than the alternatives above; introduces a new reactivity primitive (`signal`/`computed`) that has no precedent anywhere else in this codebase and no compensating benefit over `ChangeNotifier` at current feature complexity. |
| **Provider (package)** | Rejected | Would only add `InheritedWidget`-style lookup convenience over what constructor injection (already the project's standing convention — ADR-001) already provides. No net capability gain for a real dependency addition. |
| **`ValueNotifier<T>` alone (no ViewModel class)** | Rejected | Works for a single primitive value; Accounts needs several coordinated fields (`state`, `isRefreshing`) plus behavior (`createAccount`, `deleteAccount`, etc.) that a bare `ValueNotifier<T>` cannot express without wrapping it in exactly the kind of class this ADR already approves — i.e., a `ChangeNotifier`-based ViewModel is `ValueNotifier`'s natural generalization here, not a competing option. |
| **`InheritedWidget` (raw, no package)** | Rejected as the *propagation* mechanism | `InheritedWidget` solves "how does a descendant widget find an ancestor's value," which this architecture doesn't need — ViewModels are handed to pages directly via constructor at the point `go_router` builds them (see Navigation section), not looked up from an ancestor. `ListenableBuilder` (which itself needs no `InheritedWidget`) already solves "rebuild when the ViewModel changes." |

### Expected Scalability

The pattern scales per-feature, not per-app: each page owns exactly one ViewModel with a `registerFactory` DI binding. Nothing here caps the number of Finance screens; `AccountsViewModel`'s shape (a `state` getter, an `isRefreshing` flag, and imperative methods returning `Result<T>`) is directly reusable as a template for `TransactionsViewModel`, `TransferViewModel`, etc. The main scaling concern is **cross-ViewModel coordination** (e.g., a Transactions screen needing to know when Accounts changed) — not addressed by this ADR; see Future Considerations.

### Testing Implications

No new test infrastructure required. `ChangeNotifier` is directly observable via `addListener`/`removeListener` (used in `accounts_view_model_test.dart` to count notifications) and `ListenableBuilder` responds to it automatically in widget tests via ordinary `pumpAndSettle()`. Contrast with Riverpod (`ProviderContainer` + overrides) or Bloc (`blocTest`, `whenListen`) — both would require adopting a second testing vocabulary alongside plain `flutter_test`, which the existing 676-test Finance suite does not need.

### Performance Implications

`ChangeNotifier.notifyListeners()` triggers only the `ListenableBuilder` subtree wrapping the page — not a global rebuild. At current and near-term Finance screen complexity (single list + dialogs), this is not a measurable concern. No fine-grained reactivity (Signals-style dependency tracking) is needed until a screen has enough independently-updating regions that whole-page rebuilds become visibly wasteful — not the case for any page built or planned so far.

### Developer Experience / Learning Curve

Lowest of all evaluated options for this team: `ChangeNotifier` and `ListenableBuilder` are core Flutter SDK, documented in Flutter's own guides, requiring no new mental model beyond "call `notifyListeners()` when state changes." Riverpod and Bloc both have real learning curves (provider scoping rules; event/state modeling) that this project has no current need to pay for.

### Long-Term Maintenance

No third-party package version to track, no breaking-change risk from an external maintainer, no generated code to regenerate on SDK upgrades. The tradeoff is that this project owns slightly more boilerplate per ViewModel than Riverpod's generated providers would produce — judged acceptable given the project's consistent preference (ADR-001, ADR-003) for owning small platform-independent abstractions over adopting external frameworks.

---

## Architecture

```
Page (StatefulWidget)
  ↓ constructor injection (ViewModel passed in, not looked up)
ViewModel (ChangeNotifier)
  ↓ constructor injection (use cases only)
Use Cases (AsyncUseCase<I, O>)
  ↓ constructor injection (repository interfaces only)
Repositories (IAccountRepository, ITransactionRepository, …)
  ↓ constructor injection (DAOs + mappers)
Persistence (DAO → Mapper → IFinanceDatabaseExecutor)
```

### Ownership of State

| Layer | Owns |
|---|---|
| Page | Rendering only. Holds no business or async state of its own beyond ephemeral, purely-visual widget state (e.g., a `TextEditingController` for an open dialog) that never outlives the widget. |
| ViewModel | The screen's `AsyncState<T>` and any UI-only flags (`isRefreshing`). This is the **single source of truth** the page renders from. |
| Use Case | Nothing persistent — a stateless orchestrator invoked per call. |
| Repository | Nothing screen-related — persistence-facing state only (handled entirely below the ViewModel boundary). |

### Lifecycle

- A ViewModel is created once per page instance, by DI (`registerFactory`), at the moment `go_router` builds that route.
- The page calls `viewModel.load()` in `initState()` — not in `build()` — so a rebuild never re-triggers a fetch.
- The ViewModel is **not** shared across pages and is **not** cached across navigations away-and-back (a fresh instance is resolved on the next `GoRoute` build) — consistent with `registerFactory` semantics already established for use cases in `FinanceModule`.
- `ChangeNotifier.dispose()` should be called from the page's `dispose()` once a ViewModel holds any disposable resource (Accounts today holds none, so this is a forward-looking rule, not a current gap).

### Dependency Direction

Strictly downward, exactly as pictured above. A ViewModel never imports a repository, DAO, or mapper type — enforced today only by convention and code review; see ViewModel Rules for the explicit, checkable statement of this constraint.

### Refresh Behavior

Two distinct signals, both owned by the ViewModel:
- **`state`** (`AsyncState<T>`) — reset to `.loading()` only on the *first* load or after an error retry.
- **`isRefreshing`** (`bool`) — set during a `refresh()` call (e.g., pull-to-refresh) while the *existing* `state` remains visible, so the user's current list doesn't disappear behind a spinner during a manual refresh.

### Error Handling

A use case's `Result.failure` becomes `AsyncState.error(exception)` when it affects the screen's primary content (e.g., the initial account list failing to load), or is returned directly from an imperative ViewModel method (`createAccount`, `deleteAccount`, …) for the page to display as a transient message (`SnackBar`) — the page never inspects *why* it failed beyond `exception.message`; it never re-derives or re-checks the business rule that produced the failure.

### Loading Handling

`AsyncState.loading()` is the ViewModel's initial state and whatever `state` reverts to on a fresh `load()`. Pages render it as a full-screen indicator; `isRefreshing` is the loading signal for a refresh-in-place instead.

---

## ViewModel Rules

1. **No repository injection.** A ViewModel's constructor accepts only use cases (and, where needed, workspace/session-scoping values — see Workspace Context below). `IAccountRepository`/`ITransactionRepository` must never appear in a ViewModel's constructor signature.
2. **No DAO injection.** `AccountDao`/`TransactionDao` are two layers below where a ViewModel is allowed to reach.
3. **Use cases only** as collaborators for business operations. A ViewModel orchestrates *calls* to use cases; it must not re-implement, duplicate, or bypass any business rule a use case (or the specification/domain layer beneath it) already enforces.
4. **No `BuildContext` in ViewModels.** `BuildContext` is a widget-tree concept; a ViewModel is plain Dart and must remain constructible and testable with zero Flutter widget dependencies (only Flutter *SDK* — `ChangeNotifier` — not Flutter *widgets*).
5. **UI state only.** A ViewModel's fields represent what the *screen* needs to render (`state`, `isRefreshing`, and — if a future screen needs it — form-input echoes), never domain state that belongs on an entity or a repository.
6. **No service locator inside a ViewModel.** All collaborators arrive via constructor parameters, resolved once by `FinanceModule` at DI-registration time — a ViewModel never calls `locator.get<T>()` itself.

## Page Rules

1. **Pages own rendering only.** A page's `build()` method is a pure function of `viewModel.state` (and any transient local widget state for open dialogs). It contains no business logic and no direct repository/use-case calls.
2. **ViewModels own orchestration.** Every user action a page can trigger (create, update, delete, refresh) is a single call to a ViewModel method — never a multi-step sequence assembled inside the page.
3. **Use cases own business logic.** Enforced upstream of the ViewModel; the page has no path to bypass this even if it wanted to, since it holds no use-case reference at all.
4. **Repositories own persistence.** Unreachable from a page or ViewModel by construction (Rules 1–2 above).
5. **No service locator inside a widget.** A page must never call `locator.get<T>()` (or resolve anything from a `ServiceRegistry`) directly — its ViewModel (and any other collaborator) arrives exclusively via constructor, resolved once by the app-layer composition root at route-build time.

---

## Navigation

**How pages receive ViewModels:** Exactly as Accounts already established — the app-layer composition root (`apps/mobile/lib/app.dart`'s `_buildFeatureRoutes()`) resolves the ViewModel from the DI container inside the `GoRoute` builder closure and passes it to the page's constructor:

```dart
GoRoute(
  path: FinanceRoutes.accounts.path,
  name: FinanceRoutes.accounts.name,
  builder: (context, state) => AccountsPage(
    viewModel: widget.bootstrap.registry.get<AccountsViewModel>(),
  ),
),
```

This is consistent with ADR-003's existing pattern for `SamplePage`/`SampleService` — no new navigation mechanism is introduced by this ADR.

**DI ownership:** `FinanceModule.registerServices` owns every ViewModel registration (`registerFactory`), exactly as it already owns use-case registration. The app layer never constructs a ViewModel manually — it only resolves one that `FinanceModule` already registered.

**Route lifecycle:** A ViewModel's lifetime is bound to its `GoRoute` builder invocation — `go_router` calls the builder (and therefore resolves a fresh ViewModel via `registerFactory`) each time the route is navigated to. Navigating away and back produces a new ViewModel instance and a fresh `load()`, not a resumed one. This is a deliberate simplicity choice consistent with `registerFactory`'s existing semantics; if a future screen needs state to survive across navigations (e.g., scroll position, in-progress form input), that is a distinct, currently unapproved requirement — not something this ADR's pattern provides for free.

---

## Workspace Context

**Current state:** `FinanceModule` hardcodes `_defaultWorkspaceId = 'default-workspace'`, and every ViewModel receives it as a constructor parameter. This was flagged as a known placeholder in the Sprint 8C Step 4 report, not a hidden gap.

**Recommendation: `WorkspaceContext` service**, not `CurrentWorkspaceUseCase`, not a session context.

**Rationale:**
- DOC-008 establishes Workspace as a cross-cutting **Platform** concern ("A Workspace is an independent Personal OS instance… Workspace Does Not Own: Platform SDK, Platform Runtime") with its own lifecycle (Create → Initialize → Active → Suspended → Archived → Deleted) and an explicit switching procedure. This is not Finance-specific business logic, so it does not belong in a Finance use case (`CurrentWorkspaceUseCase` would incorrectly scope a platform concern inside one feature package).
- "Session context" is rejected because no authentication/session concept exists anywhere in this codebase yet (DOC-001/DOC-002 make no mention of one for the current MVP scope) — introducing one now would be inventing infrastructure ahead of an actual requirement.
- A `WorkspaceContext` service belongs in `packages/application` (or, if it needs to react to workspace-switch events, wired through `IEventBus` from `platform_runtime`), registered by `ApplicationModule` exactly as `RouteRegistry`/`FeatureRegistry` already are — giving every feature module (not just Finance) a single, consistent way to read "what is the active workspace right now," with the workspace-switching procedure (DOC-008) as the only writer.
- Every Finance ViewModel would then receive `WorkspaceContext` (or just its current `workspaceId` snapshot) as a constructor dependency instead of a hardcoded string — a one-line change per ViewModel once `WorkspaceContext` exists, since the constructor parameter shape (`required String workspaceId` or `required WorkspaceContext workspaceContext`) is already isolated to one place per ViewModel.

**Not implemented by this ADR** — this section documents the target architecture only, per the task's explicit instruction not to implement it.

---

## Testing Strategy

| Test type | What it covers | Precedent |
|---|---|---|
| **ViewModel tests** | State transitions (`loading`/`success`/`error`), business-rule surfacing (via real use cases + fake repositories, since use case classes are `final` and cannot be mocked directly), `notifyListeners()` behavior, `isRefreshing` semantics | `accounts_view_model_test.dart` (14 tests) |
| **Widget tests** | Rendering of each `AsyncState` branch, dialog open/submit flows, `SnackBar` failure surfacing, list mutation after create/update/delete | `accounts_page_test.dart` (12 tests) |
| **Navigation tests** | Route registration, `ApplicationRouter` resolution by path/name, ViewModel resolvability from the same container the route was registered against | `accounts_navigation_test.dart` (5 tests) |
| **Integration tests** | Full stack — ViewModel → real use cases → real repositories → in-memory persistence engine — already established at the repository layer (Sprint 8B `test/integration/`); a presentation-level equivalent is optional and lower-priority since ViewModel tests already exercise real use cases end-to-end down to the fake repository boundary. |
| **Golden tests** | Not currently applicable. No design system (DOC-021) or visual regression tooling is in place yet, and Finance pages are explicitly "no advanced UI polish" per Sprint 8C Step 4's own scope. Revisit once a design system exists and pages have stable, intentional visual design worth pinning. |

No new testing framework is required by any of the above — all use `flutter_test`, consistent with "lowest developer-experience cost" from the Decision section.

---

## Alternatives Considered

See the "Why Alternatives Were Rejected" table under Decision. Summarized:

| Alternative | Status |
|---|---|
| Riverpod | Rejected — translation layer / build_runner dependency not justified |
| Bloc/Cubit | Rejected — more ceremony, second testing vocabulary |
| Signals | Rejected — no precedent, smaller ecosystem, no compensating benefit at current scale |
| Provider (package) | Rejected — redundant with existing constructor-injection convention |
| `ValueNotifier<T>` alone | Rejected as insufficient — generalizes into the approved `ChangeNotifier` ViewModel anyway |
| `InheritedWidget` (raw) | Rejected as the propagation mechanism — not needed given direct constructor injection at route-build time |

---

## Consequences

### Positive

- Retroactively validates and formalizes a pattern already shipped (Accounts) and tested (31 tests), rather than requiring a rewrite.
- Zero new dependencies added to the monorepo — consistent with every prior ADR's dependency discipline (ADR-001 forbidding Flutter in `application`; ADR-003 forbidding `go_router` in feature packages).
- Clear, checkable rules (ViewModel Rules, Page Rules) give future Finance work (Transactions, Transfers, Reports) an unambiguous template instead of re-deriving the pattern per feature.
- Testing strategy requires no new tooling investment.

### Negative / Risks

- `ChangeNotifier`/`ListenableBuilder` offer coarser rebuild granularity than Signals-style fine-grained reactivity — acceptable today, worth revisiting only if a screen's complexity grows enough for this to matter.
- No cross-ViewModel coordination mechanism exists yet (e.g., Transactions needing to know Accounts changed) — deferred, see Future Considerations.
- The `_defaultWorkspaceId` placeholder remains unresolved by this ADR (by design — Workspace Context is documented, not implemented here) and must be addressed before any multi-workspace scenario is exercised.

---

## Migration

No migration is required. `AccountsViewModel`/`AccountsPage` already conform to this ADR's rules exactly as built in Sprint 8C Step 4 — this ADR ratifies the existing code rather than requiring changes to it. Future Finance features (Transactions, Transfers, Reports, Categories, Budgets, Settings) must follow the same Page → ViewModel → UseCase pattern and the ViewModel/Page Rules above from their first implementation.

---

## Future Considerations

- **Workspace Context implementation** (see above) — needed before any multi-workspace UI scenario, and before this placeholder can be removed from `FinanceModule`.
- **Cross-ViewModel coordination** — if a future screen needs to react to another screen's ViewModel changing state (e.g., a Transactions list needing to refresh after a Transfer completes elsewhere), this ADR does not yet define a mechanism. Candidate future approaches: `IEventBus` (already exists in `platform_runtime`) publishing a domain event the affected ViewModel subscribes to, versus a shared/injected coordination object. Should be resolved via amendment when the first concrete need arises, not speculatively now.
- **Golden testing** — revisit once DOC-021 (Design System) is implemented and Finance pages have a stable visual design worth protecting against regression.
- **Fine-grained reactivity** — if a future Finance screen (e.g., a dashboard with many independently-updating tiles) makes whole-page `ListenableBuilder` rebuilds a measurable performance problem, Signals or a scoped `ValueListenableBuilder`-per-field approach should be evaluated then, with real profiling data — not preemptively.

---

## Actions

- [ ] Product Owner / Architecture Review to approve this ADR
- [ ] Update DOC-031 to remove the "requires ADR-004 approval" blocking note once approved
- [ ] Apply ViewModel Rules and Page Rules to all subsequent Finance feature implementations (Transactions next)
- [ ] Schedule a follow-up ADR (or amendment) for `WorkspaceContext` implementation before any multi-workspace scenario is required
