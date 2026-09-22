---
name: review
description: Quality, security and performance review of the code changed in this session or branch. Use before opening a pull request or committing a significant change.
argument-hint: [optional scope or branch]
allowed-tools: Read, Glob, Grep, Bash(git diff*), Bash(git log*), Bash(git status), Bash(make lint), Bash(make typecheck)
---

Perform a complete review of the code modified in this session.
Adapt verifications to the language and stack defined in Part B of AGENTS.md.

**Steps:**
1. Identify the modified files (`git diff --stat` against the base branch)
2. Apply every grid below
3. Produce the structured report

---

## Grid — Architecture & Design
- [ ] Separation of concerns respected (no business logic in controllers / handlers)
- [ ] Explicit interfaces / contracts between components
- [ ] No tight coupling introduced between distinct modules
- [ ] Project naming conventions respected (B3)
- [ ] No logic duplication (DRY)
- [ ] Reasonable cyclomatic complexity, one abstraction level per function

## Grid — Tests
- [ ] Every new public function / method has at least one test
- [ ] Nominal cases AND error cases covered
- [ ] Naming convention respected: `[Subject]_[Scenario]_[Result]`
- [ ] No conditional logic inside tests
- [ ] Mocks limited to system boundaries (I/O, network, time)
- [ ] Tests are deterministic (no dependency on external state)

## Grid — Code quality
- [ ] No silently swallowed error
- [ ] Errors wrapped with explicit context
- [ ] No `print` / `console.log` / equivalent in production code
- [ ] Documentation comments on public exports
- [ ] TODO only with ticket reference
- [ ] No dead or commented-out code

## Grid — Security (A5)
- [ ] No hardcoded secret
- [ ] Inputs validated server-side before processing
- [ ] Generic API error messages (detail in logs only)
- [ ] Permissions verified before sensitive operation
- [ ] No sensitive data in logs
- [ ] No critical CVE in new dependencies

## Grid — Data & Persistence (if applicable)
- [ ] Prepared statements or ORM — no SQL string concatenation
- [ ] Consistent transactions (no unhandled partial writes)
- [ ] Project-specific constraints respected (B6)

## Grid — Performance (budgets in B6)
- [ ] No N+1 queries on list endpoints
- [ ] Indexes present on frequently filtered / joined columns
- [ ] No long-running transactions blocking rows
- [ ] Collection endpoints return paginated responses
- [ ] No sequential external calls where parallel calls are possible
- [ ] Frontend: no full re-render on partial state change
- [ ] Frontend: images optimized, route-level bundle splitting

## Grid — Observability (A8)
- [ ] New entry points instrumented (span + metric)
- [ ] Error paths logged at the right level, without PII

---

## Report format

```
## Code Review — [date]

### Files analyzed
- [list]

### Overall score
🟢 PASS | 🟡 ATTENTION (points to address) | 🔴 BLOCKING (must fix before merge)

### Blocking issues
- [description + file:line + suggested fix]

### Attention points
- [description + file:line + recommended improvement]

### Positive notes
- [good practice observed]

### Required actions before merge
- [ ] [Action 1]
```

$ARGUMENTS
