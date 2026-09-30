@AGENTS.md

---

# Claude Code specifics

Everything above is shared with every agent working on this project.
This section applies to **Claude Code only** — opencode has the equivalent in
`opencode.json` and `.opencode/`.

## What is wired up

| Mechanism | Location | Notes |
|-----------|----------|-------|
| Skills | `.claude/skills/<name>/SKILL.md` | **shared** — opencode reads the same files |
| Subagents | `.claude/agents/*.md` | source; `.opencode/agents/` is generated from these |
| Hooks | `.claude/settings.json` → `.claude/hooks/*.sh` | the scripts are shared with the opencode plugin |
| Permissions | `.claude/settings.json` | source; the `permission` block of `opencode.json` is generated from it |
| MCP servers | `.mcp.json` (copy `.mcp.json.example`) | mirrored into `opencode.json` → `mcp` |

## Guarantees enforced outside the model

Three hooks run regardless of what the model decides:

- **PostToolUse** on `Edit|Write` → `.claude/hooks/scan-secrets.sh` warns on a likely
  hardcoded secret in the file just written.
- **PreToolUse** on `Bash` matching `git commit*` → `.claude/hooks/block-commit-secrets.sh`
  inspects the staged diff and **denies** the commit if it finds a secret.
- **PreToolUse** on `Bash` matching `git commit*` → `.claude/hooks/require-tests.sh`
  **denies** a commit that changes source without changing a test, unless it carries
  a `Test-Exempt:` trailer with a reason (ADR-002).

They read their JSON payload on **stdin** and are the same scripts the opencode
plugin calls. Test them with `make test-hooks`.

A fourth hook observes rather than guards: `SubagentStart` and `SubagentStop`
append to `.claude/run/ledger.jsonl`, which `make agents` renders.

## Subagents

Delegate to keep the main context clean — `architect`, `test-architect`,
`code-reviewer`, `security-auditor`, `test-engineer`, `debugger`, `docs-writer`.
The auditing agents are read-only by construction (no `Write`/`Edit` tool), and
so is `test-architect`: it designs scenarios *before* the code, and having no way
to write one is what keeps it from drifting into implementation.

Each agent declares a `maxTurns` budget. Reaching it returns partial output
rather than failing, and the ledger shows that it happened. The generator maps it
to opencode's `steps`; `effort` and `memory` have no equivalent there and are
dropped.

## After changing anything under `.claude/`

Run `make sync` to regenerate the opencode artifacts, then commit both sides.
CI fails if they drift (`make check-sync`).
