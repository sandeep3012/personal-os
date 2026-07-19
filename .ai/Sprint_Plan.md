
# Sprint Plan

**Version:** v2.4  
**Repository Version:** v0.8.0-finance-designed  
**Current Milestone:** Finance Domain Design Complete

---

# Purpose

This document is the living execution plan for the Personal OS project. It tracks completed work,
current priorities, future roadmap, quality gates, and release planning.

---

# Project Vision

Build a modular, offline-first, AI-assisted Personal OS using a Flutter monorepo,
Platform SDK, Clean Architecture, and isolated feature packages.

---

# Current Status

## Repository

- Flutter Monorepo
- Melos Workspace
- CI Foundation
- Documentation (DOC-001–DOC-031) ✅
- ADR Governance ✅ (ADR-001 Accepted, ADR-002 Partially Accepted, ADR-003 Accepted)
- Analyzer clean
- Tests passing
- Web build passing

## Completed Foundation

- Repository Bootstrap
- Platform Core
- Platform Runtime
- Platform Storage (Contracts)
- App Shell Integration
- Application Layer Foundation

Current Version:

**v0.7.5-framework-validated**

---

# Completed Sprints

## Sprint 1 — Repository Bootstrap

Completed:
- Monorepo
- Melos
- CI
- Linting
- Workspace

Status: ✅ Complete

---

## Sprint 2 — Platform Core

Completed:
- Result Pattern
- Logging
- Configuration
- Dependency Injection Contracts
- Base Exceptions
- Utilities
- Core Models

Status: ✅ Complete

---

## Sprint 3 — Platform Runtime

Completed:
- Runtime Bootstrap
- Event Bus
- Lifecycle
- Service Registry
- Runtime Modules

Status: ✅ Complete

---

## Sprint 4 — Platform Storage

Completed:
- Storage Contracts
- Repository Interfaces
- Persistence Abstractions
- Storage Exceptions

Status: ✅ Complete

---

## Sprint 5 — App Shell Integration

Completed:
- App Bootstrap
- Runtime Integration
- Initial Navigation
- Dependency Registration
- Web Startup
- Tests

Status: ✅ Complete

---

# Current Activity

## Sprint 8 — Finance Domain Discovery & Design

Objective:

Pure design sprint. No production code. Produced the Finance Domain Design
document (DOC-031) covering all 14 deliverables.

Delivered:

- `docs/architecture/DOC-031_Finance_Domain_Design.md` — complete Finance domain design
  - Domain overview and product scope
  - Ubiquitous language (11 canonical terms)
  - Capability classification: Core MVP vs Future vs Out of Scope
  - 2 Aggregate Roots: Account, Transaction
  - 10 Value Objects: Money, CurrencyCode, AccountId, TransactionId, CategoryId,
    AccountType, TransactionType, Payee, TransactionDate, FinancePeriod
  - 3 Domain Services: BalanceCalculationService, TransferService, CategorySummaryService
  - 2 Repository Contracts: IAccountRepository, ITransactionRepository
  - 14 Use Cases (Account: 6, Transaction: 8 incl. summary: 5)
  - 7 Domain Events (Account lifecycle + Transaction lifecycle + TransferCreated)
  - 8 Business Invariants
  - Validation rules
  - Feature boundary map (Finance vs Platform responsibilities)
  - Storage strategy + offline-first approach
  - 7 Risks with mitigations
  - Implementation roadmap: Sprint 8A → 8B → 8C → 8D → 8E

Key design decisions:
- Transfers promoted to Core MVP (required for balance correctness)
- Categories: Finance stores `categoryId` reference only; platform owns category storage
- `saveTransferPair` on repository = atomic DB transaction (not two separate saves)
- Amount precision: REAL storage in MVP; INTEGER migration is known technical debt
- Account balance: computed via BalanceCalculationService; not stored as mutable field (MVP)

Status:

✅ Complete — DOC-031 written to repository

---

## Sprint 8A Planning — Finance Domain (Pure Dart)

Prerequisites met:
- DOC-031 Finance Domain Design ✅
- FeatureModule, FeatureMetadata, FeatureRegistry stable ✅
- Feature_Template.md corrected ✅
- NoParamsUseCase<T>, AsyncUseCase<I,O> in packages/application ✅
- Result<T>, IDependencyRegistrar in platform_core ✅
- 156 tests passing, analyzer clean ✅

Pending before Sprint 8A begins:
- ADR-004 (state management / UI framework) — required for Sprint 8D (presentation); NOT required for 8A, 8B, 8C (pure domain + storage + wiring)
- NavigationService full implementation — required for Sprint 8D only
- Resolve PermissionService provisional status
- Resolve AppLifecycleService provisional status

Status:

🟡 Ready for Sprint 8A — Finance Domain (Pure Dart, no storage, no UI)

---

# Completed Sprints

## Sprint 6 — Application Foundation

Objective:

Create the Application orchestration layer.

Delivered:

- `packages/application` (pure Dart)
- UseCase abstractions (UseCase, AsyncUseCase, NoParamsUseCase)
- NavigationService, RouteRegistry, ApplicationRouter, RouteDefinition
- Event marker types (AppEvent, DomainEvent)
- Validation framework (Validator<T>, ValidationResult, CompositeValidator)
- ApplicationModule (RuntimeModule subclass)
- Application exceptions (NavigationException, UseCaseException)
- 92 unit tests across 8 suites

Resolved at v0.6.0 Architecture Finalization:

- AsyncState<T> — APPROVED as domain state type (see ADR-002)
- FeatureFlag, FeatureFlagService — APPROVED as interface-only
- StartupPipeline, StartupContext, StartupStep — APPROVED (Application Startup Pipeline tier)
- DeepLink, DeepLinkHandler — REMOVED (deferred to platform_services, see ADR-003)
- AppConfiguration, BuildFlavor — REMOVED (redundant with platform_core types)

