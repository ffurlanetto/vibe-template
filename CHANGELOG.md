# Changelog

All notable changes to this template are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] — 2026-09-30

Testing becomes a constraint, the plan becomes executable, agents become
measurable, and delivery becomes a flow rather than a push.

### Added

- **The test gate** (ADR-002). A hook refuses a commit that changes source
  without changing a test. The boundary is declared per project in
  `.claude/test-policy.json`, written from the stack module; tests living inside
  a source file (Rust's `#[cfg(test)]`, a nested JUnit class) are recognised. The
  way out is a `Test-Exempt:` trailer with a reason, which stays in the history
- **Test scenarios in the analysis phase.** `/spec` carries a numbered matrix
  (`SC-n`) tied to the requirements, `/plan` repeats it, `/tdd` names the scenario
  each red test covers, `/review` treats an uncovered scenario as blocking. The
  new `test-architect` agent produces it and has no `Write` tool
- **A plan that decides everything** — decisions taken, open questions that must
  be empty, per-file signatures and error contracts, and certification by the
  `architect` agent before approval
- **The agent ledger** (ADR-003). Every subagent start and stop lands in
  `.claude/run/ledger.jsonl`, fed by Claude Code hooks and by the opencode
  plugin. `make agents` renders it; summaries are secret-masked
- **Turn budgets** on all agents: `maxTurns`, `effort`, `memory`, mapped to
  opencode's `steps`
- **The delivery flow** (ADR-004). A14: a branch before the first edit, a push
  opens a **draft** PR, ready is earned, and the agent **waits for the build**.
  B8 becomes the contract it reads — forge, git model, branch and tag conventions,
  required check names, merge strategy, wait budget. `/ship` runs it end to end
- **`/build`** (ADR-005): triage, certified plan, cohort of `implementer` agents
  in isolated worktrees, objective gate before any opinion, a jury of three
  specialists with scores, quorum (2 of 3, no FAIL on correctness or security,
  ≥ 21/30), constrained consolidation, and a loop bounded by a ceiling, a ratchet
  and a diminishing-returns stop
- ADR-002 to ADR-005; the template now keeps its own ADR index, and the
  placeholder one ships to generated projects

### Fixed

- The ADR index template was shipped to neither the template nor generated
  projects. It now lives in `templates/common/docs/adr/` beside the seed ADR-001

### Changed

- `make agents` joins the command contract
- `AGENTS.md` A1 gains the certification step; A4 gains the gate; A8 gains agent
  telemetry; A11 gains the cohort rules; A14 is new; B8 is rewritten

### Notes

A commit that changes source without a test is now **refused**. If that fires on
a legitimate change, add the trailer — and if it fires often, fix the globs in
`.claude/test-policy.json` rather than the rule.

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
