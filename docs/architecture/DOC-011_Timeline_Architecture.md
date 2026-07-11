# DOC-011 --- Timeline Architecture

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Core
Platform

## Purpose

Defines a unified chronological activity feed across Personal OS without
owning business data.

## Goals

-   Workspace-scoped timeline
-   Event-driven updates
-   Offline-first
-   Cross-package visibility

## Architecture

Feature Packages → Domain Events → Event Bus → Timeline Service →
Timeline Store → Timeline UI

## Timeline Sources

-   Expenses
-   Tasks
-   Notes
-   Documents
-   Habits
-   Assets
-   Reminders
-   Automation
-   AI Insights (optional)

## Timeline Item

-   Id
-   WorkspaceId
-   EntityId
-   EntityType
-   EventType
-   Timestamp
-   Summary
-   Metadata

## Rules

1.  Timeline never modifies business data.
2.  Timeline stores references, not full entities.
3.  Updates occur through events.
4.  Timeline is read-only.

## Filters

-   Date
-   Entity Type
-   Tags
-   Category
-   Project
-   Favorites

## Future

-   AI summaries
-   Daily digest
-   Infinite history
-   Cross-device sync

## AI Context

Timeline reacts to events only. Keep it independent from Feature
Packages.

## ADR-011

**Decision:** Timeline is an event-driven Platform Service that stores
activity references rather than business data.
