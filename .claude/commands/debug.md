---
description: Systematic debugging workflow — reproduce, isolate, hypothesize, fix, verify
---

Apply a structured debugging process to the problem described.

**Absolute rules:**
- Write a test that reproduces the bug BEFORE proposing a fix
- Do not refactor at the same time as fixing
- The fix must be minimal — one root cause at a time
- Validate that the full test suite passes after the fix

---

## Step 1 — Reproduce

Describe the exact conditions of the bug:
- Input / state that triggers the problem
- Observed behavior vs expected behavior
- Version, environment, stack trace if available
- Frequency: systematic / intermittent / conditional

```
Environment  : [dev | staging | prod]
Reproducible : [always | sometimes — estimated frequency]
First seen   : [date / commit if known]
Stack trace  :
[paste here]
```

## Step 2 — Isolate

Identify the faulty component by narrowing the scope:
- Which module / layer is involved?
- What was the last known change in this area?
- Do logs / traces confirm the location?
- Does an existing test cover this path?

## Step 3 — Hypotheses

Formulate at most 3 root cause hypotheses, in descending probability order:

```
Hypothesis 1: [description] — probability: [high | medium | low]
  → How to validate: [command / test / inspection]

Hypothesis 2: [description] — probability: [high | medium | low]
  → How to validate: [command / test / inspection]

Hypothesis 3: [description] — probability: [high | medium | low]
  → How to validate: [command / test / inspection]
```

## Step 4 — Regression test (before the fix)

Write a test that:
- Reproduces the bug deterministically
- Fails with the current code
- Will pass after the correct fix

Naming convention: `[Component]_[BugScenario]_[ExpectedBehavior]`

## Step 5 — Minimal fix

Propose the smallest possible correction:
- Single change, single root cause
- No adjacent refactoring (open a separate issue if needed)
- Document the WHY in the commit if non-obvious

## Step 6 — Validation

```bash
# Targeted test (must pass)
<test_cmd> [filter on the test written in step 4]

# Full suite (zero regressions)
<test_cmd>

# Lint / type-check
<lint_cmd>
```

### Closure criteria
- [ ] Regression test written and green
- [ ] Full suite: zero regressions
- [ ] Lint / type-check: zero warnings
- [ ] Root cause documented in the commit or a comment if non-obvious
- [ ] Refactoring issue created if cleanup was identified but deferred

---

Problem to analyze: $ARGUMENTS
