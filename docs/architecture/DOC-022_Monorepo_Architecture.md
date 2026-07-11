# DOC-022 --- Monorepo Architecture

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Engineering

## Purpose

Defines the repository structure for Personal OS, enabling multiple
applications, shared platform modules, and reusable packages to evolve
together.

## Principles

-   Single repository
-   Modular architecture
-   Shared Platform SDK
-   Independent Feature Packages
-   Clear dependency boundaries

## Repository Structure

``` text
personal_os/

apps/
  mobile/
  web/
  desktop/

packages/
  application/
  platform_core/
  platform_runtime/
  platform_services/
  platform_ui/
  platform_ai/
  platform_storage/
  platform_search/
  platform_notifications/
  platform_analytics/

features/
  finance/
  tasks/
  habits/
  notes/
  documents/
  subscriptions/
  reminders/

shared/
  design_system/
  common_models/
  utilities/

docs/
scripts/
tools/
```

## Dependency Rules

-   Apps depend on Platform packages.
-   Feature Packages depend on the Platform SDK.
-   Feature Packages never depend on one another.
-   Shared packages remain domain-independent.
-   Avoid circular dependencies.

## Benefits

-   Shared codebase
-   Faster development
-   Easier refactoring
-   Consistent architecture
-   Better AI-assisted development

## Future

-   Plugin packages
-   Premium modules
-   Enterprise extensions

## AI Context

Keep packages small and cohesive. Place reusable logic inside Platform
packages and avoid cross-feature dependencies.

## ADR-022

**Decision:** Personal OS adopts a modular monorepo architecture with
reusable Platform packages and independent Feature Packages.
