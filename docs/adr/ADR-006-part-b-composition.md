# ADR-006: The kernel and the blank Part B are composed, not copied

**Date:** 2026-09-30
**Status:** Accepted
**Deciders:** vibe-template maintainers
**Component(s):** `AGENTS.md`, `init.sh`, `templates/common/AGENTS.part-b.md`, `scripts/substitute.py`

---

## Context

`AGENTS.md` has two halves that serve different readers. Part A is the kernel —
the rules every project inherits. Part B is that project's configuration: its
stack, its commands, its delivery contract.

`init.sh` copied the file whole. That forced Part B in the repository to stay a
set of `<angle-bracket>` placeholders, because whatever is there is what a new
project receives. The cost landed on the template itself: agents working on
vibe-template read `Forge : <github | gitlab | bitbucket>` where B8 promises a
forge, and B8's own preamble names the consequence — "an empty field is a question
an agent will have to ask, or worse, answer on its own."

It was not hypothetical. Two sessions guessed at the branch convention and the
merge strategy rather than reading them, and a third had to rediscover from the
GitHub API that `main` is unprotected.

The obvious fix — keep a second, filled copy of Part B for the template — breaks
the rule this repository is built on: one source per concept, everything else
generated. Two copies of a document that describes how to work is exactly the
thing that drifts, and drift in the rules is worse than no rules.

## Decision

Split the file at its existing structural boundary, the line
`# PART B — PROJECT CONFIGURATION`.

- The repository's `AGENTS.md` keeps Part A and gains a Part B **filled in for
  vibe-template itself**.
- The blank Part B a new project starts from moves to
  `templates/common/AGENTS.part-b.md`.
- `init.sh` composes the shipped file: everything above the marker in the root
  file, then the blank Part B verbatim. The join inserts nothing — Part A ends
  with its separator and a blank line, the blank half starts at the marker, so
  concatenation reproduces the original byte for byte.

Neither half exists twice, so neither can drift. The kernel has exactly one home
and the blank configuration has exactly one home.

**A missing half is fatal, never silent.** If the blank Part B is absent, or the
marker has been renamed out of the root file, `init.sh` aborts naming what it
could not find. The alternative — falling back to copying the root file — would
ship vibe-template's own delivery contract, forge and repository URL included,
into a stranger's repository. A loud stop is much cheaper than that.

**The filled Part B records what is, not what should be.** `main` is unprotected
and no approval is required; B8 says so. A field claiming two approvals where
nothing enforces one teaches an agent to trust the document over the repository,
which is the failure this ADR exists to prevent, wearing different clothes.

### A defect found while writing the tests

The project name was substituted with
`sed -i "s|<PROJECT_NAME>|${PROJECT_NAME}|g"`. The name is user input; `|` was the
delimiter and `&` means "the whole match" in a sed replacement. A project named
`a&b|c` made sed fail outright, and — worse, because it is silent — a project
named `Foo & Bar` produced `Project name : Foo <PROJECT_NAME> Bar`, reinserting
the placeholder into the file meant to have none.

The substitution moved to `scripts/substitute.py`, a literal `str.replace`. The
alternative was to restrict project names to a safe character set, which would
have rejected names that work today — including non-ASCII ones — for the
convenience of the substitution. Fail-safe beat fail-fast here because the unsafe
input has a correct interpretation.

## Consequences

**Good**
- The template can read its own contract. `/ship`, `/build` and every agent get
  real values for the forge, the branch convention, the check names and the tags.
- A regression to placeholders fails `make check`: the root Part B is scanned for
  `<[A-Za-z][^>]*>` (a letter must follow `<`, so `->`, `<=` and `<!--` are not
  flagged) and the blank half is checked for the marker, B1–B8, `<PROJECT_NAME>`
  and the `### Code conventions` injection point.
- Project names are no longer a substitution hazard.

**Bad**
- One more file, and a bootstrap step that is a join rather than a copy. The
  join is asserted in both directions, which is the price of the split.
- Anyone renaming the marker breaks the bootstrap. That is deliberate: it stops,
  it does not ship half a file.

**Assertions that hold this together**
- `scripts/validate-template.sh` — marker exactly once; blank half well-formed;
  no placeholder left in the root Part B.
- `scripts/test-template.sh` — Part A reaches a generated project byte-identical;
  the seam occurs once; the project never receives vibe-template's own B8; a
  missing blank half aborts; `&`, `|` and non-ASCII names survive.

## Alternatives considered

**Keep copying and overwrite the tail in `init.sh`.** More moving parts for the
same result, and the failure mode when the tail is mis-cut is a silently
malformed file rather than a stop.

**Put the template's own configuration in `CLAUDE.md`.** It is the one file
opencode does not read. Forking the content across tools is the thing
`docs/DUAL-AGENT.md` exists to prevent.

**Leave it, and let each session look up the facts.** That is the status quo, and
it costs a lookup per session plus the occasional wrong guess — which is the
expensive kind, because a guess about a merge strategy is not obviously a guess.

## References

- ADR-002 — the test gate, which `.claude/test-policy.json` configures the same way
- `docs/DUAL-AGENT.md` — one source per concept, everything else generated
- AGENTS.md A11 — picking the right extension mechanism
