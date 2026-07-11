# DOC-023 --- Coding Standards

**Version:** 1.0 **Status:** Draft (Review 1) **Category:** Engineering

## Purpose

Defines coding standards to ensure consistency, maintainability and
AI-friendly development.

## Principles

-   Readability over cleverness
-   SOLID principles
-   Composition over inheritance
-   Clean Architecture
-   Domain-Driven Design where appropriate
-   Testable code

## Naming

-   Classes: PascalCase
-   Methods: camelCase
-   Variables: camelCase
-   Constants: UPPER_SNAKE_CASE
-   Files: snake_case (where language allows)

## Architecture Rules

-   Business logic belongs in Feature Packages.
-   Platform code remains reusable.
-   UI contains no business logic.
-   Use dependency injection.
-   Avoid circular dependencies.

## Error Handling

-   Fail gracefully.
-   Use typed exceptions/results.
-   Centralized logging.

## Testing

-   Unit tests for business logic.
-   Widget/UI tests where valuable.
-   Integration tests for platform services.

## Documentation

-   Public APIs documented.
-   ADR for major architectural changes.
-   Keep docs updated with implementation.

## AI Context

Generate simple, modular, documented code that follows project
architecture and avoids duplication.

## ADR-023

**Decision:** Adopt consistent coding standards emphasizing readability,
modularity and long-term maintainability.
