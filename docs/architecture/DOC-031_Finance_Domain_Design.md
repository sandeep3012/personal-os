# DOC-031 — Finance Domain Design

**Version:** 1.1
**Status:** Architecture Approved — Sprint 8A Ready
**Category:** Feature Domain
**Sprint:** Sprint 8 — Domain Discovery & Design
**Reviewed:** Sprint 8 Architecture Review — Decisions 1–4 applied
**Depends on:** DOC-001, DOC-002, DOC-005, DOC-006, DOC-007, DOC-009, DOC-010, DOC-011, DOC-017, DOC-029, Feature_Template.md, Package_Dependency_Matrix.md

---

## 1. Finance Domain Overview

### 1.1 What Finance Is

Finance is a Personal OS **financial awareness module** — not accounting software, not a bank integration portal, not an investment tracker. It is the part of the personal life management platform that answers three questions:

> *Where is my money right now? Where did it go? Where is it coming from?*

DOC-001 names AI's role explicitly as **Financial Advisor**. Finance is the domain that provides the data that role advises against. DOC-029 names Finance as a P1 priority alongside Storage — the most important business feature in the platform.

### 1.2 What Finance Is Not

| What people might expect | Design decision | Reason |
|---|---|---|
| Accounting / double-entry bookkeeping | Out of scope | Personal OS is a life platform, not an ERP |
| Bank/card API synchronisation | Out of scope (v1) | Deferred to platform_services/platform_sync |
| Investment portfolio management | Out of scope (v1) | Separate sub-domain; too complex |
| Payroll / tax calculation | Out of scope | Accounting concept |
| Enterprise budget approval workflows | Out of scope | Not personal |
| Built-in receipt OCR | Out of scope (v1) | Platform AI capability; Finance declares `Attachable` |

### 1.3 Context in the Personal OS Vision

Finance entities (accounts, transactions) are first-class citizens in the platform ecosystem. They are **Searchable**, **Taggable**, **Linkable**, **TimelineEnabled**, and **Attachable** via the platform Capability System (DOC-005). Finance only implements the money domain itself — the platform handles everything cross-cutting.

---

## 2. Ubiquitous Language

These terms are canonical inside the Finance bounded context. All code, tests, and documentation must use exactly these names.

| Term | Definition |
|---|---|
| **Account** | A financial vessel where money lives. Examples: cash wallet, bank checking account, savings account, credit card. An Account belongs to one Workspace. |
| **Balance** | The current net monetary value of an Account. Computed as `initialBalance + sum(income) − sum(expenses) − sum(transfer debits) + sum(transfer credits)`. |
| **Transaction** | A single record of money moving in, out, or between Accounts. The central entity of the Finance domain. Every Expense, Income, and Transfer leg is a Transaction. |
| **Expense** | A Transaction of type `expense` — money leaving an Account. Amount is always stored as positive; direction is implied by type. |
| **Income** | A Transaction of type `income` — money entering an Account. |
| **Transfer** | A movement of money from one Account to another within the same Workspace. Creates two Transactions atomically: a debit (expense) on the source Account and a credit (income) on the destination Account. |
| **Money** | An immutable value object combining a positive decimal amount and a currency code. |
| **Currency** | An ISO 4217 three-letter currency code (e.g. `USD`, `EUR`, `INR`). Stored on every Account and Transaction. |
| **Payee** | Who received or sent the money. A value object on a Transaction — not a tracked entity in MVP. Example: "Swiggy", "Employer", "Sandeep". |
| **Category** | A classification applied to a Transaction (e.g. Food, Transport, Salary). Owned by the platform Classification Service. Finance stores only a `categoryId` reference — an opaque string. |
| **Period** | A calendar month expressed as `(year, month)`. Used for summaries and future budgets. |
| **Initial Balance** | The starting balance set when an Account is created. Represents historical balance before the user began tracking in Personal OS. |
| **Workspace** | The isolation boundary from DOC-002. Every Finance entity belongs to exactly one Workspace. |
| **Finance Module** | The `FeatureModule` subclass that registers Finance into the Personal OS runtime. |

---

## 3. Capability Classification

### 3.1 Core MVP

These must be in the first Finance implementation.

| Capability | Justification |
|---|---|
| **Accounts** | The foundation. Without accounts, transactions have nowhere to live. DOC-029 explicit. |
| **Expenses** | DOC-029 explicit. Primary user interaction — recording where money goes. |
| **Income** | DOC-029 explicit. Required for net position calculation. Without income, balance can only decrease. |
| **Transfers** | Money moves between accounts constantly (savings → checking before a purchase). Without transfers, users must manually create an expense on one account and income on another with no relationship between them — this produces incorrect balances and a poor UX. Transfers are not in DOC-029 but are a **prerequisite for correct balance tracking**. Promoted to Core MVP. |
| **Currency on entities** | DOC-007 names Currency as a business data field. Every Account and Transaction must record its currency. Multi-currency reporting can be deferred but the data model must be currency-aware from day one — retrofitting it later requires a schema migration on every existing record. |
| **Payee (value object)** | Needed for basic expense entry UX. Implemented as a simple value object (name string), not a tracked entity. |
| **Categories (reference)** | DOC-029 explicit. Finance stores `categoryId`; platform owns category data. Seeding default Finance categories at startup (Food, Transport, Salary, etc.) is part of the Finance `StartupStep`. |
| **Tags (capability declaration)** | DOC-029 explicit. Finance entities declare `Taggable`; the platform Tag service manages tag assignment. No Finance-specific storage. |
| **Attachments (capability declaration)** | DOC-029 explicit (receipts). Finance entities declare `Attachable`; the platform Attachment Service stores files. Finance stores attachment reference IDs on Transactions. |

