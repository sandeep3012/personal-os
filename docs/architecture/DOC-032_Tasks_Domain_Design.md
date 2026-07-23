# DOC-032 — Tasks Domain Design

**Version:** 1.0 (Finalized MVP Domain — Architecture Approved)
**Status:** Architecture Approved — Ready for Sprint "Tasks Domain (Pure Dart)" per the Finance precedent (DOC-031 §12 Sprint 8A pattern)
**Category:** Feature Domain
**Depends on:** DOC-002, DOC-007, DOC-019, DOC-029 (see §16.1 — still not updated), Feature_Template.md, ADR-001, ADR-003, ADR-004
**Structural template:** DOC-031 (Finance Domain Design)
**Supersedes:** DOC-032 v0.1 (Draft) — this version resolves Decisions D1–D7 raised there. D8 remains open (administrative, not a domain-architecture blocker — see §16.1).

> **Product framing, decided this pass:** Tasks is a **personal task manager**, not a project-management system. It is explicitly not Jira, Trello, or Asana. This framing resolves the aggregate-boundary question (§4) and bounds every "is X in scope" question below.

---

## 1. Purpose

This document is the architecture contract for the Tasks feature — the same role DOC-031 plays for Finance. Unlike v0.1, this version is **domain-complete for MVP**: every entity field, business rule, state transition, repository contract, use case, and storage decision below is either derived from already-approved architecture or fixed by an explicit decision made in this pass. Nothing here is invented beyond what was decided; nothing is left ambiguous that this pass was asked to resolve.

`[Derived: Feature_Template.md]` Package structure, DI registration, naming conventions, and testing expectations are identical to Finance's and are not restated in full here — see Feature_Template.md and DOC-031 §12 for the mechanical pattern (`features/tasks`, `TasksModule`, `TasksRoutes`, etc.).

---

## 2. Scope

### 2.1 MVP Scope (Decided)

Tasks MVP is intentionally minimal: a personal task list with a title, a status, and optional description/due date. It is not a project-management system.

**In scope:**
- Task entity with the fields in §5.
- Full lifecycle CRUD + status transitions (§11).
- Home Dashboard summary (task count, completed today, quick add).
- Demo Mode integration via the existing Milestone 6 architecture.

**Explicitly out of scope for MVP (decided, not deferred-pending-discussion):**

| Capability | Status |
|---|---|
| Subtasks | Out of scope |
| Recurrence | Out of scope |
| Reminders | Out of scope |
| Attachments | Out of scope |
| Labels | Out of scope |
| Priority (`TaskPriority`) | Out of scope — do not introduce |
| Category (`TaskCategory`) | Out of scope — do not introduce |
| Calendar sync | Out of scope |
| Collaboration / multi-user | Out of scope |
| Project / List / Board grouping | Out of scope — no such aggregate exists (§4) |

This table replaces v0.1's §16 Decisions D2, D4, D7 — all resolved as "out of scope," not merely "undecided."

### 2.2 What this document still does not cover

`[Requires Architecture Approval — administrative, not domain-blocking]` DOC-029 (MVP Scope & Backlog) still does not list Tasks in its "MVP Scope" or "Prioritized Backlog" sections. This is unchanged from v0.1 (D8) and is **not** resolved by this pass, because it's a backlog/prioritization document update, not a domain decision — see §16.1.

---

## 3. Ubiquitous Language

`[Derived: DOC-002, DOC-007 — unchanged from v0.1]` Workspace, Entity, Capability, Entity Lifecycle, Tasks Module — as previously established.

`[Decided this pass]` Terms now fixed:

| Term | Definition |
|---|---|
| **Task** | A single, standalone unit of personal work. The aggregate root of the Tasks bounded context. Has a title, a status, and optionally a description, due date, and completion timestamp. |
| **TaskStatus** | A Tasks-owned (not platform-Classification-owned) enumeration of a Task's workflow state: `todo`, `in_progress`, `completed`, `archived`. See §11. |
| **Completion** | The act of transitioning a Task to `completed`, recording `completedAt`. Not the same as archiving. |
| **Archiving** | The act of transitioning a Task to `archived` — Tasks' terminal, "removed from active view" state. Mirrors Finance's soft-delete concept in spirit (see §10.6) but is a distinct, domain-visible status, not a hidden `is_deleted` flag alone. |

