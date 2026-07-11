# DOC-005 --- Capability System

**Version:** 1.0\
**Status:** Draft (Review 1)\
**Category:** Core Platform

## Executive Summary

The Capability System enables composition over inheritance. Entities
declare reusable capabilities and the Platform SDK provides the
implementation through shared Platform Services.

**Architecture Decision:** Capability → Platform Service (Behavior layer
deferred until a real need exists.)

## Principles

-   Composition over inheritance.
-   Capabilities declare intent.
-   Platform Services implement reusable functionality.
-   Runtime orchestrates execution.
-   Business logic stays inside Domains.
-   Capabilities remain reusable across Feature Packages.

## Capability Flow

Entity → Capability → Platform Service → Platform Runtime

## Capability Groups

### Organization

-   Searchable
-   Categorized
-   Taggable
-   Favoritable
-   Pinnable
-   Archivable

### Knowledge

-   Attachable
-   Notable
-   Commentable (future)

### Scheduling

-   CalendarAware
-   ReminderEnabled
-   Repeatable

### Relationships

-   Linkable
-   ParentAware
-   ChildAware
-   ReferenceAware

### Activity

-   TimelineEnabled
-   Auditable
-   Versioned

### Intelligence

-   AIAnalyzable
-   OCRReadable
-   VoiceCreatable

### Automation

-   Triggerable
-   Actionable
-   RuleAware

### Sharing

-   Exportable
-   Shareable
-   Syncable

## Runtime Execution

When an Entity is created: 1. Runtime discovers supported Capabilities.
2. Matching Platform Services are invoked. 3. Feature Package business
logic executes independently.

## Example

Expense supports: - Searchable - Categorized - Taggable -
TimelineEnabled - Linkable - Attachable - AIAnalyzable

No finance-specific implementation is required for these shared
features.

## Design Rules

1.  Capabilities never contain business logic.
2.  Platform Services remain reusable.
3.  Entities stay focused on business data.
4.  Runtime coordinates capability execution.
5.  Feature Packages reuse capabilities rather than duplicating logic.

## Future Extension

Potential future capabilities: - GeolocationAware - HealthAware -
WearableAware - CollaborationAware - EncryptionAware - MarketplaceAware

## AI Context

-   Prefer composition over inheritance.
-   Do not introduce a Behavior layer unless justified by future
    requirements.
-   Keep capabilities declarative.
-   Use Platform Services for implementation.
