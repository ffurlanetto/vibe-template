---
name: plan
description: Generate a structured implementation plan and wait for explicit approval before any development. Use at the start of every non-trivial request, as required by rule A1.
argument-hint: [request to plan]
allowed-tools: Read, Glob, Grep, Bash(git status), Bash(git diff*), Bash(git log*)
---

Analyze the request below and produce a plan an implementer can execute **without
arbitrating anything**.

That is the bar. If a coding agent reading this plan would have to decide where a
type lives, what an error returns, or which of two designs to follow, the plan is
not finished — no matter how complete the step list looks.

**Absolute rules:**
- Every architectural question raised during analysis gets an answer *here*, with
  its reason. "Questions ouvertes" must end up empty
- Every file touched is named with its full path, and every public signature it
  gains or changes is written out
- Every step references the test scenarios (`SC-n`) it must satisfy
- Do NOT write any code — plan only
- End with the approval line

**Adapt to the stack in Part B of AGENTS.md.** Commands are the `make` targets in B4.

---

```
## Plan: [Concise task title]

### Context
[Problem solved, value delivered, relationship to project components]

### Scope
- Files created    : [full paths]
- Files modified   : [full paths]
- Files deleted    : [list or "none"]
- Impacted components : [modules/services/packages]
- ADR required  : yes / no — [if yes: proposed title]
- Spec required : yes / no — [if yes: proposed title]

### Decisions taken
[Every question the analysis raised, answered. This is what stops an implementer
from doing architecture in passing.]

| # | Question | Decision | Why |
|---|----------|----------|-----|
| D1 | [where does X live / what does Y return / which of A or B] | [the answer] | [the reason, in one line] |

### Open questions
[Blocking ambiguities. **If this section is not empty, the plan is not approvable** —
resolve them or return to /spec.]
- [question, or "none"]

### Contracts
[Per file, what the implementer writes. Signatures, not prose.]

**`path/to/file.ext`**
- `functionName(arg: Type, ...) -> ReturnType` — [what it guarantees]
- Raises / returns on error: [case → error type → status code → client message → log level]
- May depend on: [allowed imports]; must not depend on: [forbidden direction]

### Test scenarios
[From /spec or the test-architect agent. The plan carries them; it does not invent them.]

| ID | Given | When | Then | Level |
|----|-------|------|------|-------|
| SC-1 | ... | ... | ... | unit |

### Implementation steps
[Each step names its files and the scenarios it makes pass.]

1. [Precise action] — `file(s)` — satisfies SC-1, SC-2
2. [...]

### Acceptance criteria
- [ ] Every `SC-n` has a test that failed before the change
- [ ] [Measurable criterion]
- [ ] `make check` green — zero regressions
- [ ] Security checklist (A5) completed

### Risks & trade-offs
- [Identified risk → proposed mitigation]

### Documentation
- [ ] ADR created if architectural decision
- [ ] Documentation comments on public exports
- [ ] README / CHANGELOG updated if applicable

---
Certification: [ ] executable without arbitration — reviewed by `architect`
✅ Awaiting approval before implementation.
```

## Before you present it

Hand the plan to the `architect` agent. Its verdict is `PLAN-CERTIFIED` or
`PLAN-BLOCKED` with the arbitrations still left open. A blocked plan goes back
around; it is not presented for approval.

Skip that round only for a change confined to one file with no new public
signature — and say that you skipped it.

---

Request to analyze: $ARGUMENTS
