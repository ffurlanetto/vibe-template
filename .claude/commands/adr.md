---
description: Create a numbered ADR in docs/adr/ — use before any architectural decision
---

Create an Architecture Decision Record for the following decision.

**Steps:**
1. Read `docs/adr/README.md` to determine the next sequential number
2. Create `docs/adr/ADR-NNN-short-kebab-case-title.md`
3. Fill all sections with the provided context
4. Update the table in `docs/adr/README.md`
5. Confirm the path and number of the created file

---

**Template to follow:**

```markdown
# ADR-NNN: [Full decision title]

**Date:** YYYY-MM-DD
**Status:** Proposed
**Deciders:** [team or people involved]
**Component(s):** [impacted module / service / layer]

---

## Context

[Describe the situation, problem, or need that motivates this decision.
Include relevant technical, regulatory, or organizational constraints.]

## Decision

[State the decision clearly, affirmatively, and unambiguously.]

## Rationale

[Why this option over the alternatives.
Technical, operational, economic, or compliance arguments.]

## Consequences

### Positive
- [Concrete benefit]

### Negative / Trade-offs
- [Cost or limitation knowingly accepted]

### Neutral
- [Notable neutral impact]

## Alternatives considered

### [Alternative 1 — short name]
- Description: ...
- Rejected because: ...

### [Alternative 2 — short name]
- Description: ...
- Rejected because: ...

## Implementation

- [ ] [Concrete implementation task]
- [ ] Validation tests
- [ ] Documentation updated

## References

- [Document, RFC, article, or related ADR]
- Related ADRs: ADR-XXX
```

---

Decision to document: $ARGUMENTS
