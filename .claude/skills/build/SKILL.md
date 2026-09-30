---
name: build
description: Run a change end to end with a cohort of implementers and a jury — analysis, certified plan, parallel candidates, objective gate, scored review, quorum, consolidation, bounded iteration. Use for work whose cost of being wrong is higher than the cost of running it several times.
argument-hint: [the change to build]
allowed-tools: Read, Glob, Grep, Bash(make *), Bash(git *), Bash(python3 scripts/quorum.py*)
---

Orchestrate the change below. You are the orchestrator: you delegate, you measure,
you decide. You do not implement.

`make agents` reads the ledger while this runs; every subagent start and stop is
recorded there (ADR-003).

---

## 0 — Triage, before anything else

Running a cohort on a rename is waste, and waste is why processes get abandoned.
Pick a tier and say which one you picked:

| Tier | When | Cohort | Jury | Iterations |
|------|------|--------|------|------------|
| `trivial` | one file, no new public signature, no behaviour change | none — one `implementer` | none — `/review` | 1 |
| `standard` | a feature or a fix inside one component | 2 | 3 | 3 |
| `critical` | security, money, data loss, migration, public API | 3 | 3 | 5 |

A `trivial` change never convenes a cohort or a jury: one `implementer`, then
`/review`, then step 9. It does not call `quorum.py` — there is nothing to count.

## 1 — Analysis

Run in parallel:
- `test-architect` → the `SC-n` scenario matrix from the requirements
- `architect` → the design, its trade-offs, the alternative it rejects

**Gate:** neither may leave a blocking question open. One that does goes back to
`/spec`, not forward.

## 2 — A plan that decides everything

Produce it with `/plan`: decisions taken, open questions empty, contracts with
signatures and error behaviour, every step tied to its scenarios.

**Gate:** `architect` returns `PLAN-CERTIFIED`. A `PLAN-BLOCKED` plan is fixed and
re-certified. Never hand a cohort a plan that leaves arbitrations open — you will
get divergent candidates and no way to tell which divergence was legitimate.

## 3 — The cohort

Launch N `implementer` agents **in parallel**, each with the same certified plan.
They run in isolated worktrees, so they do not collide.

Give every one of them the same brief. Resist the urge to steer them differently:
the variance you want comes from the model, not from you biasing one candidate.

## 4 — The objective gate, before any opinion

For each candidate: `make check`.

A candidate that fails is **disqualified**, full stop — no juror reads it. This
step is what stops the jury from rewarding elegant code that does not work, and it
costs nothing but a command.

If every candidate fails the gate, the plan is the suspect, not the implementers.
Go back to step 2.

## 5 — The jury

Three lenses, all read-only, all already specialists:

| Juror | Axis | Blocking |
|-------|------|----------|
| `code-reviewer` | correctness and design | **yes** |
| `security-auditor` | security | **yes** |
| `test-architect` | do the tests actually cover every `SC-n`? | no |

Each juror returns, per candidate:

```
CANDIDATE: [id]
SCORE: [0-10]
VERDICT: PASS | FAIL
BLOCKING: [findings that justify a FAIL, with file:line — or "none"]
STRENGTH: [what this candidate does better than the others, named precisely]
```

Two instructions to every juror: run the candidate's tests before scoring it, and
name what it does *better* — that is the input the consolidation step needs.

A third: end with the same verdict as a fenced `json` object.

```json
{"agent": "code-reviewer", "score": 8, "verdict": "PASS",
 "blocking": [], "strength": "error paths are exhaustive"}
```

The block above is what step 6 reads. Asking for it is not ceremony: without it
somebody has to transcribe free text into numbers, and that somebody is a model
scoring its own cohort. Transcription is the seam where a verdict can quietly
become a different verdict, so it is removed rather than supervised.

## 6 — Quorum

A candidate is accepted when **all** of:

- the objective gate is green (step 4 — not scored, required)
- at least **2 of 3** jurors return `PASS`
- **no** `FAIL` from `code-reviewer` or `security-auditor` — those two axes are
  blocking, a FAIL there ends it whatever the totals say
