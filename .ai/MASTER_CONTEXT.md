# Master Context

**Project:** Personal OS
**Version:** v2.2
**Repository Version:** v0.7.5-framework-validated
**Status:** v0.7.5 Complete — Sprint 8 Planning (Finance MVP)

---

# Purpose

This document is the primary context loaded by AI assistants before performing any analysis, design, implementation, or review.

It provides the current state of the project and directs AI assistants to the authoritative architecture documents.

This document is **not** the architecture itself.

The architecture is defined exclusively by the documents listed below.

---

# Source of Truth

The following documents define the approved architecture:

- DOC-001 through DOC-030
- ADR-001 onwards
- Repository README
- Package READMEs

If any implementation conflicts with these documents:

- The architecture wins.
- AI must never redesign the architecture.
- New architectural ideas require an ADR before implementation.

---

# Architecture Principles

The Personal OS platform follows these principles:

- Flutter Monorepo
- Clean Architecture
- Platform SDK First
- Offline First
- Event Driven Runtime
- Capability Based Architecture
- Feature Isolation
- Dependency Injection
- Domain Driven Design
- SOLID Principles
- Testable by Design
- AI Assisted Development

---

# Dependency Rules

Dependencies flow in one direction only.

```
Apps
    ↓
Features
    ↓
Application
    ↓
Platform Runtime
    ↓
Platform Core
```

Rules:

- Apps never access Platform directly unless explicitly approved.
- Features never depend on other Features.
- Platform packages never depend on Features.
- Platform Core has no project dependencies.
- Runtime extends Core.
- Application orchestrates platform services.
- UI contains no business logic.

---

# Current Repository Status

Current Version

v0.7.0-feature-framework

Completed

- Repository Bootstrap
- Flutter Monorepo
- Melos Workspace
- Platform Core
- Platform Runtime
- Platform Storage (Contracts)
- App Shell Integration
- Runtime Integration
- Dependency Injection Foundation
- Initial Navigation
- Web Build
- Unit Tests
- Application Layer Foundation (packages/application)
- Feature Framework (FeatureModule, FeatureMetadata, FeatureRegistry)
- Feature Framework Validation (features/sample — end-to-end reference impl)

Repository Health

- Builds successfully
- Analyzer clean (all packages)
- Tests passing (129 application + 27 feature_sample = 156 total)
- AppBootstrap wires ApplicationModule + feature modules correctly
- AppRouter accepts featureRoutes (ADR-003 §4 fulfilled)

ADR Status

- ADR-001 Application Layer: **Accepted**
- ADR-002 State Management: **Partially Accepted** — AsyncState<T> approved as domain type; UI framework deferred to ADR-004
- ADR-003 Navigation Architecture: **Accepted** — synchronous registration; DeepLink deferred to platform_services

---

# Current Milestone

Feature Framework Validated

---

# Current Activity

Sprint 8 Planning — Feature Framework validated end-to-end. Ready for Finance MVP.

Target:

Finance MVP — first feature package using the validated Feature Framework

Dependency rule clarification (from Sprint 7.5 validation):

Feature packages declare `platform_core: any` as an explicit dependency (for
`Result<T>`, `IDependencyRegistrar`). They declare `platform_runtime: any`
in dev_dependencies only (for `ServiceRegistry` in module tests). The Package
Dependency Matrix was correct; `Feature_Template.md` has been updated.

---

# Upcoming Roadmap

v0.6.0
Application Foundation

v0.7.0
Feature Framework

v0.8.0
Workspace Foundation

v0.9.0
Knowledge Engine

v1.0.0
Foundation Complete

---

# AI Workflow

Before every implementation:

1. Load Master Context.
2. Load relevant DOC architecture.
3. Load relevant ADRs.
4. Review existing implementation.
5. Verify architecture compliance.
6. Implement only approved architecture.
7. Execute tests.
8. Execute analyzer.
9. Update documentation.
10. Produce implementation report.

---

# AI Development Rules

AI must:

- Follow approved architecture.
- Never redesign architecture.
- Never duplicate existing platform functionality.
- Reuse existing services whenever possible.
- Preserve package boundaries.
- Maintain Clean Architecture.
- Keep public APIs stable.
- Keep Flutter dependencies out of Platform SDK unless explicitly required.
- Prefer composition over inheritance.
- Maintain backward compatibility where possible.

---

# Architecture Governance

Architecture changes require:

1. Proposal
2. Discussion
3. ADR
4. Approval
5. Implementation

No AI assistant may introduce new architectural concepts without approval.

---

# Quality Gates

Every implementation must satisfy:

- Builds successfully
- Analyzer clean
- Tests passing
- No architecture violations
- Dependency rules respected
- Public APIs documented
- README updated where necessary

---

# Current Platform Packages

Current Platform SDK:

- platform_core
- platform_runtime
- platform_storage
- application (v0.7.0 — Feature Framework: FeatureModule, FeatureMetadata, FeatureRegistry)
- feature_sample (v0.1.0 — Framework validation only; not a business feature)

Future Platform Packages:

- platform_services
- platform_sync
- platform_search
- platform_ai

---

# AI Roles

Product Owner

- Defines product direction
- Approves architecture
- Approves ADRs
- Prioritizes roadmap

AI Technical Lead

- Reviews architecture compliance
- Reviews Claude Code output
- Identifies technical debt
- Generates implementation plans
- Maintains project consistency

Claude Code

- Implements approved architecture
- Generates production-ready code
- Updates tests
- Updates documentation

Cursor

- Performs day-to-day development
- Refactoring
- Bug fixes
- Developer productivity

---

# Definition of Done

A sprint is complete only when:

- Implementation completed
- Tests passing
- Analyzer clean
- Architecture compliant
- Documentation updated
- Review completed
- Approved by Product Owner

---

# End of Context

After reading this document, AI assistants must load only the architecture documents relevant to the current task rather than the entire architecture set.