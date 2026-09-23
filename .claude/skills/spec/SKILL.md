---
name: spec
description: Write a numbered functional specification in docs/specs/ before building a user-facing feature. Use when the request describes a behavior rather than a technical change, or when acceptance criteria are not yet agreed.
argument-hint: [feature to specify]
allowed-tools: Read, Glob, Grep, Write, Edit
---

Produce a functional specification **before** any design or code.

**Steps:**
1. List the existing files in `docs/specs/` to determine the next number
2. Create `docs/specs/SPEC-NNN-short-kebab-case-title.md` from the template below
3. Leave every unknown as an explicit `❓ OPEN QUESTION` — never invent a requirement
4. Report the path and the open questions that block implementation

A spec describes **what** and **why**, never **how**. Implementation choices belong
in an ADR (`/adr`) or a plan (`/plan`).

---

```markdown
# SPEC-NNN: [Feature title]

**Date:** YYYY-MM-DD
**Status:** Draft | Approved | Implemented
**Author:** [name]
**Related:** ADR-XXX · issue PROJ-123

## Problem
[Who has this problem, how often, what it costs today.]

## Goal
[One sentence. The outcome, not the solution.]

## Non-goals
- [Explicitly out of scope]

## Actors
| Actor | Role | Permissions |
|-------|------|-------------|

## Functional requirements
| # | Requirement | Priority |
|---|-------------|----------|
| FR-1 | The system MUST ... | must |
| FR-2 | The system SHOULD ... | should |

## User flows
### Nominal flow
1. ...

### Error flows
| Case | Expected behavior | User-facing message |
|------|-------------------|---------------------|

## Acceptance criteria
- [ ] Given [context], when [action], then [observable result]

## Non-functional requirements
- Performance: [budget — see B6]
- Security: [authn/authz, sensitive data]
- Observability: [events and metrics to emit — see A8]
- Compliance: [see B6]

## Open questions
- ❓ [Question blocking implementation]
```

---

Feature to specify: $ARGUMENTS