### 3.2 Future

These are valid features but are explicitly excluded from MVP.

| Capability | Justification for deferral |
|---|---|
| **Budgets** | Adds significant domain complexity (budget periods, carry-over, shared budgets). Valuable but non-essential for basic tracking. Deferred to Sprint 8E or a dedicated sprint. |
| **Recurring Transactions** | Requires scheduling infrastructure (Calendar integration, platform_services scheduler). Finance should not own a scheduler. Deferred until Calendar integration is available. |
| **Payee Entity (tracked)** | Upgrading Payee from value object to entity (with history, contact linking) requires Entity Linking integration. Deferred. |
| **Multi-currency reporting** | Storing currency per transaction is MVP. Converting across currencies for unified summaries requires exchange rate data. Deferred to a platform_sync / platform_services integration. |
| **Savings Goals** | Intersects heavily with a future Goals feature. Finance publishes events; Goals feature will compute progress. Deferred to prevent feature overlap. |
| **Loans / Debt tracking** | Adds loan amortization, interest calculations, payment schedules. A distinct sub-domain. Deferred. |
| **Scheduled Payments** | Overlaps with Calendar and Notifications. Finance publishes events; the platform handles scheduling. Deferred. |
| **Reports / Analytics** | Platform Analytics Service (DOC-003) responsibility. Finance exposes data via use cases; Analytics aggregates. Deferred to Sprint 8E. |
| **Splits** | Splitting a single expense across multiple categories. UX complexity high; low frequency for personal use. Deferred. |

### 3.3 Out of Scope

These will never be part of the Finance feature package.

| Capability | Reason |
|---|---|
| **Investments** | Separate domain with different entity model (securities, shares, prices, portfolio) |
| **Tax calculation** | Accounting/legal domain, jurisdiction-specific |
| **Bank API sync** | Platform infrastructure (platform_sync, platform_services) — not Finance domain |
| **Multi-user / shared accounts** | Collaboration feature; Personal OS v1 is single-user |
| **Double-entry bookkeeping** | Enterprise accounting concept; out of product philosophy |
| **Payment processing** | External system integration; not a personal OS responsibility |

---

## 4. Domain Model

### 4.1 Entities

#### Account

The financial vessel. Aggregate root.

| Field | Type | Notes |
|---|---|---|
| `accountId` | AccountId | Typed UUID wrapper |
| `workspaceId` | String | Workspace isolation boundary |
| `name` | String | Display name, e.g. "HDFC Savings" |
| `type` | AccountType | Enum: `cash`, `checking`, `savings`, `creditCard`, `loan` |
| `currency` | CurrencyCode | ISO 4217; immutable after creation |
| `initialBalance` | Money | Historical starting balance; set once |
| `isActive` | bool | Soft-disable without deleting |
| `entityType` | String | `'account'` — for platform capability system |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

**Capabilities declared:** Searchable, Linkable, Taggable, TimelineEnabled

#### Transaction

The central entity. Every Expense, Income, and Transfer leg is a Transaction. Aggregate root.

| Field | Type | Notes |
|---|---|---|
| `transactionId` | TransactionId | Typed UUID wrapper |
| `workspaceId` | String | Workspace isolation |
| `accountId` | AccountId | Which account this affects |
| `type` | TransactionType | Enum: `expense`, `income`, `transfer` |
| `amount` | Money | Always positive; type determines direction |
| `categoryId` | CategoryId? | Nullable; reference to platform Classification |
| `payee` | Payee | Value object; who sent/received money |
| `note` | String? | Free text; nullable |
| `date` | TransactionDate | The date the transaction occurred |
| `transferCounterpartId` | TransactionId? | The other leg of a Transfer; null for expense/income |
| `entityType` | String | `'transaction'` — for platform capability system |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

**Capabilities declared:** Searchable, Taggable, Linkable, Attachable, TimelineEnabled, AIAnalyzable

---

### 4.2 Value Objects

#### Money
- `amount`: Decimal (non-negative; precision to 2 decimal places for fiat, up to 8 for future crypto)
- `currency`: CurrencyCode
- Arithmetic: `add(Money)`, `subtract(Money)` — both return new Money; subtract enforces same currency
- Equality: two Money values are equal when amount and currency are both equal

#### CurrencyCode
- `code`: String — must match ISO 4217 (3 alphabetic characters, uppercase)
- Examples: `USD`, `EUR`, `INR`, `GBP`, `JPY`
- Invariant: validated at construction; no mutation

#### AccountId
- Typed wrapper around String (UUID)
- Prevents passing raw strings as account references

#### TransactionId
- Typed wrapper around String (UUID)

#### CategoryId
- Typed wrapper around String
- Treated as an opaque reference — Finance never validates its contents against a category store

#### AccountType
- Enum: `cash`, `checking`, `savings`, `creditCard`, `loan`
- `creditCard` and `loan` types may have a negative balance

