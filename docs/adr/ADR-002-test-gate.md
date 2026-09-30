# ADR-002: The test gate — a constraint with an auditable way out

**Date:** 2026-09-27
**Status:** Accepted
**Deciders:** vibe-template maintainers
**Component(s):** `.claude/hooks/`, `.claude/skills/{plan,spec,tdd,review}`, scaffolder

---

## Context

v3.0.0 made one rule binding and left the rest as instructions. A `PreToolUse`
hook refuses a commit whose staged diff contains a secret, and it works
regardless of what the model concludes.

Testing got no such treatment. Rule A4 asks for 80% branch coverage, the `plan`
skill asks which functions to cover, and `tdd` describes a red-green-refactor
loop — all of it context, none of it enforced. The failure mode is well known:
under pressure, in a long session, after a compaction, an agent ships the
implementation and postpones the test. Nothing stops it, and nothing records
that it happened.

The template's own rule (A11) says what to do about that: *a rule that must hold
regardless of what the model decides belongs in a hook.*

## Decision

1. A `PreToolUse` hook on `git commit` **refuses** a commit whose staged diff
   touches source files without touching any test file.
2. What counts as source and as test is declared per project in
   `.claude/test-policy.json` — three glob lists: `sources`, `tests`, `exempt`.
   The scaffolder writes it from the stack module; built-in defaults cover a
   project that has none.
3. The way out is a commit trailer, `Test-Exempt: <reason of 15+ characters>`.
   The hook accepts it, prints it, and the reason **stays in the git history**.
4. Test scenarios move into the analysis phase: `spec` produces a numbered
   matrix (`SC-n`) tied to the functional requirements, `plan` carries it,
   `tdd` names the scenario each red test covers, and `review` fails when a
   scenario has no test.
5. A read-only `test-architect` agent produces the matrix. It has no `Write`
   tool, so it cannot drift into implementation.

## Rationale

**Why a hook rather than a stronger instruction.** An instruction competes with
everything else in the context window. A hook does not compete; it runs. The
secret scanner proved the pattern in v3.0.0, and the same argument applies
verbatim to tests.

**Why a declared policy rather than a heuristic.** Guessing test files from
their names breaks immediately across fourteen stacks: `internal/`, `spec/`,
`*_test.go`, `*Test.java`, `tests/unit/`. Globs in a committed file are
readable, reviewable and editable by the team that owns the repository.

**Why an exemption exists at all.** A rule with no escape gets bypassed, and the
bypass most readily at hand is `git commit --no-verify` — invisible in review
and already forbidden by A3. A trailer is the opposite: it costs one line, it
demands a reason, and the reason is preserved in the history where a reviewer
will see it. The exemption is not a weakness in the rule; it is what keeps the
rule from being routed around.

**Why 15 characters.** Long enough to rule out "wip" and "n/a", short enough not
to be an obstacle for a genuine case.

**Why the scenario matrix belongs in analysis.** A test written after the
implementation tests what the code does. A scenario written before it tests what
the code should do. Only the second catches a missing requirement, which is why
the matrix is an input to the plan rather than an output of the code.

## Consequences

### Positive
- A commit without a test is refused, not merely discouraged
- Every exemption is justified and auditable in `git log`
- Requirements and tests are linked by an identifier, so an uncovered
  requirement is mechanically detectable rather than a matter of judgement
- The phase boundary between designing scenarios and writing code is enforced by
  the absence of a tool, not by a reminder

### Negative / Trade-offs
- A legitimate commit with no behavior change — a pure rename, a refactor —
  needs the trailer. Accepted: the friction is one line, and a rising trailer
  rate is a signal that the policy's globs need fixing, not that the rule is wrong
- The policy file is one more artifact to keep current as a project's layout moves
- The gate governs the agent's `Bash` tool only. A human committing from their own
  shell is unaffected

### Neutral
- An absent or malformed policy file never blocks: the hook falls back to the
  built-in defaults and warns

## Alternatives considered

### Coverage threshold in CI instead of a commit gate
- Description: let the commit through, fail the pipeline below 80%.
- Rejected because: the feedback arrives after the work is packaged, and a
  coverage number is satisfied by tests that assert nothing. It is a useful
  second line of defence, not a substitute.

### A git `pre-commit` hook for everyone
- Description: install a git-side hook so humans are covered too.
- Rejected because: overwriting a team's git hooks is intrusive, and the problem
  being solved is an agent that forgets. Out of scope, stated as a non-goal.

### No exemption at all
- Description: refuse every commit that touches source without a test, full stop.
- Rejected because: it would make `--no-verify` the normal path within a week.
  A documented, auditable exemption beats an undocumented bypass.

### Heuristic detection of test files
- Description: infer test files from path substrings.
- Rejected because: it is wrong often enough across fourteen stacks to teach
  people to distrust the gate.

## Implementation

- [x] `.claude/test-policy.json` with defaults for the fourteen stacks
- [x] `.claude/hooks/require-tests.sh`, stdin-JSON and argv modes
- [x] Wired in `.claude/settings.json` and in the opencode guardrail plugin
- [x] `TEST_SOURCES` / `TEST_PATTERNS` in the fourteen stack modules
- [x] Scenario matrix in `spec`, `plan`, `tdd`, `review`
- [x] `test-architect` agent, read-only
- [x] Covered by `scripts/test-hooks.sh`

## References

- ADR-001 — agent-governed development workflow
- AGENTS.md A4 (tests), A5 (security checklist), A11 (rule versus hook)
