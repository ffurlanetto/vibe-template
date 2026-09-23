# ADR-001: Agent-governed development workflow

**Date:** @@DATE@@
**Status:** Accepted
**Deciders:** @@PROJECT@@ team
**Component(s):** whole repository

---

## Context

This project is developed with AI coding agents (Claude Code and opencode) as a
routine part of the workflow. Agents are fast at producing code and poor at
knowing when to stop, which makes the failure mode of the project not "too
little code" but "code nobody decided on".

Two agents are in use, so any convention that lives in a tool-specific file has
to exist twice and will drift.

## Decision

1. `AGENTS.md` is the single source of instructions. `CLAUDE.md` imports it with
   `@AGENTS.md` and only adds Claude-specific wiring.
2. No implementation starts before an approved plan (rule A1).
3. Repeatable procedures live in `.claude/skills/`, read natively by both tools.
4. Anything that must hold regardless of the model's judgement is enforced by a
   hook, not by an instruction.
5. Every agent-facing artifact that cannot be shared is **generated** from the
   shared source, never maintained twice.

## Rationale

Instructions are context, not control. An instruction tells the model what is
expected; a hook decides what is possible. Splitting the two means a prompt
regression cannot leak a secret into a commit.

Generating the divergent artifacts keeps a single edit point, and CI fails on
drift, so the two tools cannot quietly disagree.

## Consequences

### Positive
- One place to change a rule; both agents pick it up
- Security guarantees survive a bad model day
- Onboarding a third agent means adding one generator target

### Negative / Trade-offs
- `make sync` must be run after touching `.claude/` — CI enforces it
- The plan-first rule costs a round trip on trivial changes

### Neutral
- Generated files are committed, so a checkout works without running the generator

## Alternatives considered

### Duplicate the instructions per tool
- Description: keep a `CLAUDE.md` and an `AGENTS.md`, each complete.
- Rejected because: they drift within weeks, and the drift is invisible.

### Instructions only, no hooks
- Description: rely on the rules in `AGENTS.md` for security.
- Rejected because: an instruction is a suggestion to a probabilistic system.

## Implementation

- [x] `AGENTS.md` written, `CLAUDE.md` imports it
- [x] Skills, subagents and hooks installed under `.claude/`
- [x] `make sync` / `make check-sync` wired into CI
- [ ] Part B of `AGENTS.md` completed for this project

## References

- Related ADRs: none
