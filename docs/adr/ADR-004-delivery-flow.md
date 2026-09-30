# ADR-004: Delivery flow — a branch first, a draft always, and waiting for the build

**Date:** 2026-09-30
**Status:** Accepted
**Deciders:** vibe-template maintainers
**Component(s):** `AGENTS.md` A14 and B8, `.claude/skills/ship`

---

## Context

An agent that finishes a change tends to do three things badly. It edits on
whatever branch it happens to be on. It pushes and reports success, because from
its side the push succeeded. And it opens a pull request as ready, before any
build has run, which asks reviewers to look at something that may not compile.

None of the three is a reasoning failure. They are gaps in the instructions: the
template never said where a change belongs, never said a push is not the end, and
never recorded which forge the project uses or what "all checks green" names.

## Decision

1. **A branch before the first edit.** A change is never committed on the
   integration branch; the naming convention is declared in B8.
2. **A push opens a draft pull request**, always — including for a change the
   agent considers finished.
3. **Ready is earned**: CI green on the head commit, `make check` green, review
   threads resolved, no conflict, template followed.
4. **The agent waits for the build**, then promotes or fixes. Waiting is bounded
   by a budget in B8; when it expires the agent hands back the check status as it
   stands rather than waiting indefinitely or claiming success.
5. **B8 becomes the delivery contract**: forge and URL, git model, branch
   convention, tag and version format, who tags, changelog source, PR policy,
   required check names, wait budget, environments, code owners.
6. `/ship` performs the flow end to end and dispatches on the forge recorded in B8.

## Rationale

**Why a draft rather than a ready PR.** A draft costs nothing and buys two things:
CI runs, and a reviewer can look early without being asked to approve. Opening as
ready makes a promise the agent cannot keep until the build has run. Promoting
later is a deliberate act with a checklist behind it, which is exactly what the
gap needed.

**Why waiting is a rule rather than a courtesy.** "Pushed, should be fine" moves
the failure to whoever reads the pipeline next, usually hours later. The agent is
the cheapest possible fixer at that moment: it still has the context. Making it
wait is what converts a push into a delivery.

**Why the wait is bounded.** An unbounded wait turns a session into a spinning
process, and some pipelines take an hour. A budget with an honest report — "still
running after 20 minutes, here is the status" — is more useful than either
extreme.

**Why B8 rather than detection.** An agent can guess the forge from the remote
URL, but not the required check names, not the merge strategy, not who may tag.
Writing them down once removes a class of confident wrong answers, and the file
is useful to humans too.

**Why the flow is a skill and not a hook.** Unlike the test gate, there is nothing
here to forbid: the actions are legitimate, the failure is omission. A skill is
the right shape, and it is portable to opencode, which hooks around the forge
would not be.

## Consequences

### Positive
- Work in progress is visible on the forge from the first push
- A build failure is found by the agent that caused it, while the context is warm
- The delivery rules are written down once, for agents and humans alike
- Bitbucket and GitLab are first-class, not afterthoughts

### Negative / Trade-offs
- The flow needs a forge CLI (`gh`, `glab`) or a REST call. Bitbucket has no solid
  first-party CLI, so it relies on the endpoint recorded in B8 — and if that is
  missing, `/ship` stops and says so instead of pretending
- Waiting occupies the session. Bounded, and the budget is the project's to set
- A project that genuinely wants ready-on-open has to override A14

### Neutral
- The template's own repository follows this flow, which is how the gaps surfaced

## Alternatives considered

### Always open as ready, let CI fail loudly
- Rejected because: it spends reviewer attention on changes that do not build, and
  a failed check on a ready PR reads as a problem rather than as work in progress.

### Detect everything from the remote and the CI config
- Rejected because: the forge is detectable, the rest is not. Guessing the required
  check names is the kind of confident wrong answer that costs the most trust.

### A hook that refuses a push without a PR
- Rejected because: the push and the PR are two calls, and a hook on the first
  cannot know the second will follow. The problem is omission, not permission.

## Implementation

- [x] A14 in `AGENTS.md`
- [x] B8 rewritten as the delivery contract
- [x] `.claude/skills/ship/SKILL.md`, dispatching on the forge from B8
- [x] `/pr` remains the description writer, called by `/ship`

## References

- ADR-001 — agent-governed development workflow
- ADR-002 — the test gate
- AGENTS.md A3 (commit conventions), A14 (delivery flow), B8
