---
description: Quality and security review of code changed in the session — adapts checks to the project stack
---

Perform a complete review of the code modified in this session.
Adapt verifications to the language and stack defined in Part B of CLAUDE.md.

**Steps:**
1. Identify files modified in the current session
2. Apply all grids below
3. Produce the structured report

---

## Review grid — Architecture & Design

- [ ] Separation of concerns respected (no business logic in controllers / handlers)
- [ ] Explicit interfaces / contracts between components
- [ ] No tight coupling introduced between distinct modules
- [ ] Project naming conventions respected (B3)
- [ ] No logic duplication (DRY)
- [ ] Reasonable cyclomatic complexity (short functions, one abstraction level per function)

## Review grid — Tests

- [ ] Every new public function / method has at least one test
- [ ] Nominal cases AND error cases covered
- [ ] Test naming convention respected: `[Subject]_[Scenario]_[Result]`
- [ ] No conditional logic inside tests
- [ ] Mocks limited to system boundaries (I/O, network, time)
- [ ] Tests are deterministic (no dependency on external state)

## Review grid — Code quality

- [ ] No silently swallowed error
- [ ] Errors wrapped with explicit context
- [ ] No `print` / `console.log` / equivalent in production code
- [ ] Documentation comments on public exports
- [ ] TODO only with ticket reference
- [ ] No dead or commented-out code

## Review grid — Security (section A5)

- [ ] No hardcoded secret
- [ ] Inputs validated server-side before processing
- [ ] Generic API error messages (detail in logs only)
- [ ] Permissions verified before sensitive operation
- [ ] No sensitive data in logs
- [ ] No critical CVE in new dependencies

## Review grid — Data & Persistence (if applicable)

- [ ] Prepared statements or ORM — no SQL string concatenation
- [ ] Consistent transactions (no unhandled partial writes)
- [ ] Project-specific constraints respected (B6)

---

## Report format

```
## Code Review — [date]

### Files analyzed
- [list]

### Overall score
🟢 PASS | 🟡 ATTENTION (points to address) | 🔴 BLOCKING (must fix before merge)

### Blocking issues
- [description + location + suggested fix]

### Attention points
- [description + location + recommended improvement]

### Positive notes
- [good practice observed]

### Required actions before merge
- [ ] [Action 1]
- [ ] [Action 2]
```

$ARGUMENTS
