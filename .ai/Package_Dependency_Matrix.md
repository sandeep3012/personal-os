# Package Dependency Matrix

**Version:** v2.0  
**Repository Version:** v0.5.0-platform-foundation

---

# Purpose

This document defines the approved dependency relationships between all repository packages.

Every package must follow this dependency matrix.

If a dependency is not explicitly allowed here, it is considered forbidden.

When a new dependency direction is required, an ADR must be created before implementation.

---

# Dependency Philosophy

Dependencies always point inward toward stable layers.

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

- No cyclic dependencies.
- No upward dependencies.
- Platform packages never depend on Features.
- Features never depend on other Features.
- Apps coordinate Features.
- Application orchestrates platform services.
- Platform Core remains independent.

---

# Layer Responsibilities

## Platform Core

Purpose

Provides the fundamental building blocks of the platform.

Examples

- Result
- Exceptions
- Logging
- Configuration
- Dependency Injection Contracts
- Shared Constants
- Base Models
- Utilities

Allowed Dependencies

- Flutter/Dart SDK only

Forbidden

- Runtime
- Application
- Features
- Apps

---

## Platform Runtime

Purpose

Provides runtime infrastructure built on Platform Core.

Examples

- RuntimeBootstrap
- Event Bus
- Lifecycle
- Service Registry
- Module Loading

Allowed Dependencies

- platform_core

Forbidden

- Application
- Features
- Apps

---

## Platform Storage

Purpose

Defines storage abstractions and contracts.

Examples

- Storage Interfaces
- Repository Contracts
- Persistence Models
- Storage Exceptions

Allowed Dependencies

- platform_core

Forbidden

- Runtime
- Application
- Features
- Apps

---

## Application (Sprint 6)

Purpose

Application orchestration layer.

Responsibilities

- Use Case abstractions
- Application Services
- Workflow orchestration
- Cross-feature coordination
- Validation abstractions (if approved)
- Navigation abstractions (if approved)

Allowed Dependencies

- platform_core
- platform_runtime
- platform_storage (only when storage contracts are required)

Forbidden

- Flutter UI
- Features
- Apps

Notes

Application must not become another utility SDK.

Its responsibility is orchestration.

---

## Shared

Purpose

Reusable code shared by multiple Features.

Examples

- UI Components
- Themes
- Localization
- Common Widgets
- Design System
- Shared Assets

Allowed Dependencies

- platform_core
- application

Forbidden

- Feature-to-feature dependencies

---

## Feature Packages

Purpose

Business capabilities.

Examples

- Notes
- Tasks
- Finance
- Calendar
- Knowledge
- Habits

Allowed Dependencies

- application
- shared
- platform_core

Conditional

- platform_runtime (only through approved abstractions)

Forbidden

- Other Features
- Apps

---

## Apps

Purpose

Application composition.

Responsibilities

- Compose Features
- Dependency registration
- Platform entry points
- Navigation host
- Shell
- App configuration

Allowed Dependencies

- Features
- Application
- Shared

Forbidden

Direct business logic.

---

# Current Package Dependencies

| Package | Allowed Dependencies |
|----------|----------------------|
| platform_core | Flutter/Dart SDK |
| platform_runtime | platform_core |
| platform_storage | platform_core |
| application | platform_core, platform_runtime, platform_storage* |
| shared | platform_core, application |
| feature_* | application, shared, platform_core |
| apps/mobile | feature_*, application, shared |
| apps/web | feature_*, application, shared |
| apps/desktop | feature_*, application, shared |

*Only when storage contracts are required.

---

# Dependency Rules

## Allowed

Apps

↓

Features

↓

Application

↓

Platform Runtime

↓

Platform Core

---

## Forbidden

Platform Core

↓

Application

❌

Platform Runtime

↓

Features

❌

Feature A

↓

Feature B

❌

Apps

↓

Platform Core

❌ (unless explicitly approved)

Application

↓

Apps

❌

---

# Cross Feature Communication

Features must never communicate directly.

Communication must occur through:

- Application Services
- Event Bus
- Shared Contracts
- Dependency Injection

---

# Dependency Validation Checklist

Before merging code verify:

- No cyclic dependencies.
- Layer direction is respected.
- No Feature → Feature references.
- No Platform → Feature references.
- No UI logic inside Platform.
- No business logic inside Apps.
- Public APIs remain stable.

---

# ADR Trigger Conditions

A new ADR is required when:

- Introducing a new Platform package.
- Changing dependency direction.
- Allowing a previously forbidden dependency.
- Introducing a cross-feature dependency.
- Moving responsibilities between layers.
- Introducing new architectural abstractions.

---

# AI Rules

AI assistants must:

- Validate every new dependency.
- Reject forbidden references.
- Prefer existing platform services.
- Never duplicate infrastructure.
- Recommend ADRs before changing dependency rules.

---

# Current Repository Status

Current Version

v0.5.0-platform-foundation

Completed

- Platform Core
- Platform Runtime
- Platform Storage
- App Shell

Next

Application Foundation

---

# End