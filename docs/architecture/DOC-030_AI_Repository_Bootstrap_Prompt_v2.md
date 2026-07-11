# DOC-030 --- AI Repository Bootstrap Prompt

## Objective

Generate the repository exactly according to approved architecture.

## Inputs

-   Master_Context.md
-   DOC-001--DOC-029
-   ADRs
-   Coding Standards

## Rules

-   Never redesign architecture.
-   Preserve dependency boundaries.
-   Use dependency injection.
-   Generate documentation stubs.
-   Ensure project builds.

## Deliverables

1.  Monorepo
2.  Packages
3.  Features
4.  Shared modules
5.  CI
6.  GitHub Actions
7.  Melos
8.  Linting
9.  Build verification

## Validation Checklist

-   No circular dependencies
-   Analyzer passes
-   Tests execute
-   Build succeeds
-   Documentation generated
