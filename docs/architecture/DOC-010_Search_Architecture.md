# DOC-010 --- Search Architecture

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Core
Platform

## Purpose

Defines the global search capability across all Feature Packages while
maintaining workspace isolation.

## Goals

-   Fast global search
-   Workspace-scoped results
-   Offline-first indexing
-   Extensible ranking

## Architecture

Feature Packages → Domain Events → Search Service → Search Index →
Search API → UI

## Search Sources

-   Expenses
-   Tasks
-   Notes
-   Documents
-   Habits
-   Assets
-   Projects
-   Categories
-   Tags

## Indexing

-   Incremental updates via Event Bus
-   Full rebuild supported
-   Workspace-specific index

## Query Features

-   Keyword search
-   Filters
-   Entity type
-   Tags
-   Categories
-   Date range
-   Favorites

## Ranking

Priority based on: - Exact match - Recent usage - Favorites - Entity
relevance

## Rules

1.  Search never queries packages directly.
2.  Packages publish events.
3.  Search owns its index.
4.  Search is read-only.

## Future

-   Semantic search
-   AI-assisted search
-   OCR search
-   Voice search

## AI Context

Implement Search as a Platform Service. Keep indexing event-driven and
Workspace-scoped.

## ADR-010

**Decision:** Search uses an independent index synchronized through the
Event Bus.