Still provisional (must resolve before Sprint 7 feature use):

- PermissionService, PermissionType, PermissionStatus, PermissionException
- AppLifecycleService

Constraints met:

- No business features
- No Flutter dependency inside application package
- Reuses existing platform services

Status:

✅ Complete — Architecture Finalized

Version:

**v0.6.0-application-foundation**

---

## Sprint 7 — Feature Framework

Objective:

Build the reusable Feature Framework that every future feature package uses.
No business features implemented — framework only.

Delivered:

- `FeatureModule` — base class for all feature packages (extends RuntimeModule)
- `FeatureMetadata` — identity record (id, name, version, description)
- `FeatureRegistry` — discovery catalog populated synchronously at boot
- `FeatureException` — feature-layer error type
- `ApplicationModule` updated — registers `FeatureRegistry` singleton
- 37 new unit tests (129 total, all passing)
- `docs/architecture/Feature_Template.md` — canonical feature package structure
- `packages/application/README.md` updated

Architecture decisions implemented:

- Route registration: synchronous during `register()` phase (ADR-003 Section 5)
- Module ordering: `ApplicationModule` must precede all `FeatureModule`s
- Feature isolation: features import only `application` (never each other)
- No UI framework binding until ADR-004 approved

Status:

✅ Complete

Version:

**v0.7.0-feature-framework**

---

## Sprint 7.5 — Feature Framework Validation

Objective:

Validate the Feature Framework built in Sprint 7 end-to-end using a complete
reference implementation (`features/sample`). Not a business feature — framework
validation only.

Delivered:

- `features/sample` — minimal but complete reference feature package
  - `SampleModule` — extends `FeatureModule`; exercises all 4 hooks
  - `SampleService` — application service; tracks startup completion
  - `GetSampleStatusUseCase` — implements `NoParamsUseCase<String>`
  - `SampleStartupStep` — implements `StartupStep`
  - `SampleRoutes` — `RouteDefinition` constants
  - `SamplePage` — Flutter `StatelessWidget`
- 27 unit tests (all passing): service, use case, DI/module integration
- `AppBootstrap` fixed: `ApplicationModule` was missing from bootstrap sequence
- `AppRouter` refactored: accepts `featureRoutes` parameter (ADR-003 §4 fulfilled)
- `apps/mobile` wired: `SampleModule` registered; home screen navigates to `SamplePage`
- `Feature_Template.md` corrected: `platform_core` IS an allowed feature dep

Framework findings:
- Features need `platform_core: any` in pubspec (for `Result<T>`, `IDependencyRegistrar`)
- Tests need `platform_runtime: any` in dev_dependencies (for `ServiceRegistry`)
- The Package Dependency Matrix was always correct; `Feature_Template.md` had the error

Status:

✅ Complete — `FEATURE FRAMEWORK VALIDATED`

Version:

**v0.7.5-framework-validated**

---

# Future Roadmap

## v0.6.0 ✅

Application Foundation (Complete)

## v0.7.0 ✅

Feature Framework (Complete)

## v0.7.0

Feature Framework

- Feature template
- Module registration
- Feature lifecycle

## v0.8.0

Workspace Foundation

- Workspace engine
- Entity management
- Search integration

## v0.9.0

Knowledge Engine

- Timeline
- Classification
- Entity linking
- Knowledge graph

## v1.0.0

Foundation Complete

- Stable SDK
- Stable Architecture
- Stable Feature Framework
- Production-ready documentation

---

# Sprint Workflow

1. Planning
2. Architecture Review
3. Implementation
4. Unit Testing
5. Analyzer
6. Documentation
7. Architecture Review
8. Product Owner Approval
9. Release

---

# Definition of Ready

A sprint starts only when:

- Scope defined
- Architecture approved
- Dependencies identified
- Acceptance criteria agreed
- Risks understood

---

# Definition of Done

A sprint is complete only when:

- Implementation complete
- Tests passing
- Analyzer clean
- Documentation updated
- Architecture compliant
- Dependency rules respected
- Product Owner approval received

---

# Architecture Gates

Every sprint must verify:

- Clean Architecture
- SOLID
- Dependency Matrix
- Package Boundaries
- Public API Stability
- No duplicate infrastructure

---

# Testing Strategy

Every sprint must include:

- Unit tests
- Regression tests
- Existing tests remain green
- Web build verification

---

# Documentation Requirements

Update when applicable:

- Package README
- Public APIs
- Master Context
- Sprint Plan
- ADRs (only when approved)

---

# Quality Gates

Before merge:

- flutter analyze
- dart test
- melos bootstrap
- Build verification
- Documentation review

---

# Release Process

1. Freeze scope
2. Verify quality gates
3. Review architecture
4. Tag release
5. Update changelog
6. Increment semantic version

---

# Technical Debt

Track:

- Deferred ADRs
- Planned refactoring
- Performance improvements
- Future platform packages

---

# Current Priorities

1. Complete Application Foundation
2. Preserve architecture consistency
3. Avoid duplicate abstractions
4. Expand test coverage
5. Prepare Feature Framework

---

# AI Workflow

Before implementation:

1. Load Master Context
2. Load relevant architecture documents
3. Load relevant ADRs
4. Analyze repository
5. Produce implementation plan
6. Implement approved scope
7. Validate
8. Update documentation
9. Produce implementation report

---

# Success Criteria

The Platform Foundation is considered complete when:

- Platform SDK is stable
- Application layer established
- Feature framework ready
- Documentation synchronized
- Architecture governance operational

---

# End
