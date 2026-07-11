# DOC-007 --- Universal Entity Model

**Version:** 1.0\
**Status:** Draft (Review 1)\
**Category:** Core Platform

## Purpose

Defines the common structure shared by all business entities while
keeping domain data separate from platform metadata.

## Principles

-   Business data belongs to Feature Packages.
-   Platform metadata belongs to Platform Services.
-   Composition over inheritance.
-   Keep entities focused and lightweight.

## Entity Ownership

### Business Data (Feature Package)

Examples for Expense: - Amount - Currency - Account - CategoryId -
TransactionDate - Merchant

### Platform Metadata

Managed independently: - Tags - Attachments - Links - Timeline entries -
Search index - AI insights - Favorites - Archive status

## Common Entity Identity

Every entity must have:

-   Id
-   WorkspaceId
-   EntityType
-   CreatedAt
-   UpdatedAt

## Entity Lifecycle

Draft → Active → Archived → Deleted (soft delete)

## Relationships

Entities never directly own other entities.

Relationships are managed through the Entity Linking Service.

## Capabilities

Entities opt into capabilities such as:

-   Searchable
-   Taggable
-   Linkable
-   Attachable
-   TimelineEnabled
-   AIAnalyzable
-   ReminderEnabled

## Design Rules

1.  No business logic inside entities.
2.  No platform metadata inside business models.
3.  Keep entities immutable where practical.
4.  Extend functionality through capabilities.

## AI Context

-   Keep entities domain-focused.
-   Store cross-cutting concerns in Platform Services.
-   Avoid large BaseEntity classes.

## ADR-007

**Decision:** Business data and platform metadata remain separate to
preserve clean domain boundaries.
