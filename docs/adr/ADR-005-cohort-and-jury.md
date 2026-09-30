# ADR-005: A cohort of implementers, a jury with a quorum, and a bounded loop

**Date:** 2026-09-30
**Status:** Accepted
**Deciders:** vibe-template maintainers
**Component(s):** `.claude/skills/build`, `.claude/agents/{implementer,consolidator}`

---

## Context

One agent producing one implementation gives one sample of a distribution. On work
where being wrong is expensive — a migration, an auth path, anything touching
money — a single sample is a thin basis for shipping, and the usual mitigation is
a human reading the diff carefully, which does not scale to every change.

Sampling several candidates and picking between them is a known answer. It has two
well-documented ways of going wrong: a judge that reads code rewards the elegant
over the correct, and a merge of two good implementations is routinely worse than
either. A third risk is specific to loops — an improvement loop with no objective
criterion optimises noise and burns budget.

The template already had the pieces: specialists that are read-only by
construction, a ledger that makes parallel agents observable, and a plan format
that leaves no arbitration open. What was missing was the protocol.

## Decision

1. **Triage first.** Three tiers — `trivial` (one implementer, no jury),
   `standard` (cohort 2, jury 3, 3 iterations), `critical` (cohort 3, jury 3,
   5 iterations). A cohort on a rename is waste.
2. **A certified plan before the cohort.** `architect` returns `PLAN-CERTIFIED`,
   or the cohort is not launched.
3. **Isolated worktrees.** `implementer` carries `isolation: worktree`, so
   candidates cannot collide.
4. **The objective gate precedes any opinion.** `make check` on each candidate; a
   failure disqualifies it before a juror reads it.
5. **Three lenses, not three copies**: `code-reviewer` (correctness, blocking),
   `security-auditor` (security, blocking), `test-architect` (scenario coverage,
   advisory). Each returns a score out of 10, a verdict, blocking findings, and —
   required — what the candidate does *better* than the others.
6. **Quorum**: gate green, ≥ 2 of 3 PASS, no FAIL on a blocking axis, total ≥ 21/30.
7. **Consolidation takes named contributions.** `consolidator` ports them one at a
   time, each followed by the gate, and returns the base unchanged when the result
   is not clearly better. It counts as an iteration.
8. **The loop is bounded three ways**: the tier's ceiling, a ratchet that rejects
   any iteration lowering score, coverage or passing tests, and a stop on two
   iterations without measurable gain.
9. **Failure is reported, not shipped.** Ceiling without quorum → stop, name the
   blocker, say where the work is.

## Rationale

**Why the gate comes before the jury.** This is the single decision that makes the
rest trustworthy. A jury that reads code scores what reads well; a jury that reads
code *which already passes its tests* scores something real. It also costs one
command, which makes it the cheapest guard in the protocol.

**Why three different specialists rather than three judges.** Three instances of
the same judge produce correlated scores — they agree, and the agreement means
nothing. Correctness, security and test coverage are genuinely different lenses,
and all three agents already existed and were already read-only.

**Why two blocking axes.** A total score lets a candidate average away a security
flaw. Correctness and security are not tradeable against elegance, so a FAIL on
either ends it regardless of the total.

**Why quorum rather than unanimity.** Unanimity gives any single juror a veto,
including on a matter of taste, and the loop then optimises for the most opinionated
reviewer. Two of three, with the blocking-axis rule as the safety net, keeps the
strictness where it belongs.

**Why 21/30.** An average of 7 across three axes: clearly above "acceptable", below
"exceptional". A threshold that is routinely met teaches nothing; one that is never
met gets lowered.

**Why consolidation is constrained and optional.** Blind merging of two structurally
different implementations produces something neither author would defend. Requiring
*named* contributions forces the jury to have identified something concrete, and
letting the consolidator return the base unchanged removes the pressure to justify
its own run.

**Why the ratchet.** A loop with a ceiling but no ratchet can spend five iterations
getting worse and ship the fifth. The ratchet makes the process monotone: the worst
outcome is the best candidate seen so far.

**Why stopping is an outcome.** The alternative — relaxing the quorum at the last
iteration — silently converts the protocol into theatre. A named blocker is
actionable; a shipped guess is not.

## Consequences

### Positive
- Expensive changes get several samples and an objective filter before any judgement
- The scores are defensible: they follow a rubric and a gate, not an impression
- Parallel work is observable live through the ledger
- The tiers keep the machinery off the 80% of changes that do not need it

### Negative / Trade-offs
- A `critical` run costs roughly 8 to 12 agent runs. That is the point, and the
  triage step is what keeps it from being the default
- Latency: a cohort runs in parallel, but the jury is a second round
- `isolation: worktree` is Claude Code only. opencode runs the same protocol
  sequentially, which is slower but produces the same verdicts

### Neutral
- The protocol is written in a skill, so a team can change a threshold in one place

## Alternatives considered

### One implementer, then a review round
- Rejected because: it is the status quo. It gives one sample and no basis for
  comparison — the reviewer can say the code is wrong, not that another approach
  was better.

### Unanimity instead of quorum
- Rejected because: a single juror's taste becomes a veto, and the loop starts
  optimising for whoever is strictest rather than for correctness.

### Always merge the best parts of every candidate
- Rejected because: structurally different implementations do not combine.
  Constrained consolidation, with the option to return the base, keeps the upside
  without the Frankenstein.

### A judge model scoring diffs without running them
- Rejected because: it is the documented failure mode of LLM-as-judge — verbosity
  and style beat correctness. The gate makes the scoring mean something.

## Implementation

- [x] `.claude/skills/build/SKILL.md` — triage, gates, quorum, ratchet, failure report
- [x] `.claude/agents/implementer.md` — `isolation: worktree`, refuses to arbitrate
- [x] `.claude/agents/consolidator.md` — named contributions, gate after each port
- [x] Jury from the existing read-only specialists
- [x] A11 in `AGENTS.md`

## References

- ADR-002 — the test gate · ADR-003 — the agent ledger · ADR-004 — delivery flow
- AGENTS.md A1 (plan first), A4 (tests), A11 (context engineering)