`[Decided this pass — removes v0.1 ambiguity]` **Status is domain-owned, not a platform Classification reference.** DOC-002 lists "Status" under the platform Classification System as a *generic possibility* other Apps could adopt, but that same document leaves each App free to decide whether its own status is domain logic or platform classification (Finance made an analogous choice differently for `TransactionType`, which is domain-owned, vs `CategoryId`, which is platform-opaque — both are valid patterns already present in approved architecture). This decision selects the domain-owned pattern for Tasks, matching how `TransactionType` drives Finance's own business rules — because, per this pass, Task status *does* drive enforceable business rules (§11), the same reason `TransactionType` is domain-owned rather than an opaque reference.

**Terms explicitly retired from v0.1's open-question list:** Priority, Category, Project-as-container, Due-date-in-scope — all resolved below.

---

## 4. Aggregate Root

**Decided this pass, confirming v0.1's derivation:** `Task` is a single, standalone aggregate root. **There is no Project aggregate, no List aggregate, no Board aggregate.** This is now a decided product-scope fact ("Tasks is a personal task manager, not Jira/Trello/Asana"), not merely the DOC-007-derived default it was in v0.1 — v0.1's Decision D3 is resolved.

This mirrors Finance's principle that entities don't own other entities (DOC-007) and additionally settles the specific product question DOC-007 alone couldn't answer: there is no Tasks-internal grouping construct of any kind, ever, at MVP. If a future Project feature exists, it groups Tasks via the Entity Linking Service (DOC-002/DOC-007), never via a foreign key inside the Task entity.

Unlike Finance (which has two cooperating entities — Account and Transaction — because a ledger entry is meaningless without a container to hold a balance), Tasks needs only one, because a Task is self-contained: it does not represent a movement of something *between* two other things the way a Transaction does.

---

## 5. Entities

### 5.1 Task

`[Decided this pass]`

| Field | Type | Required | Notes |
|---|---|---|---|
| `taskId` | `TaskId` | Yes | Typed UUID wrapper, mirroring `AccountId`/`TransactionId`. |
| `workspaceId` | `String` | Yes | Workspace isolation boundary — DOC-002/DOC-007, identical to Finance. |
| `title` | `String` | Yes | Required non-empty short text. Validation rule: see §5.3. |
| `status` | `TaskStatus` | Yes | Domain-owned enum — see §6.1, §11. |
| `description` | `String?` | No | Optional free text. |
| `dueDate` | `TaskDueDate?` | No | Optional. See §6.2. |
| `completedAt` | `DateTime?` | No | Set exactly when `status` transitions to `completed` (§11); cleared only if the entity is later archived without ever having completed — see §10.4 for the precise rule. |
| `entityType` | `String` | Yes | `'task'` — for the platform capability system, mirroring Finance's `entityType: 'account'` / `'transaction'` (DOC-007, DOC-031 §4.1). |
| `createdAt` | `DateTime` | Yes | DOC-007 universal identity field. |
| `updatedAt` | `DateTime` | Yes | DOC-007 universal identity field. |

**No other fields.** Priority, category, labels, attachments, subtasks, recurrence rule, and reminder configuration are explicitly not present on this entity (§2.1). This resolves v0.1 §5's entire "Requires Architecture Approval" block.

