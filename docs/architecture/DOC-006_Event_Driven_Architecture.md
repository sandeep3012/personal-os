# DOC-006 --- Event-Driven Architecture & Event Bus

**Version:** 1.0\
**Status:** Draft (Review 1)\
**Category:** Core Platform

## Purpose

The Event Bus enables loose coupling between Feature Packages, the
Platform Runtime, and Platform SDK. Components communicate by publishing
and subscribing to events instead of calling each other directly.

## Goals

-   Decouple Feature Packages
-   Notify multiple services with a single event
-   Support offline-first execution
-   Enable AI, Automation, Analytics and Timeline updates

## Architecture

``` text
Feature Package
      │
      ▼
 Domain Event
      │
      ▼
   Event Bus
      │
 ┌────┼────┬──────┬────────┬────────┐
 ▼    ▼    ▼      ▼        ▼
Search Timeline AI Analytics Automation Notifications
```

## Event Types

### Domain Events

-   ExpenseCreated
-   ExpenseUpdated
-   TaskCompleted
-   ReminderCreated
-   NoteCreated
-   SubscriptionRenewed

### Platform Events

-   WorkspaceActivated
-   WorkspaceSwitched
-   ThemeChanged
-   DashboardChanged
-   PackageLoaded

### System Events

-   InternetConnected
-   InternetDisconnected
-   AppForegrounded
-   AppBackgrounded
-   BatteryLow

## Event Rules

-   Events represent facts.
-   Events are immutable.
-   Use past-tense names.
-   Publish only after successful persistence.
-   Never publish commands as events.

## Event Lifecycle

User Action → Feature Package → Business Logic → Persist Data → Publish
Event → Event Bus → Subscribers Execute

## Subscribers

-   Timeline Service
-   Search Service
-   AI Service
-   Analytics Service
-   Automation Service
-   Notification Service
-   Dashboard Manager

## Error Handling

-   Isolate subscriber failures.
-   Continue notifying remaining subscribers.
-   Log failures.
-   Retry support may be added later.

## Versioning

Example: - ExpenseCreatedV1 - ExpenseCreatedV2

## Future Enhancements

-   Event persistence
-   Event replay
-   Cloud synchronization
-   Debug tracing

## Design Principles

-   Publish once.
-   Consume independently.
-   Never couple Feature Packages.
-   Runtime routes events.
-   Platform Services react to events.

## AI Context

-   Publish Domain Events after successful persistence.
-   Never communicate directly between Feature Packages.
-   Keep events immutable.

## ADR-006

**Decision:** All cross-package communication occurs through the Event
Bus.
