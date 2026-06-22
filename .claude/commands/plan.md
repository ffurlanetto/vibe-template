---
description: Generate a structured implementation plan — waits for explicit approval before any development
---

Analyze the request below and produce a complete implementation plan.

**Absolute rules:**
- Exhaustiveness: list every file touched, every required test, every impacted component
- Explicitly identify regression risks
- Do NOT write any code — plan only
- End with the mandatory approval line

**Adapt the plan to the language and stack defined in Part B of CLAUDE.md.**
The test, lint, and build tools to reference are those defined in B4.

---

```
## Plan: [Concise task title]

### Context
[Problem solved, value delivered, relationship to project components]

### Scope
- Files created    : [list with full paths]
- Files modified   : [list with full paths]
- Files deleted    : [list or "none"]
- Impacted components : [list of modules/services/packages involved]
- ADR required : yes / no — [if yes: proposed ADR title]

### Implementation steps
1. [Precise action — file(s) involved]
2. [...]

### Required tests
- Unit        : [classes / functions / methods to cover]
- Integration : [interactions to test — or "not applicable"]
- Regression  : [what could break, test suite to run]
- Security    : [checkpoints — or "not applicable"]

### Acceptance criteria
- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] Full test suite: zero regressions
- [ ] Lint / format / type-check: zero warnings
- [ ] Security checklist (A5) completed

### Risks & trade-offs
- [Identified risk → proposed mitigation]

### Documentation
- [ ] ADR created if architectural decision
- [ ] Documentation comments on public exports
- [ ] README / changelog updated if applicable

---
✅ Awaiting approval before implementation.
```

Request to analyze: $ARGUMENTS
