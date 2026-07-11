# DOC-013 --- Entity Linking Architecture

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Core
Platform

## Purpose

Defines how entities from different Feature Packages can be related
without creating direct dependencies.

## Goals

-   Universal linking
-   Loose coupling
-   Workspace-scoped relationships
-   Support manual and intelligent linking

## Link Types

-   Manual Link
-   Automatic Link (rules)
-   Smart Link Suggestion (AI)

## Supported Relationships

-   Related To
-   Parent Of
-   Child Of
-   Depends On
-   References
-   Duplicate Of

## Architecture

Entity A → Entity Linking Service → Link Store → Entity B

## Link Record

-   LinkId
-   WorkspaceId
-   SourceEntityId
-   SourceEntityType
-   TargetEntityId
-   TargetEntityType
-   RelationshipType
-   CreatedAt

## Rules

1.  Entities never store direct references to other Feature Package
    entities.
2.  Entity Linking Service owns all relationships.
3.  Links are Workspace-scoped.
4.  AI may suggest links but never creates them automatically without
    user approval.

## Future

-   Graph visualization
-   Bidirectional navigation
-   Relationship analytics
-   AI relationship discovery

## AI Context

Always use the Entity Linking Service for cross-package relationships.

## ADR-013

**Decision:** Cross-package relationships are managed centrally by the
Entity Linking Service using manual, automatic and AI-assisted links.