#### TransactionType
- Enum: `expense`, `income`, `transfer`

#### Payee
- `name`: String — who sent or received the money
- Validates: non-empty, max 200 characters, trimmed
- Value object — no ID, not tracked across transactions in MVP

#### TransactionDate
- Wraps DateTime
- Validates: not before 1970-01-01, not more than 30 days in the future
- Business rule: future-dating transactions beyond 30 days is likely a data entry error

#### FinancePeriod
- `year`: int
- `month`: int (1–12)
- Used for period-based queries and future budget periods
- Provides: `previous()`, `next()`, `contains(DateTime)` logic

---

### 4.3 Aggregate Roots

| Aggregate | Root Entity | Invariant boundary |
|---|---|---|
| **Account** | Account | Currency is immutable after creation; balance is always computable from its transaction history |
| **Transaction** | Transaction | Amount is always positive; type determines direction; transfer pair is always persisted atomically |

Account does NOT own a collection of Transactions. Transactions reference their Account by `accountId`. This boundary is deliberate:

- **Performance:** Loading account metadata (name, currency, balance display) never requires pulling the full transaction history into memory. An account may accumulate thousands of transactions over years — the aggregate boundary ensures each load is O(1), not O(n).
- **Pagination:** Filtering, date-range queries, and paginated transaction lists are performed at the repository level without traversing an Account aggregate.
- **Transfer atomicity:** `saveTransferPair(debit, credit)` on `ITransactionRepository` is the consistency boundary for Transfers. The invariant — both legs persist together or neither does — is enforced by a single database transaction in the repository implementation. It does not require both Account aggregates to be loaded simultaneously.
- **Independent lifecycle:** Each Transaction aggregate is independently identifiable, independently soft-deletable, and independently auditable by the platform Timeline and Search services via domain events.

---

### 4.4 Domain Services

#### BalanceCalculationService
- Pure computation — no I/O, no side effects
- `calculateBalance(initialBalance, List<Transaction>) → Money`
- Business rule: expense transactions subtract, income transactions add, transfer debits subtract, transfer credits add, soft-deleted transactions are excluded

#### TransferService
- Creates both legs of a Transfer atomically
- `createTransferPair(fromAccountId, toAccountId, amount, currency, date, note?) → (debitTransaction, creditTransaction)`
- Invariant: `fromAccountId != toAccountId`
- Both transactions share the same `transferCounterpartId` pointing to each other
- The repository must persist both atomically; TransferService produces the pair for the use case to persist

#### CategorySummaryService
- `summarizeByCategory(List<Transaction>) → Map<CategoryId, Money>`
- Groups and sums expense transactions by category for a given period
- Pure computation; operates on data already fetched by the use case

---

### 4.5 Repository Contracts

Finance defines these interfaces. Implementations live in the `data/` layer (Sprint 8B).

#### IAccountRepository

```
findById(AccountId)             → Result<Account>
findAll(workspaceId)            → Result<List<Account>>
findActive(workspaceId)         → Result<List<Account>>
save(Account)                   → Result<Account>         // insert or update
softDelete(AccountId)           → Result<void>
```

Precondition on `softDelete`: the use case must verify no active transactions exist before calling this.

#### ITransactionRepository

```
findById(TransactionId)                             → Result<Transaction>
findByAccount(AccountId, {DateRange?})              → Result<List<Transaction>>
findByPeriod(workspaceId, FinancePeriod)            → Result<List<Transaction>>
findByCategory(workspaceId, CategoryId, {FinancePeriod?}) → Result<List<Transaction>>
query(workspaceId, TransactionQuery)                → Result<TransactionPage>
save(Transaction)                                   → Result<Transaction>
saveTransferPair(debit, credit)                     → Result<(Transaction, Transaction)>  // atomic
softDelete(TransactionId)                           → Result<void>
```

**TransactionQuery** (value object — filter parameters):
- `accountId?`, `categoryId?`, `type?`, `dateRange?`, `payeeNameContains?`, `pageIndex`, `pageSize`

**TransactionPage** (value object):
- `items: List<Transaction>`, `totalCount: int`, `hasNextPage: bool`

---

### 4.6 Use Case Catalog

All use cases return `Result<T>` and accept typed parameters. All implement `AsyncUseCase<Input, Output>` or `NoParamsUseCase<Output>` per the existing application framework.

#### Account Use Cases

| Use Case | Input | Output | Notes |
|---|---|---|---|
| `CreateAccountUseCase` | name, type, currency, initialBalance | Account | Validates name, currency, initialBalance ≥ 0 |
| `UpdateAccountUseCase` | accountId, name?, isActive? | Account | Cannot change currency after creation |
| `GetAccountsUseCase` | workspaceId | List\<Account\> | Returns active accounts only |
| `GetAccountByIdUseCase` | accountId | Account | |
| `DeleteAccountUseCase` | accountId | void | Fails if active transactions exist |
| `GetAccountBalanceUseCase` | accountId | Money | Computes via BalanceCalculationService |

#### Transaction Use Cases

