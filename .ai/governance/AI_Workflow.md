# AI Workflow

**Version:** v1.0

## Purpose
Defines the standard workflow for AI assistants working on the Personal OS repository.

## Workflow

1. Load `.ai/Master_Context.md`
2. Read relevant architecture documents (DOC-001–DOC-030)
3. Read relevant ADRs
4. Inspect existing implementation
5. Verify architecture compliance
6. Produce implementation plan
7. Wait for approval if required
8. Implement approved scope
9. Run analyzer and tests
10. Update documentation
11. Produce implementation report

## Architecture Rules

- Never redesign approved architecture.
- Never duplicate platform infrastructure.
- Reuse existing services first.
- Propose an ADR for architectural changes.

## Quality Gates

- Analyzer clean
- Tests passing
- Dependency rules respected
- Documentation updated
- Public APIs stable

## Deliverables

Every implementation report should include:

- Summary
- Files created
- Files modified
- Tests
- Architecture compliance
- Risks
- Technical debt
- Next steps