- total score **≥ 21 / 30**

Several candidates pass → the highest total; on a tie, the fewer files changed,
then the fewer lines, then the lexicographically first id.

**Do not apply these by hand.** Assemble the jurors' JSON blocks into a bundle and
let `scripts/quorum.py` return the decision:

```bash
python3 scripts/quorum.py <<'JSON'
{"iteration": 1, "ceiling": 3, "complementary_strengths": false,
 "metrics": {"passing_tests": 42, "coverage": 0.84},
 "history": [],
 "candidates": [
   {"id": "c1", "gate": "green", "size": {"files_changed": 4, "lines_changed": 120},
    "jurors": [ … the three blocks from step 5 … ]}]}
JSON
```

It prints one object: `decision` (`ADOPT` · `CONSOLIDATE` · `ITERATE` · `STOP`),
the winning `candidate`, the `reason`, what was `disqualified` and why, the
`ratchet` state and the `tie_break` that settled it. Exit 2 means the bundle was
malformed and **nothing was decided** — fix the bundle, never assume a verdict.

The bundle goes in on stdin and is never written to disk: it carries jurors' prose
about someone's source tree, and that does not need a file.

**Paste the returned object into the report.** It is the only evidence that the
arithmetic was applied rather than recalled, and a run whose report has no such
object is a run where nobody can tell.

Worked examples — each is asserted in `scripts/test-quorum.sh`:

| Gate | Verdicts | Total | Decision |
|------|----------|-------|----------|
| green | PASS · PASS · PASS | 21 | `ADOPT` — 21 is inside the threshold, not past it |
| green | FAIL · PASS · PASS | 27 | not adopted — a `code-reviewer` FAIL ends it whatever the total |
| green | PASS · PASS · PASS | 18, iteration 3 of 3 | `STOP` — the ceiling, with the blocker named |

## 7 — Consolidation, only when it is warranted

No candidate reaches quorum, but the jury named complementary strengths → run
`consolidator` with the base, the named contributions, and the verdicts.

It ports contributions one at a time, each followed by `make check`. If the result
is not clearly better than the base, it returns the base — which is a success.

Consolidation **counts as an iteration**.

Strengths are not complementary → go straight to iteration.

## 8 — Iterate, with a ratchet

No quorum yet → feed the blocking findings back to the cohort and run again.

Three rules keep this from becoming churn:

- **Ceiling**: the tier's iteration count. It is a maximum, never a target
- **Ratchet**: an iteration that lowers the number of passing tests, the coverage,
  or the total score is **rejected** — you keep the previous best. The script
  reports this as `ratchet: "rejected"` with `base: "previous-best"`; it is not a
  decision of its own, because it answers *what do we build on*, not *what next*.
  A rejected iteration still spends a slot against the ceiling — otherwise a
  cohort that regresses every round would loop forever
- **Diminishing returns**: two iterations with no measurable gain → stop, even at
  iteration 2. A loop optimising a criterion it cannot move is burning budget

## 9 — Deliver

Quorum reached → `/ship`: branch, commits, push, draft PR, wait for the build,
promote to ready or fix (A14).

## 10 — Or stop, and say so

Ceiling reached without quorum → **stop and report**. Do not ship the best of a bad
set, and do not quietly relax the quorum.

```
## Build failed to reach quorum — [task]

Tier        : [trivial | standard | critical]
Iterations  : [n] of [max]   Cohort: [n]   Consolidation: [yes/no]

Best candidate : [id] — [total]/30
  code-reviewer    [score] [PASS/FAIL] — [blocking finding]
  security-auditor [score] [PASS/FAIL] — [blocking finding]
  test-architect   [score] [PASS/FAIL] — [uncovered SC-n]

What is blocking : [the finding no iteration could clear]
What I would need: [a decision, a missing requirement, access, a different approach]
Where it is      : [worktree or branch, so nothing is lost]
```

A clear stop with a named blocker is a better outcome than a shipped guess.

---

Change to build: $ARGUMENTS