**Capabilities declared** (mirroring Finance's declare-without-owning pattern, DOC-031 §4.1): `Searchable`, `Taggable`, `Linkable`, `TimelineEnabled`. **Not declared:** `Attachable`, `ReminderEnabled`, `CalendarAware`, `AIAnalyzable` — each of those corresponds to an explicitly out-of-scope capability (§2.1); declaring them with no owning feature behind them would be misleading. If a future milestone brings any of these into scope, the capability is added then, not speculatively now.

### 5.2 Aggregate boundary — no owned children

Per §4, `Task` owns no child entities and is never itself owned by a container entity.

### 5.3 Validation Rules

`[Decided this pass, mirroring DOC-031 §4.9's validation style]`

**Task:**
- `title`: required, 1–200 characters (mirrors Finance's `Payee.name` bound of 200 characters — the closest existing precedent for a short user-entered text field — rather than Finance's `Account.name` bound of 100, since a task title is closer in nature to free descriptive text than an account label), must not be only whitespace.
- `description`: optional; if provided, max 1000 characters (mirrors `Transaction.note`'s bound exactly, DOC-031 §4.9).
- `dueDate`: optional; if provided, no range restriction is imposed (unlike Finance's `TransactionDate`, which rejects dates more than 30 days in the future — that rule exists because a *future-dated financial transaction* is a plausible data-entry error; a task with a due date far in the future is not an analogous error, so this Finance-specific rule is deliberately **not** copied).
- `status`: must be one of the four approved `TaskStatus` values (§6.1); no other transition target is valid (§11).

---

## 6. Value Objects

### 6.1 TaskStatus

`[Decided this pass]` A domain-owned enum, not an opaque platform reference (§3).

```
enum TaskStatus { todo, inProgress, completed, archived }
```

Stored value convention mirrors Finance's `AccountType`/`TransactionType` (DOC-031 §6.2: `type.name` stored as the column string) — i.e. persisted as `'todo'`, `'inProgress'`, `'completed'`, `'archived'` (Dart enum `.name`), not the underscored spelling used in this decision's prose (`todo`, `in_progress`, `completed`, `archived`); the underscored spelling is the product-level vocabulary, the camelCase `.name` is the Dart/storage convention already used throughout Finance. This is a naming-convention note, not a scope decision.

### 6.2 TaskDueDate

`[Decided this pass]` Wraps `DateTime`. Unlike Finance's `TransactionDate`, it carries **no** "not more than N days in the future" business rule (see §5.3) — the only Finance-style validation that transfers is "must be a valid `DateTime`." No minimum-date validation (e.g. "not before 1970") is asserted as a requirement; it may be added mechanically at implementation time as a defensive `DateTime` sanity bound if the implementer judges it useful, but it is not a business rule this document mandates.

### 6.3 TaskId

`[Derived: Feature_Template.md / DOC-031 convention]` Typed wrapper around `String` (UUID), identical in spirit to `AccountId`/`TransactionId`.

### 6.4 Value objects explicitly not introduced

`TaskPriority`, `TaskCategory`, `TaskLabel`, `TaskAttachment`, `RecurrenceRule`, `ReminderConfig`, `Subtask` — none exist, per §2.1.

---

## 7. Repository Contracts

`[Decided this pass]` One repository, mirroring the one-aggregate decision in §4.

### 7.1 ITaskRepository

```
findById(TaskId)                        → Result<Task>
findAll(workspaceId)                    → Result<List<Task>>
findByStatus(workspaceId, TaskStatus)   → Result<List<Task>>
search(workspaceId, TaskQuery)          → Result<TaskPage>
save(Task)                              → Result<Task>          // insert or update
softDelete(TaskId)                      → Result<void>
```

This mirrors `IAccountRepository`'s minimal CRUD shape (DOC-031 §4.5) plus one query method mirroring `ITransactionRepository.query`/`TransactionQuery`/`TransactionPage` (DOC-031 §4.5), because `SearchTasks` (§12) needs a filtered, paginated read path the same way Finance's transaction list does — a plain unpaginated `findAll` is not sufficient once search-by-title exists.

`TaskQuery` (value object — filter parameters, mirroring `TransactionQuery`):
- `status?`, `titleContains?`, `pageIndex`, `pageSize`

`TaskPage` (value object, mirroring `TransactionPage`):
- `items: List<Task>`, `totalCount: int`, `hasNextPage: bool`

**No `saveTransferPair`-equivalent atomic multi-row method** — nothing in Tasks spans two rows (§8: no domain service needed for the same reason).

**No restore method.** Finance itself defines no restore-from-soft-delete use case or repository method (verified against the current Finance implementation before writing this document — `DeleteAccountUseCase`/`DeleteTransactionUseCase` are one-directional soft deletes with no counterpart). Per this pass's explicit instruction ("RestoreTask only if Finance already supports restore semantics"), `RestoreTask` and any repository restore method are **not** included.

---

## 8. Domain Services

`[Decided this pass]` **None.** Finance's domain services exist because Finance has cross-entity computation (`BalanceCalculationService` sums a Transaction history) or a multi-step invariant spanning two rows (`TransferService`). Tasks has neither: no aggregable numeric field, no multi-row invariant, no cross-entity computation. This resolves v0.1 §8 ("none proposed, contingent on undecided fields") — the fields are now decided, and none of them implies a domain service.

---

## 9. Domain Events

`[Decided this pass]` Mirroring Finance's one-event-per-lifecycle-transition pattern (DOC-031 §4.7), now with full payloads since the fields are fixed:

```
TaskCreated
  taskId, workspaceId, title, status, dueDate?, timestamp

TaskUpdated
  taskId, workspaceId, title, status, dueDate?, timestamp

TaskCompleted
  taskId, workspaceId, completedAt, timestamp

TaskArchived
  taskId, workspaceId, timestamp

TaskDeleted
  taskId, workspaceId, timestamp
```

`TaskCompleted` is split out as its own event (rather than folded into a generic `TaskUpdated`) because DOC-002 names it explicitly as a vision-level example event, and because completion is a business-meaningful transition with its own timestamp field (`completedAt`) — mirroring why Finance has `TransferCreated` as a distinct event from a plain `TransactionCreated`, even though a transfer leg is "just" a Transaction. `TaskArchived` is added for the same reason: archiving is a distinct, terminal, business-meaningful transition (§11), not an ordinary field update.

---

## 10. Business Rules

`[Decided this pass]` Mirroring DOC-031 §4.8's enforceable-invariant format:

1. **Title is required and non-empty.** A Task cannot be created or updated with an empty or whitespace-only title. Enforced by the `title` validation rule (§5.3).

2. **Status must be one of the four approved values.** No other value may ever be persisted. Enforced by the `TaskStatus` enum construction — invalid values cannot exist as a matter of typing, not just validation.

3. **Status transitions are restricted** — see the full transition table in §11. An attempt to move to a status not reachable from the current one must be rejected by the domain layer (not merely discouraged in the UI). This is the Tasks-domain equivalent of Finance's Business Invariant 1 (currency immutability) — a structural constraint the entity must never violate, not a validation hint.

4. **`completedAt` is set if and only if `status == completed`.** Transitioning into `completed` sets `completedAt` to the transition time. Transitioning a `completed` task onward to `archived` (§11) **retains** the existing `completedAt` value — archiving a completed task does not erase the record of when it was completed. A task that is archived directly from `todo` or `in_progress` (without ever passing through `completed`) has `completedAt == null` — archiving is not a form of completion.

5. **Archived is terminal.** Once `status == archived`, no further status transition is permitted, in either direction. This mirrors the *spirit* of Finance's Business Invariant 5 ("an Account with active Transactions cannot be hard-deleted" — some states are one-way) without copying Finance's specific rule.

6. **Soft delete, mirroring Finance exactly.** Deleting a Task is a soft delete (`ITaskRepository.softDelete`), identical in mechanism to `IAccountRepository.softDelete`/`ITransactionRepository.softDelete` (DOC-031 §4.5, §6.2's `is_deleted` column pattern). This is a **separate** mechanism from archiving (§11) — soft-deleted tasks are excluded from all live queries entirely (mirroring Finance's Business Invariant 6), whereas archived tasks remain queryable (e.g. `findByStatus(archived)`) and simply represent a Task the user has chosen to stop actively tracking. Do not conflate the two: `archived` is a visible `TaskStatus` value; `is_deleted` is an invisible repository-level flag, exactly as Finance already separates these two concerns for Accounts and Transactions.

---

## 11. Lifecycle / State Transitions

`[Decided this pass]` `TaskStatus` transition table, as specified:

```
todo          → in_progress, completed, archived
in_progress   → completed, archived
completed     → archived
archived      → (none — terminal)
```

Rendered as a diagram:

```
        ┌──────┐
        │ todo │──────────────┬───────────────┐
        └──┬───┘               │               │
           │                   │               │
           ▼                   ▼               ▼
     ┌──────────────┐    ┌───────────┐   ┌──────────┐
     │ in_progress  │───▶│ completed │──▶│ archived │
     └──────┬───────┘    └─────┬─────┘   └──────────┘
            │                  │               ▲
            └──────────────────┴───────────────┘
```

Notes:
- `todo → completed` directly (skipping `in_progress`) is **allowed** — `in_progress` is an optional intermediate signal, not a mandatory gate, per the transition table as given.
- `todo → archived` and `in_progress → archived` are **allowed** — a task can be dismissed without ever completing it.
- There is **no** transition out of `archived`, in any direction, including back to `todo` (explicitly stated in the decision: "Archived tasks cannot transition back").
- There is **no** transition directly reversing `completed → in_progress` or `completed → todo` ("reopening") — only `completed → archived` is defined. Reopening a completed task is therefore **not supported** by this domain model as decided. `[Requires Architecture Approval — minor, non-blocking]` if product intent is that a user should be able to "un-complete" a task, that is a distinct future decision; it is not assumed here because it was not included in the approved transition table.

This is enforced at the domain layer (a `Task.transitionTo(TaskStatus)` method, or equivalent, on the entity itself — mirroring DOC-007's "no business logic in entities" tension the same way Finance resolves it: simple invariant checks like "amount must be positive" live in the value object/entity constructor, per DOC-031 §4.2/§4.8; a transition-legality check is the direct Tasks analogue and belongs in the same place, not in a use case or ViewModel).

---

## 12. Application Use Cases

`[Decided this pass]` Exactly the list given, no more:

| Use Case | Input | Output | Notes |
|---|---|---|---|
| `CreateTaskUseCase` | title, description?, dueDate? | Task | New tasks always start at `status = todo`. Validates title (§5.3). |
| `UpdateTaskUseCase` | taskId, title?, description?, dueDate? | Task | Does **not** accept `status` — status changes go through the dedicated use cases below, mirroring Finance's `UpdateAccountUseCase` rejecting currency as an input (DOC-031 §4.6) — a deliberate narrowing of what a generic "update" is allowed to touch. |
| `CompleteTaskUseCase` | taskId | Task | Transitions to `completed`; sets `completedAt`. Rejects if current status is `archived` (§11). |
| `ArchiveTaskUseCase` | taskId | Task | Transitions to `archived` from any non-archived status. Rejects if already `archived` (no-op is not silently accepted — mirrors Finance's pattern of explicit precondition failures, e.g. `DeleteAccountUseCase` failing loudly rather than silently succeeding on an invalid precondition). |
| `DeleteTaskUseCase` | taskId | void | Soft delete (§10.6). No precondition beyond existence — unlike Finance's `DeleteAccountUseCase` (which checks for active transactions), nothing about a Task's own fields creates a cross-entity precondition, per §4/§8. |
| `GetTaskUseCase` | taskId | Task | Mirrors `GetAccountByIdUseCase`. |
| `GetTasksUseCase` | workspaceId | List\<Task\> | Mirrors `GetAccountsUseCase`. Returns all non-deleted tasks regardless of status (archived tasks are not hidden by this use case — filtering by status is `SearchTasks`'s job, not this one's, mirroring how Finance's `GetAccountsUseCase` returns active accounts and leaves further filtering to the caller). |
| `SearchTasksUseCase` | workspaceId, TaskQuery | TaskPage | Mirrors `QueryTransactionsUseCase`; paginated, filterable by status and title. |

**`RestoreTaskUseCase` is not included** — see §7's reasoning (Finance has no restore semantics to mirror).

**No summary/aggregation use cases** (no `GetTaskPriorityBreakdownUseCase` or equivalent) — nothing in the entity is aggregable the way Money is, per §8.

---

## 13. Storage Model

`[Decided this pass]` Mirrors Finance's persistence approach exactly (DOC-031 §6.1–§6.3), scoped to Tasks' single table.

### 13.1 Repository implementation

`TaskRepositoryImpl` implements `ITaskRepository`, following the exact same internal-only-contract rule as Finance (DOC-031 §6.1): never exported from the Tasks public barrel, registered by `TasksModule`.

### 13.2 Schema

```
tasks
  task_id                  TEXT     PRIMARY KEY
  workspace_id             TEXT     NOT NULL
  title                    TEXT     NOT NULL
  status                   TEXT     NOT NULL       -- TaskStatus.name
  description              TEXT                    -- nullable
  due_date                 TEXT                    -- nullable; ISO 8601 date
  completed_at             TEXT                    -- nullable; ISO 8601 datetime
  is_deleted               INTEGER  NOT NULL       -- 0/1 soft delete (§10.6)
  created_at               TEXT     NOT NULL       -- ISO 8601
  updated_at               TEXT     NOT NULL
```

No `amount_minor`-style integer conversion is needed (Tasks has no monetary field) — this is the one structural piece of DOC-031 §6.2 that does not transfer, because it exists specifically to solve Money's precision problem, which Tasks does not have.

### 13.3 Offline-first, event publishing

Identical to Finance (DOC-031 §6.3): local storage is the single source of truth; all reads are local; writes persist locally first, then publish domain events via `IEventBus`.

### 13.4 Demo Mode storage seam

`[Decided this pass]` Reuse the existing Milestone 6 architecture exactly, at the *principle* level: a switchable executor/runner pair sits between `TaskRepositoryImpl`'s DAO and the concrete storage engine, swapped by the same `DemoModeController` Finance already uses, so Tasks demo data lives in a separate in-memory store that can never touch real Task rows — identical guarantee to Finance's.

`[Requires Architecture Approval — minor, mechanical, non-blocking]` The *exact class* used for that seam is an open naming/reuse detail, not a domain question: today's `SwitchableFinanceDatabaseExecutor`/`SwitchableFinanceTransactionRunner` are named after Finance specifically. Whether Tasks reuses those same classes generalized (e.g. renamed to drop "Finance"), or a structurally-identical pair is introduced for Tasks' own `IFinanceDatabaseExecutor`-equivalent interface, is an implementation-time naming decision with no domain consequence either way. This is downgraded from v0.1's Decision D5 (previously listed as a first-class architecture blocker) to a minor implementation note, because the *behavior* required — no module-specific demo infrastructure, no `if (demoMode)` branching, repositories unaware of demo state — is fully decided and unambiguous; only a class name is left open.

---

## 14. Demo Data Strategy

`[Decided this pass]` Mirrors `DemoFinanceSeedData` exactly in mechanism: a seed function inserts realistic sample rows directly into a fresh in-memory store via the same executor seam, run by `DemoModeController.enableDemoMode()`/`resetDemoData()` — no `DemoTaskRepository`, `TaskDemoDatabase`, or `TaskDemoService` (explicitly prohibited, consistent with "repositories never branch on Demo Mode").

Sample content, now that fields are fixed: realistic task titles across a mix of statuses (some `todo`, some `in_progress`, some `completed` with a `completedAt` in the past few days, none `archived` by default — archived is a user action, not a natural seed state) and a mix of tasks with and without due dates (some overdue, some upcoming, some none) — mirroring Finance's demo data mixing multiple categories/dates/merchants for realism (Milestone 6). Exact sample copy is an implementation detail, not an architecture decision, exactly as Finance's specific merchant names were.

---

## 15. Home Dashboard Integration

`[Decided this pass]` Reuses the exact mechanism Finance already established (Milestone 5): a `ModuleCard`-based summary card resolved via DI, plus a quick action, wired into the existing `HomeDashboardPage` — no redesign of Home.

Card content, per this pass's explicit instruction:
- **Task count** — total non-deleted, non-archived tasks (mirrors Finance's balance figure being the headline number on its card).
- **Completed today** — count of tasks whose `completedAt` falls on the current calendar date.
- **Quick add action** — a `QuickActionButton` (mirroring Finance's Home quick actions) that opens task creation.

A `TasksHomeViewModel`-equivalent (mirroring `FinanceHomeViewModel`) supplies this summary data to the `ModuleCard`, resolved from `GetTasksUseCase`/`SearchTasksUseCase` — no new summary use case is required beyond what §12 already lists (the counts are computed presentation-side from the returned list, mirroring how `FinanceDashboardData` is assembled presentation-side from several use case results rather than by a dedicated summary use case for every single figure).

---

## 16. Open Questions / Architecture Decisions Required

Every decision raised in v0.1 (D1–D7) is resolved by this pass. Two items remain, both explicitly downgraded from "blocking" status:

### 16.1 Remaining items (non-blocking)

| # | Item | Why it's not a blocker |
|---|---|---|
| **D8 (carried over)** | DOC-029 does not list Tasks in its MVP Scope or Prioritized Backlog. | Administrative housekeeping — updating a backlog document — not a domain-modeling question. It does not change any entity, rule, or contract in this document. Recommended to be fixed alongside implementation kickoff, not before it. |
| **D5 (downgraded, see §13.4)** | Exact class-naming/reuse strategy for the Demo Mode switchable-executor seam. | The *behavior* is fully decided (reuse the existing architecture exactly, no module-specific demo classes). Only a class name/generalization detail is open, with no effect on the domain model, and it can be resolved by whoever writes the code following existing convention, without further architecture review. |

### 16.2 One genuinely open, non-blocking product question

`[Requires Architecture Approval — minor, non-blocking, noted in §11]` Whether a `completed` task can ever be reopened (moved back to `todo`/`in_progress`) is not supported by the approved transition table. If this turns out to be a real product need, it is a future, separate decision — implementation should proceed on the assumption that it is **not** supported, per the transition table as given.

---

## Architecture Traceability Table (updated)

| Section | Classification |
|---|---|
| §2.1 MVP scope (in/out) | Decided this pass |
| §3 Ubiquitous Language — Task, TaskStatus, Completion, Archiving | Decided this pass |
| §3 Status ownership (domain-owned, not Classification-owned) | Decided this pass — resolves D1 |
| §4 Aggregate Root — standalone Task, no Project/List/Board | Decided this pass — resolves D3 |
| §5 Entity fields (full list) | Decided this pass — resolves v0.1 §5 |
| §5 Capabilities declared/not declared | Decided this pass |
| §6 Value Objects — TaskStatus, TaskDueDate, TaskId | Decided this pass — resolves relevant part of v0.1 §6 |
| §7 Repository Contract — `ITaskRepository`, `TaskQuery`, `TaskPage` | Decided this pass |
| §7 No restore method | Decided this pass (verified against actual Finance implementation) |
| §8 Domain Services — none needed | Decided this pass |
| §9 Domain Events — full catalog | Decided this pass |
| §10 Business Rules — full list | Decided this pass |
| §11 Lifecycle — full transition table | Decided this pass |
| §12 Use Case Catalog — full list, `RestoreTask` excluded | Decided this pass |
| §13 Storage Model — schema | Decided this pass |
| §13.4 Demo Mode class-naming detail | Requires Architecture Approval — minor, non-blocking (D5, downgraded) |
| §14 Demo Data Strategy — mechanism and content approach | Decided this pass |
| §15 Home Dashboard Integration — card content | Decided this pass |
| §16.1 DOC-029 backlog update | Requires Architecture Approval — administrative, non-blocking (D8, carried over) |
| §16.2 Reopening a completed task | Requires Architecture Approval — minor, non-blocking, future product question |

---

## Architecture Decision List (remaining — none block implementation)

1. **D8 (administrative)** — Update DOC-029 to list Tasks and its priority. Does not block implementation.
2. **D5 (mechanical, downgraded)** — Class-naming strategy for the shared Demo Mode executor seam. Does not block implementation; resolvable by the implementer following existing convention.
3. **Reopening completed tasks (future product question)** — Not supported by the current transition table; would require a future decision if product need arises. Does not block implementation of the approved MVP.

---

## Implementation Readiness Assessment

## READY FOR IMPLEMENTATION

**Justification:**

- Every section that DOC-031 needed filled in before Finance's Sprint 8A began (entity fields, value objects, business invariants, lifecycle/state transitions, repository contract, use case catalog, storage schema, demo data strategy, Home Dashboard integration) is now fully specified for Tasks, at the same level of rigor and with the same tracing-to-source discipline DOC-031 itself models.
- All eight decisions (D1–D8) raised in v0.1 are addressed: D1, D2, D3, D4, D6, D7 are fully resolved with no remaining ambiguity; D5 is resolved in behavior and downgraded to a non-blocking naming detail; D8 is explicitly carried forward as administrative housekeeping that does not affect the domain model.
- The two items remaining in §16 are, by their own description, non-blocking: one is a documentation-housekeeping task (D8), one is a mechanical implementation-time naming choice with no domain consequence (D5), and one is an explicitly-out-of-scope future product question (reopening) that the approved transition table already answers by omission ("not supported").
- No aspect of the approved MVP domain model depends on any of the three remaining items being resolved first.

**Recommended next step**, mirroring DOC-031 §12's own roadmap pattern: a "Tasks Domain (Pure Dart)" pass — value objects, `Task` entity, `ITaskRepository` interface, no storage, no UI, no Flutter — analogous to Finance's Sprint 8A, followed by storage, DI/module wiring, and presentation passes in that order, each gated on `flutter analyze`/`flutter test` passing before the next begins, exactly as Finance's roadmap was structured.

No implementation, Flutter code, or package scaffolding has been produced as part of this task, per instruction.
