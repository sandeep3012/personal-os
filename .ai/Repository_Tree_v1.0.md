# Repository Tree

**Version:** v2.0  
**Repository Version:** v0.5.0-platform-foundation

---

# Purpose

This document defines the logical structure of the Personal OS repository.

It serves as the canonical reference for:

- Repository organization
- Package locations
- Feature locations
- Documentation
- AI development workflow

The actual repository may evolve, but all structural changes must remain consistent with the approved architecture.

---

# Repository Structure

```text
personal_os/
│
├── apps/
│   ├── mobile/
│   ├── web/
│   └── desktop/
│
├── packages/
│   ├── platform_core/
│   ├── platform_runtime/
│   ├── platform_storage/
│   ├── application/                (Sprint 6)
│   ├── platform_services/          (Future)
│   ├── platform_search/            (Future)
│   ├── platform_sync/              (Future)
│   └── platform_ai/                (Future)
│
├── features/
│   ├── notes/
│   ├── tasks/
│   ├── calendar/
│   ├── finance/
│   ├── knowledge/
│   ├── habits/
│   ├── goals/
│   ├── automation/
│   └── ...
│
├── shared/
│   ├── design_system/
│   ├── widgets/
│   ├── localization/
│   ├── themes/
│   ├── assets/
│   └── utilities/
│
├── docs/
│   ├── architecture/
│   │   ├── DOC-001_...
│   │   ├── DOC-002_...
│   │   ├── ...
│   │   └── DOC-030_...
│   │
│   ├── adr/
│   │   ├── ADR-001.md
│   │   ├── ADR-002.md
│   │   └── ...
│   │
│   ├── diagrams/
│   │
│   ├── planning/
│   │
│   └── README.md
│
├── .ai/
│   ├── Master_Context.md
│   ├── Package_Dependency_Matrix.md
│   ├── Repository_Tree.md
│   ├── Claude_Code_Master_Prompt.md
│   ├── Cursor_Project_Rules.md
│   ├── Sprint_Plan.md
│   └── Folder_Structure.md
│
├── scripts/
│
├── tooling/
│
├── test/
│
├── .github/
│   └── workflows/
│
├── melos.yaml
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── LICENSE
```

---

# Package Responsibilities

## apps/

Contains deployable applications.

Responsibilities:

- Platform entry point
- App shell
- Dependency composition
- Navigation host
- Platform integrations

Contains no business logic.

---

## packages/

Contains reusable platform infrastructure.

Examples:

- Core
- Runtime
- Storage
- Application
- AI
- Search
- Sync

These packages are shared by all features.

---

## features/

Contains isolated business modules.

Each feature owns:

- Domain
- Application
- Data
- Presentation
- Tests

Features never depend on each other.

---

## shared/

Contains reusable presentation assets.

Examples:

- Design System
- Widgets
- Themes
- Localization
- Assets

Contains no business rules.

---

## docs/

Contains all project documentation.

Subfolders:

- Architecture
- ADRs
- Diagrams
- Planning

This is the authoritative documentation.

---

## .ai/

Contains AI governance.

Examples:

- Master Context
- Prompts
- Rules
- Dependency Matrix
- Sprint Plan

AI assistants load these before implementation.

---

## scripts/

Repository automation.

Examples:

- Build
- Release
- Formatting
- Code generation

---

## tooling/

Developer tooling.

Examples:

- Custom generators
- Analysis tools
- Repository utilities

---

## test/

Repository-level integration and end-to-end tests.

Package-specific tests remain inside each package.

---

# Current Repository Status

Completed

- Flutter Monorepo
- Melos Workspace
- Platform Core
- Platform Runtime
- Platform Storage
- App Shell Integration

In Progress

- Application Foundation

Future

- Feature Framework
- Workspace Engine
- Knowledge Engine
- Automation Engine
- AI Platform

---

# Repository Rules

Every package must:

- Have its own README.
- Contain its own tests.
- Respect dependency rules.
- Follow Clean Architecture.
- Expose only stable public APIs.

---

# AI Rules

AI assistants must:

- Never change repository structure without approval.
- Never move packages between layers.
- Never introduce new root folders.
- Never bypass dependency rules.
- Keep documentation synchronized with implementation.

---

# Repository Evolution

Repository evolution occurs through:

1. Architecture proposal
2. ADR
3. Approval
4. Implementation
5. Documentation update

Repository structure is considered architecture.

---

# End