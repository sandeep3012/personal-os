# DOC-012 --- Classification System

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Core
Platform

## Purpose

Provides a universal classification capability that can be reused by
every Feature Package.

## Components

-   Categories
-   Tags
-   Labels
-   Priority
-   Status
-   Type

## Principles

-   Universal platform capability
-   Workspace scoped
-   Feature Packages define values
-   Shared implementation

## Categories

Examples

Finance: - Food - Fuel - Salary

Tasks: - Work - Personal

Documents: - Identity - Insurance

## Tags

Global reusable tags.

Examples: - Travel - Family - Office

## Status

Examples: - Draft - Active - Completed - Archived

## Priority

-   Low
-   Medium
-   High
-   Critical

## Rules

1.  Classification belongs to Platform Services.
2.  Feature Packages never implement their own classification engine.
3.  Categories are package-specific values.
4.  Tags are global.

## Future

-   Hierarchical categories
-   Smart tags
-   AI tag suggestions

## AI Context

Use a single Classification Service for all Feature Packages.

## ADR-012

**Decision:** Classification is a reusable Platform capability shared by
all Feature Packages.
