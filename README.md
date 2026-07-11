# Personal OS

A modular, offline-first personal productivity platform built as a Flutter monorepo.

---

## Project Overview

Personal OS is a cross-platform application targeting Android, iOS, Web, Windows, macOS, and Linux. It is architected as a Flutter monorepo managed by [Melos](https://melos.invertase.dev/), following Clean Architecture principles with strict feature isolation and event-driven communication between modules.

---

## Repository Structure

```
personal_os/
├── apps/
│   └── mobile/          # Flutter application (all platforms)
├── packages/            # Platform SDK packages (shared infrastructure)
├── features/            # Feature packages (isolated business domains)
├── shared/              # Shared utilities, UI components, constants
├── docs/                # Architecture decisions, design documents
├── scripts/             # Build, CI, and maintenance scripts
├── tooling/             # Custom tooling and code generators
├── .github/             # GitHub Actions workflows and templates
├── .ai/                 # AI context pack (architecture, roadmap, standards)
├── melos.yaml           # Melos workspace configuration
├── analysis_options.yaml
└── README.md
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Stable channel) |
| Language | Dart |
| Monorepo Tooling | Melos |
| State Management | TBD (Sprint 2+) |
| Local Storage | TBD (Sprint 4) |
| Architecture | Clean Architecture + Feature isolation |

---

## Dependency Rules

```
Apps → Features → Platform SDK → Flutter
```

- Feature packages **must not** depend on other feature packages.
- All cross-feature communication is event-driven.
- Business logic must never exist in the UI layer.

---

## Build Requirements

| Tool | Minimum Version |
|---|---|
| Flutter | Stable channel |
| Dart | Bundled with Flutter |
| Melos | 8.x |

---

## Bootstrap Instructions

### 1. Install Melos

```bash
dart pub global activate melos
```

### 2. Bootstrap the workspace

```bash
melos bootstrap
```

### 3. Run the mobile app

```bash
cd apps/mobile
flutter run
```

### 4. Analyze all packages

```bash
melos analyze
```

### 5. Run all tests

```bash
melos test
```

---

## Platform Support

| Platform | Status |
|---|---|
| Android | Supported |
| iOS | Supported |
| Web | Supported |
| Windows | Supported |
| macOS | Supported |
| Linux | Supported |

---

## Architecture Governance

All architectural changes require an Architecture Decision Record (ADR). See `.ai/ADR_INDEX.md` for the governance process. No architecture may be changed without a corresponding ADR.

---

## Development Workflow

```
Requirements → Architecture → Prompt → Code → Review → Test → Merge
```

See `.ai/AI_WORKFLOW.md` for the full AI-assisted development workflow.
