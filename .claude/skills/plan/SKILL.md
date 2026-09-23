---
name: plan
description: Generate a structured implementation plan and wait for explicit approval before any development. Use at the start of every non-trivial request, as required by rule A1.
argument-hint: [request to plan]
allowed-tools: Read, Glob, Grep, Bash(git status), Bash(git diff*), Bash(git log*)
---

Analyze the request below and produce a complete implementation plan.

**Absolute rules:**
- Exhaustiveness: list every file touched, every required test, every impacted component
- Explicitly identify regression risks
- Do NOT write any code — plan only
- End with the mandatory approval line

**Adapt the plan to the language and stack defined in Part B of AGENTS.md.**
The test, lint, and build commands to reference are the `make` targets defined in B4.

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
- Spec required : yes / no — [if yes: proposed SPEC title]

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
- [ ] `make check` green — zero regressions
- [ ] Security checklist (A5) completed

### Risks & trade-offs
- [Identified risk → proposed mitigation]

### Documentation
- [ ] ADR created if architectural decision
- [ ] Documentation comments on public exports
- [ ] README / CHANGELOG updated if applicable

---
✅ Awaiting approval before implementation.
```

Request to analyze: $ARGUMENTS
