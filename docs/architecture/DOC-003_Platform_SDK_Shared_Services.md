# DOC-003 --- Platform SDK & Shared Services

**Version:** 1.0\
**Status:** Draft (Review 1)\
**Category:** Platform Architecture

## Purpose

The Platform SDK is the technical foundation of Personal OS. It provides
reusable capabilities, infrastructure, contracts, and shared services
that every App builds upon.

Business logic belongs to Domains. User experience belongs to Apps. The
SDK provides the reusable platform.

------------------------------------------------------------------------

# Responsibilities

The Platform SDK provides:

-   Common models
-   Shared services
-   Shared capabilities
-   Infrastructure
-   Contracts
-   Event distribution
-   Storage abstraction
-   AI integration
-   Search
-   Timeline
-   Notifications
-   Calendar
-   Theme
-   Widget framework

The Platform SDK does **not** contain:

-   Finance business rules
-   Productivity business rules
-   App-specific UI
-   Domain-specific calculations

------------------------------------------------------------------------

# Architecture

``` text
Personal OS
│
├── Platform SDK
│   ├── Core
│   ├── Shared Services
│   ├── Capabilities
│   └── UI Foundation
│
└── Installed Apps
    ├── Finance
    ├── Tasks
    ├── Notes
    ├── Documents
    └── Habits
```

------------------------------------------------------------------------

# SDK Layers

## Layer 1 --- Core

Provides:

-   Configuration
-   Logging
-   Error Handling
-   Dependency Injection
-   Storage
-   Networking
-   Security
-   Encryption
-   Permissions

------------------------------------------------------------------------

## Layer 2 --- Shared Services

-   Search
-   Timeline
-   Notifications
-   Calendar
-   Analytics
-   AI Gateway
-   Attachments
-   Classification
-   Entity Linking
-   Automation
-   Settings
-   Theme

------------------------------------------------------------------------

## Layer 3 --- Capabilities

Composable behaviors:

-   Searchable
-   Taggable
-   Categorized
-   Attachable
-   TimelineEnabled
-   CalendarAware
-   ReminderEnabled
-   Linkable
-   AIAnalyzable
-   Exportable
-   Shareable

------------------------------------------------------------------------

## Layer 4 --- UI Foundation

Shared UI infrastructure:

-   Design Tokens
-   Typography
-   Colors
-   Icons
-   Buttons
-   Cards
-   Dialogs
-   Bottom Sheets
-   Form Controls
-   Animations
-   Responsive Layout Utilities

------------------------------------------------------------------------

# Shared Services

## Search Service

Global search, indexing, suggestions, filters, and ranking.

## Timeline Service

Receives events and presents chronological activity.

## Notification Service

Local notifications, scheduling, actions, future push support.

## Calendar Service

Scheduling, recurrence, agenda, date calculations.

## Classification Service

Universal Categories, Tags, Labels, Priority, Status and Type.

## Attachment Service

File storage, previews, metadata, import/export.

## Entity Linking Service

Supports:

-   Manual Links
-   Rule-based Automatic Links
-   AI Smart Link Suggestions

## AI Gateway

Responsibilities:

-   Provider abstraction
-   Prompt routing
-   Privacy enforcement
-   Result caching
-   AI provider independence

## Automation Service

Supports:

-   Rules
-   Triggers
-   Conditions
-   Actions
-   Scheduling

## Analytics Service

Provides:

-   Metrics
-   Aggregations
-   Charts
-   KPIs
-   Insights

------------------------------------------------------------------------

# SDK Design Rules

1.  Apps depend on the SDK.
2.  SDK never depends on Apps.
3.  Services communicate through contracts and events.
4.  Services remain reusable across Apps.
5.  Infrastructure components should be replaceable.

------------------------------------------------------------------------

# Extension Points

Future provider abstractions:

-   AI Providers
-   Storage Providers
-   Sync Providers
-   Authentication Providers
-   Widget Providers
-   Theme Providers

------------------------------------------------------------------------

# Future Services

Not required for Version 1 but supported architecturally:

-   Cloud Sync
-   Collaboration
-   Plugin Marketplace
-   Health Integration
-   Banking Integrations
-   Email Integration
-   Calendar Sync
-   Wearables

------------------------------------------------------------------------

# Principles

The Platform SDK should be:

-   Stable
-   Predictable
-   Lightweight
-   Replaceable
-   Extensible
-   Testable
-   Well Documented
-   Independent of Business Domains

------------------------------------------------------------------------

# Architectural Decisions

-   Platform SDK is the foundation for every App.
-   Domains own business logic.
-   Apps consume shared platform services.
-   Shared services communicate via events and contracts.
-   Capabilities are composable.
-   Infrastructure should be replaceable whenever practical.
