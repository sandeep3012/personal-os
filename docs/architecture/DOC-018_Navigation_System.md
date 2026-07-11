# DOC-018 --- Navigation System

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** User
Experience

## Purpose

Defines a consistent navigation model across all platforms while keeping
Feature Packages independent.

## Principles

-   Simple first
-   Workspace-aware
-   Consistent across Android, iOS, Web and Desktop
-   Deep-link ready
-   State preserving

## Primary Navigation

-   Dashboard
-   Finance
-   Tasks
-   Settings

Additional Feature Packages are accessed through: - App Library -
Search - Widgets - Shortcuts

## Navigation Hierarchy

Workspace → Dashboard → Feature Package → Screen → Detail

## Navigation Types

-   Bottom Navigation (Mobile)
-   Navigation Rail (Tablet)
-   Sidebar (Desktop/Web)
-   Deep Links
-   Global Search Navigation

## Rules

1.  Feature Packages own their internal navigation.
2.  Platform owns top-level navigation.
3.  Navigation state is restored per Workspace.
4.  Deep links resolve through the Navigation Service.

## Future

-   Multi-window
-   Split view
-   Floating panels
-   Keyboard shortcuts
-   Universal command palette

## AI Context

Keep navigation centralized. Feature Packages register routes but do not
control global navigation.

## ADR-018

**Decision:** The Platform owns top-level navigation while Feature
Packages own internal navigation.
