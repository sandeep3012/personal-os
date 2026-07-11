# Cursor Project Rules

**Version:** v2.0  
**Repository Version:** v0.5.0-platform-foundation

---

# Source of Truth

Before making any change, load and follow:

1. `.ai/Master_Context.md`
2. Relevant architecture documents in `docs/architecture`
3. Relevant ADRs
4. Package README
5. Existing implementation

Never assume architecture.

---

# Architecture Rules

- Follow Clean Architecture.
- Respect package boundaries.
- Follow the Package Dependency Matrix.
- Never redesign approved architecture.
- Architecture changes require an ADR.
- Prefer extending existing architecture over creating new abstractions.

---

# Dependency Rules

Allowed dependency flow:

Apps

↓

Features

↓

Application

↓

Platform Runtime

↓

Platform Core

Never create:

- Feature → Feature dependencies
- Platform → Feature dependencies
- Cyclic dependencies
- UI → Business Logic dependencies

---

# Development Rules

Always:

- Reuse existing services.
- Reuse existing interfaces.
- Reuse existing exceptions.
- Reuse existing models.
- Reuse existing utilities.
- Keep public APIs stable.
- Keep classes focused.
- Prefer composition over inheritance.
- Use constructor dependency injection.
- Keep code production ready.

Never:

- Duplicate infrastructure.
- Introduce unnecessary abstractions.
- Add placeholder implementations.
- Leave TODO comments.
- Break existing APIs without approval.

---

# Platform Rules

Platform packages:

- Must remain Flutter-independent unless explicitly required.
- Must not contain UI code.
- Must not contain business logic.
- Must expose stable public APIs.

---

# Feature Rules

Each feature owns:

- Domain
- Application
- Data
- Presentation
- Tests

Features must remain isolated.

Cross-feature communication must occur through approved application services or shared contracts.

---

# Testing Rules

Every change must:

- Pass analyzer.
- Pass existing tests.
- Include new tests when required.
- Avoid reducing coverage.

---

# Documentation Rules

Update documentation whenever public behavior changes.

Examples:

- README
- Public APIs
- Architecture references

Do not modify ADRs unless explicitly instructed.

---

# AI Workflow

Before implementation:

1. Analyze existing code.
2. Verify architecture.
3. Produce a plan.
4. Implement.
5. Run tests.
6. Verify analyzer.
7. Update documentation.

---

# When Uncertain

If architecture is unclear:

- Stop implementation.
- Explain the uncertainty.
- Ask for clarification.

Never invent architecture.