| Use Case | Input | Output | Notes |
|---|---|---|---|
| `AddExpenseUseCase` | accountId, amount, currency, date, payee, categoryId?, note?, attachmentIds? | Transaction | Validates amount > 0, date range |
| `AddIncomeUseCase` | accountId, amount, currency, date, payee, categoryId?, note? | Transaction | Same validations as expense |
| `CreateTransferUseCase` | fromAccountId, toAccountId, amount, currency, date, note? | (Transaction, Transaction) | Calls TransferService; atomic save |
| `UpdateTransactionUseCase` | transactionId, amount?, categoryId?, payee?, date?, note? | Transaction | Cannot change type or account |
| `DeleteTransactionUseCase` | transactionId | void | Soft delete; reverses balance effect |
| `GetTransactionsByAccountUseCase` | accountId, dateRange? | List\<Transaction\> | |
| `GetTransactionsByPeriodUseCase` | workspaceId, period | List\<Transaction\> | All accounts for the period |
| `QueryTransactionsUseCase` | workspaceId, TransactionQuery | TransactionPage | Paginated filtered list |

#### Summary Use Cases

| Use Case | Input | Output | Notes |
|---|---|---|---|
| `GetTotalExpensesUseCase` | workspaceId, period | Money | Sum of expense transactions |
| `GetTotalIncomeUseCase` | workspaceId, period | Money | Sum of income transactions |
| `GetNetPositionUseCase` | workspaceId, period | Money | income − expenses for period |
| `GetCategorySummaryUseCase` | workspaceId, period | Map\<CategoryId, Money\> | Calls CategorySummaryService |

---

### 4.7 Domain Events

All events are immutable value objects extending `DomainEvent` (packages/application). Published by use cases **after successful persistence**. Subscribers: Timeline Service, Search Service, Notification Engine (when implemented).

```
AccountCreated
  accountId, workspaceId, name, type, currency, timestamp

AccountUpdated
  accountId, workspaceId, name, isActive, timestamp

AccountDeleted
  accountId, workspaceId, timestamp

TransactionCreated
  transactionId, workspaceId, accountId, type, amount, currency,
  categoryId?, payeeName, date, timestamp

TransactionUpdated
  transactionId, workspaceId, accountId, type, amount, currency,
  categoryId?, payeeName, date, timestamp

TransactionDeleted
  transactionId, workspaceId, accountId, type, timestamp

TransferCreated
  debitTransactionId, creditTransactionId, workspaceId,
  fromAccountId, toAccountId, amount, currency, date, timestamp
```

---

### 4.8 Business Invariants

These rules must never be violated. The domain layer enforces them; they are not validation UI hints.

1. **Account currency is immutable.** Once set, the currency of an Account cannot change. Changing it would invalidate all historic transaction amounts. `UpdateAccountUseCase` rejects currency as an input parameter.

2. **Transaction amount is always positive.** The `type` field determines direction. An amount of zero or negative must never be persisted. Enforced by Money value object constructor.

3. **Transfer legs are equal in amount and currency.** The debit and credit sides of a Transfer must have the same amount and currency. Cross-currency transfers require exchange rates — deferred to a future sprint. Enforced by TransferService.

4. **A Transfer cannot be to the same Account.** `fromAccountId != toAccountId`. Enforced by `CreateTransferUseCase`.

5. **An Account with active Transactions cannot be hard-deleted.** Use soft delete (`isActive = false`). Hard deletion is never supported in MVP — it would corrupt balance history. Enforced by `DeleteAccountUseCase`.

6. **Soft-deleted Transactions are excluded from all balance and summary calculations.** Repository implementations must never return soft-deleted records in live queries.

7. **A Transaction's date may not be more than 30 days in the future.** Prevents common data entry errors. Enforced by TransactionDate value object.

8. **Initial balance must be ≥ 0 for non-credit accounts.** `cash`, `checking`, `savings`, `loan` accounts start at zero or positive. `creditCard` may start at a negative initial balance (representing existing debt). Enforced by `CreateAccountUseCase` with AccountType context.

---

### 4.9 Validation Rules

These produce user-visible errors and live at the use case input layer using the existing `Validator<T>` / `ValidationResult` framework from `packages/application`.

**Account:**
- `name`: required, 1–100 characters, must not be only whitespace
- `currency`: required, valid ISO 4217 code
- `initialBalance`: ≥ 0 (for cash/checking/savings/loan); any value for creditCard
- `type`: must be a valid AccountType value

**Transaction:**
- `amount`: required, > 0, max 2 decimal places for fiat currencies
- `currency`: required, valid ISO 4217 code
- `date`: required, between 1970-01-01 and today + 30 days
- `payee.name`: optional; if provided: 1–200 characters
- `note`: optional; if provided: max 1000 characters
- `categoryId`: optional; treated as an opaque reference — not validated against platform store at the domain layer

**Transfer:**
- All Transaction rules apply to both legs
- `fromAccountId` ≠ `toAccountId`
- Both accounts must belong to the same `workspaceId`

---

## 5. Feature Boundaries

### 5.1 Belongs Inside Finance

- Account entity CRUD and lifecycle
- Transaction entity CRUD and lifecycle (expense, income, transfer)
- Balance calculation
- Period-based financial summaries (total expenses, total income, net position, category breakdown)
- Finance domain events
- Finance route constants and screens (presentation layer)
- **Finance default category seeds** — installed once during `FinanceStartupStep`. This is the only category write Finance ever performs. After seeding, Finance never creates, updates, or deletes categories. Category lifecycle belongs to the platform Classification Service.

#### Category Ownership Boundary

