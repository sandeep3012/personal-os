# DOC-014 --- AI Architecture

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Intelligence

## Purpose

Defines how AI integrates with Personal OS while remaining optional,
provider-agnostic and privacy-first.

## Principles

-   AI enhances, never replaces user control.
-   Offline-first architecture.
-   Provider independent.
-   Workspace-scoped context.
-   User approval for AI actions.

## Components

-   AI Gateway
-   Prompt Manager
-   Context Builder
-   AI Memory
-   Provider Adapter
-   Insight Engine

## Responsibilities

### AI Gateway

Routes all AI requests through a single abstraction.

### Context Builder

Collects relevant workspace data while respecting permissions.

### AI Memory

Stores reusable AI context for each Workspace.

### Insight Engine

Generates suggestions, summaries and recommendations.

## AI Features

-   Expense insights
-   Budget recommendations
-   Smart search
-   Task prioritization
-   Habit analysis
-   Document summaries
-   Subscription analysis

## Providers

Support multiple providers: - OpenAI - Anthropic - Google - Local LLM
(future)

## Rules

1.  AI never modifies data without user confirmation.
2.  AI providers are replaceable.
3.  Prompts are versioned.
4.  Sensitive data remains local unless explicitly shared.

## Future

-   Offline local models
-   Voice assistant
-   AI workflows
-   Predictive automation

## AI Context

All Feature Packages use the AI Gateway. Never call AI providers
directly.

## ADR-014

**Decision:** AI is implemented as a Platform Service through an AI
Gateway with provider abstraction.
