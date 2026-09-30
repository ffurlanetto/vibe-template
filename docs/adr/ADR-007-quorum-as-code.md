# ADR-007: The cohort's arithmetic is a script, not a paragraph

**Date:** 2026-09-30
**Status:** Accepted
**Deciders:** vibe-template maintainers
**Component(s):** `scripts/quorum.py`, `.claude/skills/build`, `scripts/test-quorum.sh`

---

## Context

ADR-005 gave `/build` a protocol: a cohort of implementers, an objective gate, a
three-lens jury, a quorum, a consolidation step and a bounded loop. All of it was
written as prose in `SKILL.md` — instructions to a model.

The pull request that shipped it said plainly that this was its least-proven
piece: the agents existed and their frontmatter was validated, but nothing proved
that a jury's verdicts produced the right decision. Sections 6 to 8 contained
eleven numeric rules and not one test.

The rules are also exactly the kind that fail quietly. "At least 2 of 3", "≥ 21 /
30", "iteration == ceiling", "two iterations with no gain" are off-by-one
hazards, and a model applying them from memory at the end of a long orchestration
will get them nearly right. Nearly right, in a gate, is indistinguishable from
right until the one time it matters.

Two rules were not merely untested but genuinely undecided. "On a tie, the one
with the simpler structure" gave no metric. The ratchet "rejects" an iteration
without saying what rejection does next. Both were arbitrations dressed as rules.

## Decision

Extract the arithmetic into `scripts/quorum.py`: one JSON bundle on stdin, one
decision object on stdout.

It owns what can be counted — the gate, the quorum, the blocking axes, the
threshold, the tie-break, the ratchet, the ceiling and the diminishing-returns
stop. It does not own what must be read: whether two candidates' strengths
actually compose is a judgement about source code that no arithmetic reaches, so
`complementary_strengths` arrives as an input from the jury rather than being
inferred.

The two undecided rules are now decided. The tie-break is total, then
`files_changed`, then `lines_changed`, then the lexicographically first id — the
last step arbitrary and reported as such, because a deterministic arbitrary beats
a coin flip nobody can reproduce. The ratchet became a **field**, not a fifth
decision: `ratchet: "rejected"` with `base: "previous-best"`, while the decision
stays `ITERATE`. It answers *what do we build on*, not *what do we do next*, and
one token cannot carry both questions. A rejected iteration still spends a
ceiling slot, or a cohort that regresses every round would loop forever — which
is the failure the ceiling exists to prevent.

**Malformed input refuses.** Exit 2, the reason on stderr, nothing on stdout, and
no decision. A bundle with two `code-reviewer` entries, a renamed axis, a score
of `9.5` or a `gate` reading `"true"` is refused rather than coerced. The
alternative — defaulting — means a parse error can ship an unreviewed candidate,
and every plausible default is wrong in a different way.

**Jurors' prose never leaves the script.** Strengths and blocking findings are
model output about someone's source tree; they may quote a credential. The
decision object carries ids, numbers and the script's own sentences. The
orchestrator already holds the prose and does not need it echoed.

### What this is not

It is **advisory arithmetic with a testable core**, not an enforced guarantee.

A11 says a rule that must hold regardless of what the model decides belongs in a
hook. This is not that, and the distinction matters enough to write down: there
is no tool call to intercept — the decision happens between two agent runs — so
the orchestrator is *instructed* to call the script, not prevented from skipping
it, and every input is supplied by a model.

What the extraction actually buys: the rules are now testable and tested, two
arbitrations became decisions, and malformed input fails loudly. Section 6
requires the returned object to be pasted into the report, which makes a skipped
call visible to a reader. That is the honest claim; claiming enforcement would be
the kind of overstatement this template exists to prevent.

## Consequences

**Good**
- 64 assertions where there were none, at the boundaries rather than near them:
  exactly 21, exactly 2 PASS, `iteration == ceiling`, one flat iteration versus
  two, each blocking axis on its own.
- A jury that wants to accept at 20/30 now edits a rule in a file rather than
  reasoning past a sentence. That is the point.
- The script is pure — no file, no network, no environment — so it is trivially
  testable and cannot become stateful by accident.

**Bad**
- One narrow permission entry, `Bash(python3 scripts/quorum.py*)`, which ships to
  every generated project. The alternative was to name a `make` target so that it
  slipped under the existing `Bash(make test*)` grant, which would be abusing the
  command contract to dodge a permission — worse than asking for one.
- `quorum.py` and `test-quorum.sh` now ship with every project, because
  `.claude/skills/` is copied whole and a skill pointing at a file that was never
  installed is its own kind of broken.
- `/build` is still unproven end to end. This ADR covers its arithmetic, not its
  orchestration.

## Alternatives considered

**Leave the rules in prose and write the tests against the skill.** There is
nothing to run: a markdown section has no exit code.

**A hook.** Nothing to hook onto. The decision sits between two agent runs, not
at a tool call, which is precisely why D7 chose a script.

**Have the script judge complementarity too.** It would have to read the
candidates' diffs, which makes it a reviewer rather than a calculator, and a
calculator is the only part of this that can be trusted without review.

## References

- ADR-005 — the cohort, the jury and the bounded loop this arithmetic serves
- AGENTS.md A11 — picking the right extension mechanism, and its limits
- `.claude/skills/build/SKILL.md` §5–§8