Finance stores `categoryId: CategoryId` on a Transaction — an **opaque reference string**. Finance does not know or validate what categories exist. Finance does not implement category CRUD. Finance does not maintain a local category list.

The platform Classification Service owns:
- Creating, renaming, and deleting category definitions
- Category hierarchy (if any)
- The global category index shared across all features

Finance's only interaction with categories:
- Storing a `categoryId` supplied by the user during transaction entry
- Seeding a set of Finance-appropriate default categories (Food, Transport, Salary, etc.) into the Classification Service during `FinanceStartupStep`. If the Classification Service is not yet available, seeds are stored as constants in Finance and applied when the service becomes available.
- Grouping transactions by `categoryId` for summary calculations (using `CategorySummaryService` — pure computation on the opaque IDs already stored).

### 5.2 Belongs Outside Finance

| Capability | Owner | Interface to Finance |
|---|---|---|
| **Budget alerts** | Notification Engine (platform) | Finance publishes `TransactionCreated`; a future Budget service or Automation Rule triggers the alert |
| **Recurring transactions** | Calendar feature + Automation Engine | Finance publishes events; platform Automation Engine schedules future transactions |
| **Savings goals** | Goals feature (future) | Goals feature subscribes to Finance events and computes progress |
| **Follow-up tasks** | Tasks feature | Tasks feature may link to transactions via Entity Linking Service |
| **Receipt files** | Platform Attachment Service | Finance stores `attachmentId` references only |
| **Notes attached to expenses** | Platform Entity Linking Service | A Note entity links to a Transaction entity; Finance does not own note content |
| **Tags** | Platform Classification Service | Finance entities declare `Taggable`; platform handles tag storage and global tag index |
| **Categories (storage)** | Platform Classification Service | Finance stores only `categoryId`; seeds initial Finance categories via StartupStep |
| **Search indexing** | Platform Search Service | Finance publishes events; Search Service indexes |
| **Timeline** | Platform Timeline Service | Finance publishes events; Timeline Service adds entries |
| **Reports / charts** | Platform Analytics Service | Finance exposes data via use cases; Analytics aggregates and visualises |
| **Exchange rate data** | Platform Services (future) | Finance stores per-transaction currency; conversion is a platform responsibility |
| **Scheduled payment reminders** | Calendar / Notification Engine | Finance publishes payment-related events; other services schedule reminders |

---

## 6. Storage Strategy

### 6.1 Repository Interfaces

Finance defines `IAccountRepository` and `ITransactionRepository` in its domain layer (`features/finance/lib/src/domain/repositories/`). These are **internal implementation contracts** — the interface layer through which Finance use cases communicate with the storage layer. They are not part of the Finance public API.

**External consumers must never depend on Finance repository interfaces.** The repository interfaces are not exported from the Finance barrel (`finance.dart`). No feature package, app layer module, or platform service may ever import `IAccountRepository` or `ITransactionRepository`. Doing so would couple an external consumer to Finance's internal storage contract — a coupling that breaks feature isolation (DOC-006) and prevents the storage implementation from being changed independently.

If an external consumer needs data that Finance manages, it must receive it through one of two approved channels:
- **Domain events** — Finance publishes `AccountCreated`, `TransactionCreated`, `TransferCreated`, etc. after each successful persistence. Platform services subscribe to these.
- **Finance public API** — use cases resolved via DI return typed entities (`Account`, `Transaction`, `Money`) as value results. The app layer calls these use cases; it does not reach into the repository layer.

`FinanceModule` registers concrete implementations into DI during `registerServices`. The domain layer never references concrete implementations.

### 6.2 Persistence Boundaries

Finance owns exactly two tables:

```
accounts
  account_id               TEXT     PRIMARY KEY
  workspace_id             TEXT     NOT NULL
  name                     TEXT     NOT NULL
  type                     TEXT     NOT NULL       -- AccountType string key
  currency                 TEXT     NOT NULL       -- ISO 4217
  initial_amount_minor     INTEGER  NOT NULL       -- minor currency units (e.g. paise, cents)
  initial_currency         TEXT     NOT NULL
  is_active                INTEGER  NOT NULL       -- 0/1
  is_deleted               INTEGER  NOT NULL       -- 0/1 soft delete
  created_at               TEXT     NOT NULL       -- ISO 8601
  updated_at               TEXT     NOT NULL

transactions
  transaction_id           TEXT     PRIMARY KEY
  workspace_id             TEXT     NOT NULL
  account_id               TEXT     NOT NULL       -- references accounts
  type                     TEXT     NOT NULL       -- TransactionType
  amount_minor             INTEGER  NOT NULL       -- minor currency units; always positive
  currency                 TEXT     NOT NULL
  category_id              TEXT                   -- nullable; opaque reference
  payee_name               TEXT                   -- nullable
  note                     TEXT                   -- nullable
  date                     TEXT     NOT NULL       -- ISO 8601 date
  transfer_counterpart_id  TEXT                   -- nullable; other leg of transfer
  is_deleted               INTEGER  NOT NULL       -- 0/1 soft delete
  created_at               TEXT     NOT NULL
  updated_at               TEXT     NOT NULL
```

**Amount persistence — INTEGER minor units (approved Sprint 8B strategy):**

