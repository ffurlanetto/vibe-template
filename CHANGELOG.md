# Changelog

All notable changes to this template are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] — 2026-09-22

Dual-agent support, Agent Skills, working security hooks, and a scaffolder that
produces code rather than only configuration.

### Added

- **`AGENTS.md`** as the single instruction source, read by opencode natively and
  by Claude Code through the `@AGENTS.md` import in `CLAUDE.md`
- **opencode compatibility**: `opencode.json`, generated `.opencode/agents/` and
  `.opencode/commands/`, and a guardrail plugin that calls the same hook scripts
- **12 skills** in `.claude/skills/`, read by both agents: the five former slash
  commands plus `spec`, `tdd`, `commit`, `pr`, `prime`, `deps-audit`, `perf-audit`
- **6 subagents** in `.claude/agents/`; the auditing ones are read-only by construction
- **Kernel sections** A11 (context engineering, dual-agent rules), A12 (LLM
  features: prompt injection, evals, model pinning, token budgets) and A13 (supply chain)
- **Scaffolding**: `init.sh` now generates a walking skeleton — health endpoints,
  a vertical slice, structured logging, env-based configuration and their tests —
  for `python-fastapi`, `go`, `nestjs`, `frontend`, `java-spring`,
  `java-spring-gradle` and `java-quarkus`; the other seven stacks get the
  official generator's output plus the imposed architecture
- **`Makefile` command contract**: `install test lint typecheck build dev audit check`,
  identical across every stack, generated from the preset's command block
- **Three test suites**: `make test-hooks`, `make test`, `make validate`
- **CI**: `template-ci.yml` (bootstraps all 14 stacks and runs the generated
  project's own gate), plus a rewritten `quality-gate.yml` with gitleaks,
  dependency review, timeouts and concurrency
- `docs/DUAL-AGENT.md`, `docs/SCAFFOLD.md`, `CONTRIBUTING.md`, a PR template,
  `.mcp.json.example`, a seed ADR, a seed spec and a runbook template
- `init.sh` options: `--scaffold`, `--agent`, `--variant`, `--yes`, `--dry-run`

### Fixed

- **The two security hooks never fired.** `PostToolUse` read `$CLAUDE_TOOL_INPUT`,
  but Claude Code sends the hook payload on **stdin**; `PreToolUse` used
  `"Bash(git commit*)"` as a matcher, but matchers filter on the tool *name*, so
  it is now `"Bash"` narrowed with `if`. Blocking also required exit code 2, not 1.
- **`init.sh` copied the template's own `.git/`** into every bootstrapped project,
  which inherited the template's history.
- **Permission arrays contained ~60 pseudo-comment entries** (`"// Bash(mvn test*)"`)
  that parsed as invalid permission rules.
- `includeCoAuthoredBy` replaced by the current attribution settings.
- Committed `.DS_Store` files removed; the template now has a `.gitignore`.
- The CI template mixed English and French, and its steps were placeholders.
- The README claimed 13 presets; there were 14.

### Changed

- **Breaking — `.claude/commands/` is gone.** The five slash commands are now
  skills. They are invoked the same way (`/plan`, `/review`, …) and work in both
  agents.
- **Breaking — B4 is now a `make` contract.** Agents call `make test`, never the
  raw stack command. Stack specifics live in the generated `Makefile`.
- `settings.json` no longer carries commented-out permission blocks per stack:
  one `Bash(make *)` family replaces them.

### Migrating from 2.x

Your existing `CLAUDE.md` keeps working — nothing forces the move. To adopt v3
in a project bootstrapped from v2:

```bash
# 1. Make AGENTS.md the source, and CLAUDE.md the import wrapper
git mv CLAUDE.md AGENTS.md
printf '@AGENTS.md\n' > CLAUDE.md

# 2. Take the new configuration (nothing existing is overwritten)
/path/to/template/init.sh <project-name> <stack> . --scaffold none --yes

# 3. Remove the superseded commands, wire the command contract
git rm -r .claude/commands
$EDITOR Makefile        # fill in the B4 commands for your project

# 4. Verify
make test-hooks && make check-sync
```

## [2.0.0]

- Part A / Part B kernel split, 14 stack presets, 5 slash commands, ADR and spec
  templates, secret-scanning hooks, `init.sh` bootstrap.
