# Architecture Review Checklist

**Version:** v1.0

## Repository

- [ ] Repository structure follows Repository_Tree.md
- [ ] Package boundaries respected
- [ ] No forbidden dependencies

## Architecture

- [ ] Matches DOC-001–DOC-030
- [ ] No undocumented architecture changes
- [ ] ADR created where required

## Clean Architecture

- [ ] Business logic isolated
- [ ] Dependency inversion respected
- [ ] SOLID principles followed

## Platform

- [ ] Platform Core has no upward dependencies
- [ ] Runtime depends only on Core
- [ ] Application only orchestrates
- [ ] No Flutter UI inside platform packages

## Features

- [ ] Feature isolation maintained
- [ ] No feature-to-feature dependency
- [ ] Shared code extracted appropriately

## Code Quality

- [ ] Analyzer clean
- [ ] Tests passing
- [ ] Public APIs documented
- [ ] No TODO placeholders
- [ ] No duplicated infrastructure

## Documentation

- [ ] README updated
- [ ] Sprint Plan updated (if applicable)
- [ ] Master Context updated (if required)