All monetary amounts are stored as `INTEGER` representing the smallest unit of the relevant currency. The repository layer is responsible for converting between the domain's `Money` type (which carries a decimal amount) and the stored integer. Floating-point storage (`REAL`) is not used.

Conversion examples:

| Currency | Decimal places | Domain value | Stored integer |
|---|---|---|---|
| INR | 2 | ₹125.75 | 12575 |
| USD | 2 | $49.99 | 4999 |
| JPY | 0 | ¥100 | 100 |
| BHD | 3 | 0.100 BHD | 100 |

The currency's minor-unit scale (decimal places) is a fixed property of the ISO 4217 currency code. Sprint 8B must include a `CurrencyScale` lookup (a simple constant map) that the repository uses during conversion. The domain `Money` type remains a decimal value — storage representation is an implementation detail of the repository layer only.

**Platform owns:** tags, attachments, categories, timeline_entries, search_index. Finance never writes to these tables.

### 6.3 Offline-First Strategy

- Local SQLite is the single source of truth
- All reads go to local DB — no network call on the read path
- All writes persist locally first, then domain events are published via `IEventBus`
- Platform services (Search, Timeline) update asynchronously via event subscriptions
- The app remains fully functional when offline

### 6.4 Synchronisation (Future)

- `platform_sync` (not yet built) will handle cloud sync
- Finance implements no sync logic
- Events published by Finance use cases serve as the sync change log
- Conflict resolution: last-write-wins for simple field updates; flagged for user resolution when both devices modify the same entity

### 6.5 Attachment Handling

Finance stores `List<String> attachmentIds` on a Transaction. These are opaque references. The Platform Attachment Service owns the actual files and metadata. Finance never reads, writes, or validates file bytes.

### 6.6 Search Integration

After `TransactionCreated` / `TransactionUpdated` / `TransactionDeleted` events are published, the platform Search Service (when built) will index: payee name, note text, category name, account name, amount, and date. Finance maintains no search index.

---

## 7. Public API Surface

The public barrel (`features/finance/lib/finance.dart`) exports **only what external consumers require**.

### Exported

| Export | Reason |
|---|---|
| `FinanceModule` | App layer needs this for `RuntimeBootstrap` |
| `FinanceRoutes` | App layer needs route constants for `GoRoute` wiring |
| `FinancePage`, `AccountListPage`, `AccountDetailPage`, `AddTransactionPage`, `TransactionDetailPage` | App layer needs Flutter builders for GoRoute entries |
| `Account` | App layer needs this type for UI state |
| `Transaction` | App layer needs this type for UI state |
| `AccountType`, `TransactionType` | App layer needs these for UI filtering/display |
| `Money`, `CurrencyCode` | App layer needs these to display balance values |
| `AccountCreated`, `AccountUpdated`, `AccountDeleted` | Event bus consumers (future platform services) |
| `TransactionCreated`, `TransactionUpdated`, `TransactionDeleted`, `TransferCreated` | Event bus consumers |

### Not Exported (internal)

| Internal item | Reason |
|---|---|
| `IAccountRepository`, `ITransactionRepository` | **Internal contracts only.** No external feature, app module, or platform service may import Finance repositories. Cross-feature data flows through domain events or use case return values — never through repository calls. |
| `AccountRepositoryImpl`, `TransactionRepositoryImpl` | Concrete storage implementation; registered in DI by FinanceModule |
| DB models / mappers | Storage detail; coupling external code to these would break independent schema evolution |
| `BalanceCalculationService`, `TransferService`, `CategorySummaryService` | Domain services resolved via DI internally; external consumers receive computed results, not service instances |
| `AccountId`, `TransactionId` | No external consumer constructs Finance entity IDs; IDs travel as opaque strings in events |
| All use case classes | Use cases are resolved from DI; no consumer imports a use case type directly |
| `CurrencyScale` | Storage implementation detail; maps ISO 4217 codes to minor-unit decimal places |

**Cross-feature communication rule:** Features in Personal OS never import each other's packages. The approved channels are (a) domain events via `IEventBus` and (b) navigation via route constants. Minimising the Finance public API surface enforces this rule by making it structurally impossible to create an illegal dependency.

---

## 8. Bounded Context Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FINANCE BOUNDED CONTEXT                         │
│                                                                     │
│  ┌─────────────┐        ┌───────────────────────────────────────┐  │
│  │   Account   │        │              Transaction               │  │
│  │  (Aggregate)│◄───────│            (Aggregate)                 │  │
│  │             │        │  type: expense | income | transfer     │  │
│  │ - name      │        │  amount: Money                         │  │
│  │ - type      │        │  payee: Payee (VO)                     │  │
│  │ - currency  │        │  categoryId: CategoryId (VO/opaque)    │  │
│  │ - balance*  │        │  date: TransactionDate (VO)            │  │
│  └──────┬──────┘        └──────────────┬────────────────────────┘  │
│         │                              │                            │
│  ┌──────▼──────────────────────────────▼────────────────────────┐  │
│  │                    Domain Services                            │  │
│  │  BalanceCalculationService │ TransferService │ CategorySumSvc │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│  ┌───────────────────────────▼──────────────────────────────────┐  │
│  │                      Use Cases                               │  │
│  │  CreateAccount │ AddExpense │ AddIncome │ CreateTransfer     │  │
│  │  GetAccountBalance │ GetCategorySummary │ QueryTransactions  │  │
│  └───────────────────────────┬──────────────────────────────────┘  │
│                              │                                      │
│  ┌───────────────────────────▼──────────────────────────────────┐  │
│  │                   Repository Contracts                        │  │
│  │         IAccountRepository │ ITransactionRepository           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  * balance = computed, not stored as mutable state on entity        │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ Domain Events
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                          Event Bus                                    │
│  AccountCreated │ TransactionCreated │ TransferCreated │ ...          │
└──────┬──────────────────────┬──────────────────────────┬─────────────┘
       ▼                      ▼                          ▼
 Timeline Service        Search Service          Notification Engine
 (platform, future)     (platform, future)       (platform, future)
