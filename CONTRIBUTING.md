# Contributing

## Before you push

```bash
make check
```

That runs, in order: structural validation (83 assertions), shellcheck, Python
byte-compile, the hook test suite (52), the cohort arithmetic (64), the `init.sh`
test suite (56), and the generated-artifact drift check. CI runs the same target
plus a bootstrap of all fourteen stacks.

## The one rule that causes every mistake

**`.opencode/agents/`, `.opencode/commands/` and the `permission` block of
`opencode.json` are generated.** Edit the source, then run `make sync`:

| To change | Edit | Then |
|---|---|---|
| a subagent | `.claude/agents/<name>.md` | `make sync` |
| a skill | `.claude/skills/<name>/SKILL.md` | nothing — both agents read it |
| a permission | `.claude/settings.json` | `make sync` |
| a guardrail | `.claude/hooks/*.sh` | `make test-hooks` |
| the cohort's arithmetic | `scripts/quorum.py` | `make test-quorum` |
| the kernel | `AGENTS.md` | nothing — `CLAUDE.md` imports it |

`make check-sync` fails the build if you forget.

## Adding a skill

Create `.claude/skills/<name>/SKILL.md` with frontmatter:

```yaml
---
name: <name>            # must equal the directory name (opencode requires it)
description: <when Claude or opencode should use this skill>
allowed-tools: Read, Grep, Bash(make test*)   # Claude only; opencode ignores it
---
```

Keep the body under ~200 lines and write it as a procedure, not an essay.
Then `make sync && make validate`.

## Adding a subagent

Create `.claude/agents/<name>.md` with `name`, `description`, `tools` and
`model`. The `tools` list is an allowlist: the generator turns it into an
opencode permission block, so an agent without `Write` is read-only in both
tools. Then `make sync`.

## Adding a stack

See [`docs/SCAFFOLD.md`](docs/SCAFFOLD.md). In short: one module in
`scripts/scaffold/<stack>.sh`, one preset in `.claude/presets/<stack>.md`, the
stack added to `STACKS` in `init.sh` and to the CI matrix. Add
`templates/skeleton/<stack>/` to make it tier A.

## Commits

Conventional Commits — `type(scope): imperative description`. Scope is the
component: `core`, `skills`, `agents`, `hooks`, `opencode`, `scaffold`, `docs`, `ci`.

No commit with failing tests. No commit with a secret — the hook will stop you,
and `--no-verify` is not an answer.

A commit that changes source without changing a test is refused (ADR-002). If the
change genuinely carries no behaviour, say why in a trailer:

```
refactor(hooks): rename Handler to Controller

Test-Exempt: pure rename, behaviour unchanged, existing suite still covers it
```

The reason stays in `git log` where a reviewer sees it — which is the whole
difference from `--no-verify`. Add it only when the gate asks for it: a trailer on
a commit that would have passed anyway now gets a notice saying so, because a
waiver used out of habit stops meaning anything the day it is needed.

## Delivery

The full contract — forge, branch convention, tag format, required checks, merge
strategy — is section **B8 of `AGENTS.md`**, filled in for this repository. Read it
there rather than here; this is the short version.

**A branch before the first edit, never after the work.** One change, one branch,
cut from `main`. Branches are deleted on merge.

```bash
git fetch origin main
git checkout -b feat/short-slug origin/main
```

**Every push opens a draft pull request**, including one you consider finished. The
draft is where CI runs and where a reviewer can look early.

**Ready is earned.** A pull request leaves draft only when CI is green *on the head
commit*, `make check` passes locally, every thread is resolved, there is no
conflict, and the description follows the template. After pushing, wait for the
build — do not report "pushed, should be fine". Red means read the failure and fix
it; never disable a test to get green.

**Tags are the maintainer's.** `vX.Y.Z`, SemVer, pushed by hand after the release
commit is merged. `VERSION` and `CHANGELOG.md` move in that commit.

`/ship` runs this flow end to end.
