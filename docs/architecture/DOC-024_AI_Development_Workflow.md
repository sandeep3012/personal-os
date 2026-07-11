# DOC-024 --- AI Development Workflow

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Engineering

## Purpose

Defines how AI tools are used consistently throughout the development
lifecycle of Personal OS.

## Objectives

-   Increase development speed
-   Maintain architectural consistency
-   Reduce repetitive work
-   Keep humans responsible for final decisions

## AI Roles

### ChatGPT

-   Architecture
-   System design
-   Planning
-   Reviews
-   Documentation

### Claude Code

-   Feature implementation
-   Refactoring
-   Code generation

### Cursor

-   Daily development
-   Code completion
-   Small fixes
-   Navigation

## Development Flow

Requirements → Architecture → AI Prompt → Code Generation → Review →
Testing → Merge

## Rules

1.  AI follows approved architecture.
2.  Humans review every generated change.
3.  Architecture changes require ADRs.
4.  Prompts are version controlled.

## Artifacts

-   Architecture docs
-   Master Context
-   AI prompts
-   ADRs
-   Coding standards

## Future

-   Automated prompt generation
-   AI code review
-   AI test generation
-   AI documentation updates

## AI Context

Always load Master Context, relevant architecture documents and ADRs
before generating implementation.

## ADR-024

**Decision:** AI-assisted development is a first-class engineering
workflow while maintaining human architectural oversight.
