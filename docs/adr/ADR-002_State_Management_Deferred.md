# ADR-002 — State Management: AsyncState\<T\> Approved; UI Framework Deferred

**ADR ID:** ADR-002
**Title:** AsyncState\<T\> Approved as Domain Type; UI State Framework Deferred to ADR-004
**Status:** Partially Accepted — UI Framework Selection Deferred
**Date:** 2026-07-11
**Approved:** 2026-07-11
**Author:** Architecture Review
**Related Documents:** DOC-001, DOC-023, ADR-001

---

## Context

The root `README.md` has explicitly deferred state management since the project began:

> "State Management: TBD (Sprint 2+)"

During Sprint 6, `AsyncState<T>` — a sealed Dart class with `LoadingState<T>`, `SuccessState<T>`, and `ErrorState<T>` subtypes — was implemented in `packages/application`.

Sprint 7 will create the first feature packages. The question is whether feature packages may use `AsyncState<T>` before a UI state management framework is selected.

---

## Decision

This ADR records two separate resolutions:

### 1 — AsyncState\<T\> as Domain State Type: APPROVED

`AsyncState<T>` is approved as a **pure Dart domain state representation type**.

It is the canonical type for expressing the loading / success / error lifecycle of an async operation in use cases and domain services. It is NOT a UI framework binding. Feature packages may use `AsyncState<T>` in their use-case return types and domain service interfaces as of Sprint 7.

```dart
// Approved usage — domain/use-case layer:
Future<AsyncState<List<Transaction>>> getTransactions();

// NOT yet approved — UI binding:
// final AsyncState<List<Transaction>> _state = ...
// Widget build() => state.when(loading: ..., success: ..., error: ...);
```

The sealed class pattern (Dart 3) is the approved implementation. No changes to the implementation are required.

### 2 — UI State Management Framework: DEFERRED to ADR-004

Which framework (Riverpod, Bloc, Signals, custom ViewModel, or retain AsyncState for UI) is used to bind `AsyncState<T>` to Flutter widgets remains **intentionally deferred**.

This decision will be made via ADR-004 after a feature spike, before Feature Framework sprint scaffolding begins.

**Constraint:** Feature packages created in Sprint 7 must not build production Flutter widget bindings against `AsyncState<T>` until ADR-004 is approved. Use-case and domain layer usage is unrestricted.

---

## Options for ADR-004 to Evaluate

### Option 1 — Retain AsyncState\<T\> for UI binding (extend current implementation)

Use `AsyncState<T>` at both domain and presentation layers.

**Pros**
- Zero external dependencies
- Pure Dart, consistent with Platform SDK philosophy
- Already implemented with 19 unit tests
- Single type throughout the stack

**Cons**
- UI binding requires manual `setState` or `InheritedWidget` scaffolding
- No DevTools state inspector integration
- No code generation support

---

### Option 2 — Riverpod

Use `flutter_riverpod` with `AsyncNotifier` / `NotifierProvider`.

**Pros**
- Strong typing, fully testable
- `AsyncValue<T>` conceptually maps to `AsyncState<T>` — migration path is clear
- DevTools integration, large community, stable v3.x API

**Cons**
- Adds Flutter dependency to feature packages (or forces ViewModel layer boundary)
- `Ref` objects required in notifiers

---

### Option 3 — Bloc / Cubit

**Pros**
- Well-established in enterprise Flutter projects
- `bloc_test` utilities, clear event → state → UI flow

**Cons**
- Adds Flutter dependency
- More boilerplate per feature than Riverpod

---

### Option 4 — Signals

**Pros**
- Fine-grained reactivity, minimal boilerplate
- Pure Dart core; Flutter widgets via `signals_flutter`

**Cons**
- Smaller ecosystem, less community resources

---

### Option 5 — ViewModel pattern (custom)

Define `ViewModel<S>` in `packages/application` backed by `ChangeNotifier` or `ValueNotifier` at the app layer.

**Pros**
- Keeps business logic in pure Dart
- Familiar MVVM pattern

**Cons**
- `ChangeNotifier` is Flutter-specific; ViewModel must remain pure Dart

---

## Recommendation for ADR-004 Process

1. Spike one feature screen using Option 1 and one using Option 2
2. Evaluate testability, boilerplate, and runtime behaviour
3. Decide before Feature Framework sprint begins
4. ADR-004 must document: selected option, rationale, migration plan for `AsyncState<T>` (retain, replace, or supersede), and feature package convention

---

## Consequences

### Domain layer (approved)

- Feature packages use `AsyncState<T>` in use-case return types and domain service interfaces from Sprint 7 onwards
- No breaking change risk — domain types are implementation details of pure-Dart code

### UI layer (deferred)

- Sprint 7 feature packages must not build Flutter widget bindings against `AsyncState<T>`
- Prevents locked-in technical debt from an unapproved UI pattern
- Decision is made with empirical spike evidence

---

## Actions

- [x] Approve `AsyncState<T>` as domain state type
- [ ] Product Owner to schedule feature spike before Sprint 7 UI scaffolding
- [ ] Produce ADR-004 — State Management Framework (UI binding)
- [ ] Constrain Sprint 7 feature scaffolding to domain-layer usage of `AsyncState<T>` until ADR-004 approved
