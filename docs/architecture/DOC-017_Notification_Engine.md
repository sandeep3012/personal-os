# DOC-017 --- Notification Engine

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Intelligence

## Purpose

Provides a centralized notification platform for reminders, alerts and
event-driven user notifications.

## Principles

-   Platform-wide service
-   Workspace scoped
-   Event-driven
-   User configurable
-   Offline-first

## Architecture

Event Bus → Notification Engine → Scheduler → Local Notification
Provider → User

## Notification Types

-   Reminder
-   Alert
-   Information
-   Warning
-   Automation
-   AI Suggestion

## Sources

-   Finance
-   Tasks
-   Habits
-   Documents
-   Automation
-   AI
-   Platform Runtime

## Features

-   Scheduling
-   Recurring notifications
-   Action buttons
-   Notification history
-   Snooze
-   Dismiss

## Rules

1.  Notifications respect user preferences.
2.  Scheduling is Workspace-specific.
3.  Platform Services publish notification requests.
4.  Engine manages delivery.

## Future

-   Push notifications
-   Email notifications
-   Wearable notifications
-   Cross-device sync

## AI Context

Notification Engine subscribes to events and schedules notifications
through platform providers.

## ADR-017

**Decision:** Notification delivery is centralized in a reusable
Notification Engine.