```

Platform capabilities Finance declares (owned by platform, not Finance):

```
 CategoryId ──────────────► Classification Service (platform)
 attachmentIds ───────────► Attachment Service (platform)
 [Taggable capability] ───► Tags Service (platform)
 [Linkable capability] ───► Entity Linking Service (platform)
 [Searchable capability] ─► Search Service (platform)
 [TimelineEnabled] ───────► Timeline Service (platform)
```

---

## 9. Risks

### R1 — Category ownership ambiguity (Medium)

**Problem:** Finance transactions reference categories, but the platform Classification Service that owns category storage is not built yet.

**Mitigation:** For MVP, Finance seeds default Finance categories into the platform Classification Service via its `StartupStep`. If the Classification Service is not yet available, Finance maintains a read-only local list of default category seeds as a constant value object (no storage). This avoids blocking Finance on Classification Service implementation.

### R2 — Balance calculation performance (Low now, Medium later)

**Problem:** Computing balance from all historical transactions is O(n). For a user with years of data, this becomes slow.

**Mitigation planned:** Sprint 8B introduces a `cached_balance` column on the `accounts` table. The repository updates it atomically with each transaction write. `GetAccountBalanceUseCase` reads the cached value; `BalanceCalculationService` is used only for validation and cold-cache computation. A full rebuild use case can recompute from scratch if the cache is ever suspected to be incorrect.

### R3 — Transfer atomicity (High — must resolve in Sprint 8B)

**Problem:** A Transfer creates two Transactions. If the first `INSERT` succeeds and the second fails, Account balance is corrupted.

**Mitigation:** `ITransactionRepository.saveTransferPair(debit, credit)` must execute inside a database transaction. This is a requirement on the concrete repository implementation. The repository contract makes atomicity explicit with a dedicated method rather than two separate `save()` calls.

### R4 — Floating-point amount precision (Resolved by design)

**Problem:** Storing Money as floating-point (`REAL`) in SQLite introduces precision errors for large amounts and currencies with non-standard decimal places (JPY = 0, BHD = 3, INR = 2).

**Resolution:** This risk is resolved at the architecture level. The approved Sprint 8B persistence strategy stores all amounts as `INTEGER` (minor currency units) from the first implementation. No floating-point storage will be introduced. No future migration is required. See §6.2 for the conversion strategy and currency scale map.

This is no longer an open risk. It is closed.

### R5 — Platform services not yet implemented (Low — design is safe)

**Problem:** Finance publishes events to the Event Bus. There are no subscribers yet.

**Mitigation:** Finance publishes via `IEventBus`; subscribers are independent. The absence of subscribers means events fire and are dropped, which is acceptable in development. No risk to Finance's own data integrity.

### R6 — Schema migration management (Medium)

**Problem:** As Finance evolves (adding budgets, recurring transactions), the SQLite schema must change without corrupting existing data.

**Mitigation:** The Finance `StartupStep` must include a schema version check and migration runner from day one. Even if Sprint 8B only has migration `v1`, the infrastructure must exist so future migrations can be added safely.

### R7 — Multi-currency reporting accuracy (Medium — deferred, data model is correct)

**Problem:** A user with USD and INR accounts cannot have expenses summed into a single number without exchange rates.

**Mitigation:** Summary use cases return per-currency breakdowns in MVP rather than a single converted total. The data model is currency-aware from day one. When exchange rate infrastructure is available (future), summary use cases can be extended.

---

## 10. MVP Scope

### Included in MVP

- `Account` entity: create, update, soft-delete, list, get-by-id, get-balance
- `Transaction` entity: add expense, add income, create transfer, update, soft-delete, list-by-account, list-by-period, paginated query
- `Money`, `CurrencyCode`, `Payee`, `TransactionDate`, `FinancePeriod` value objects
- `BalanceCalculationService`, `TransferService`, `CategorySummaryService` (pure domain logic)
- `IAccountRepository` and `ITransactionRepository` interfaces
- Concrete SQLite implementations (Sprint 8B)
- Finance default category seeds via StartupStep
- Domain events: full Account and Transaction lifecycle event set
- All 14 use cases listed in §4.6
- `FinanceModule` registering all of the above
- Basic screens: account list, account detail, transaction list, add expense/income, transfer
- Full unit test coverage of domain layer
- Full integration test coverage of repository implementations

### Excluded from MVP

- Budgets
- Recurring transactions
- Payee entity tracking
- Multi-currency conversion / unified reporting
- Reports / analytics screens
- Goals / savings targets
- Notification delivery (events are published; delivery infrastructure is future)
- Search indexing (events are published; indexing infrastructure is future)
- Timeline entries (events are published; timeline infrastructure is future)
- Cloud sync

---

## 11. Future Scope

| Feature | Sprint estimate | Dependencies |
|---|---|---|
| Budgets (per category, per period) | Sprint 9A | Finance domain complete |
| Recurring transactions | Sprint 9B | Calendar integration |
| Payee entity tracking (history, auto-complete) | Sprint 9C | Finance domain complete |
| Multi-currency reporting with exchange rates | Sprint 9D | platform_services (exchange rate provider) |
| Finance reports and charts | Sprint 8E | Analytics Service, ADR-004 |
| Savings goals | Sprint 10 | Goals feature |
| Bank sync / import | Sprint 11 | platform_sync, platform_services |
| Scheduled payment reminders | Sprint 9B | Notification Engine |
| Receipt OCR | Sprint 12 | platform_ai |
| Loan tracking | Sprint 10 | Finance domain v2 |

---

## 12. Recommended Implementation Roadmap

### Sprint 8A — Finance Domain (Pure Dart)

No storage. No UI. No Flutter. No DI wiring.

Deliverables:
- All value objects: Money, CurrencyCode, AccountId, TransactionId, CategoryId, AccountType, TransactionType, Payee, TransactionDate, FinancePeriod
- Account entity and Transaction entity
- IAccountRepository and ITransactionRepository interfaces (including TransactionQuery, TransactionPage)
- BalanceCalculationService, TransferService, CategorySummaryService
- All 7 domain events
- All 14 use cases backed by fake/in-memory repositories
- Validation rules wired to the existing `Validator<T>` / `CompositeValidator` framework
- Comprehensive unit test coverage (target: 100% of domain logic)

Definition of done: `dart test features/finance` passes. `dart analyze features/finance` clean. Zero Flutter dependencies. Zero storage dependencies.

---

### Sprint 8B — Finance Storage

No UI.

Deliverables:
- SQLite schema for `accounts` and `transactions` tables (using `INTEGER` minor-unit columns: `initial_amount_minor`, `amount_minor` — see §6.2)
- `CurrencyScale` — constant lookup map from ISO 4217 code to minor-unit decimal places; used by repository layer for Money ↔ integer conversion
- `AccountRepositoryImpl` implementing `IAccountRepository`
- `TransactionRepositoryImpl` implementing `ITransactionRepository` (including `saveTransferPair` wrapped in a DB transaction for atomicity)
- Money conversion: repository converts `Money.amount` (decimal) → `INTEGER` on write; converts `INTEGER` → `Money.amount` (decimal) on read using the currency's scale factor
- Schema migration infrastructure (version table, migration runner in `FinanceStartupStep`)
- Default Finance category seeds (seeded via `FinanceStartupStep`)
- Storage-layer unit tests using in-memory or test SQLite database; includes Money round-trip tests for representative currencies (INR, USD, JPY, BHD)
- Integration tests: end-to-end from use case → real repository → SQLite

Definition of done: All use cases work against a real SQLite database. Transfers are atomic (`saveTransferPair` is a single DB transaction). Soft-deleted records are excluded from live queries. Money round-trip conversion is lossless for all supported currencies. `flutter analyze features/finance` clean.

---

### Sprint 8C — Finance Module and Event Wiring

No UI.

Deliverables:
- `FinanceModule` extending `FeatureModule`
- DI registration: all repositories, services, use cases
- `FinanceStartupStep`: schema migration + category seeding
- `FinanceRoutes`: route constants
- Event publishing in use cases: after each successful persistence, publish the appropriate domain event via `IEventBus`
- Module integration tests
- Register `FinanceModule` in `AppBootstrap`

Definition of done: FinanceModule boots successfully. All use cases resolve from DI. Events are published to the bus. All tests clean.

---

### Sprint 8D — Finance Presentation

Requires ADR-004 (state management / UI framework) approval before starting.

Deliverables:
- `FinanceHomePage` — account list + period summary
- `AccountDetailPage` — account info + transaction list
- `AddExpensePage` and `AddIncomePage` — input forms
- `TransferPage` — from/to account + amount
- `TransactionDetailPage` — read-only detail + edit action
- Basic widget tests for each screen

Definition of done: All screens render from real DI-resolved use cases. Navigation between screens works. `flutter analyze` clean.

---

### Sprint 8E — Finance Reports (Future)

Deliverables:
- Monthly summary screen (income vs expenses)
- Category breakdown chart
- Period navigation (previous/next month)
- Net worth across all accounts

Dependency: Platform Analytics Service or an approved charting library (requires ADR-004).

---

## 13. Deliverables Index

| # | Deliverable | Section |
|---|---|---|
| 1 | Finance Domain Overview | §1 |
| 2 | Ubiquitous Language | §2 |
| 3 | Bounded Context Diagram | §8 |
| 4 | Entity List | §4.1 |
| 5 | Value Object List | §4.2 |
| 6 | Aggregate Roots | §4.3 |
| 7 | Repository Contracts | §4.5 |
| 8 | Use Case Catalog | §4.6 |
| 9 | Domain Events | §4.7 |
| 10 | Validation Rules | §4.9 |
| 11 | MVP Scope | §10 |
| 12 | Future Scope | §11 |
| 13 | Risks | §9 |
| 14 | Implementation Roadmap | §12 |
