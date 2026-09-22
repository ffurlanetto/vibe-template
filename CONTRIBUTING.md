# Contributing

## Before you push

```bash
make check
```

That runs, in order: structural validation, shellcheck, Python byte-compile, the
hook test suite, the `init.sh` test suite, and the generated-artifact drift check.
CI runs the same target plus a bootstrap of all fourteen stacks.

## The one rule that causes every mistake

**`.opencode/agents/`, `.opencode/commands/` and the `permission` block of
`opencode.json` are generated.** Edit the source, then run `make sync`:

| To change | Edit | Then |
|---|---|---|
| a subagent | `.claude/agents/<name>.md` | `make sync` |
| a skill | `.claude/skills/<name>/SKILL.md` | nothing — both agents read it |
| a permission | `.claude/settings.json` | `make sync` |
| a guardrail | `.claude/hooks/*.sh` | `make test-hooks` |
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
