# DOC-009 --- Platform Data Architecture

**Version:** 1.0\
**Status:** Draft (Review 1)\
**Category:** Core Platform

## Purpose

Defines ownership, storage and responsibilities for Platform Data versus
Feature Package business data.

## Principles

-   Feature Packages own business data.
-   Platform owns cross-cutting data.
-   Shared metadata is stored independently.
-   Services communicate through identifiers, not object references.

## Data Ownership

### Feature Package Data

Examples: - Expenses - Tasks - Notes - Habits - Documents - Assets

Each package owns its schema and business rules.

### Platform Data

-   Search Index
-   Timeline
-   Tags
-   Categories
-   Entity Links
-   Attachments
-   AI Insights
-   Automation Rules
-   Notification State
-   User Preferences
-   Dashboard Layouts

## Data Layers

Platform Data Layer → Metadata Store → Timeline Store → Search Store →
Attachment Store → AI Store → Classification Store

Feature Packages → Domain Database → Repositories

## Access Rules

1.  Feature Packages cannot modify Platform stores directly.
2.  Platform Services expose APIs/contracts.
3.  Event Bus synchronizes cross-cutting data.

## Storage Strategy

-   Offline-first
-   Local database as source of truth
-   Cloud synchronization added later
-   Workspace-scoped storage

## Security

-   Workspace isolation
-   Encryption for sensitive data
-   Soft delete by default
-   Audit history for future support

## AI Context

Keep business data independent from platform metadata. Synchronize
through Platform Services and Events.

## ADR-009

**Decision:** Separate Platform Data from Feature Package business data
to maintain clean boundaries and simplify evolution.
