# DOC-020 --- Widget Framework

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** User
Experience

## Purpose

Defines the reusable widget framework used throughout Personal OS.

## Principles

-   Reusable
-   Independent
-   Configurable
-   Responsive
-   Data driven

## Widget Structure

Widget → Configuration → Data Provider → View → Actions

## Widget Types

-   Summary
-   List
-   Chart
-   Calendar
-   KPI
-   Timeline
-   AI Insight
-   Shortcut

## Widget Lifecycle

Create → Configure → Load Data → Render → Refresh → Dispose

## Rules

1.  Widgets never own business logic.
2.  Widgets consume Platform Services or Feature Package APIs.
3.  Widgets are reusable across dashboards.
4.  Widgets are Workspace-aware.

## Future

-   Widget marketplace
-   Third-party widgets
-   Interactive widgets
-   Live widgets

## AI Context

Treat widgets as presentation components only.

## ADR-020

**Decision:** Widgets are reusable presentation components independent
of business logic.
