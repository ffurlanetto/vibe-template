# ADR-003: The agent ledger — a file protocol shared by both tools

**Date:** 2026-09-27
**Status:** Accepted
**Deciders:** vibe-template maintainers
**Component(s):** `.claude/hooks/`, `.opencode/plugins/`, `Makefile`

---

## Context

The template ships six subagents and will ship an orchestrator that runs several
of them at once (a cohort of implementers judged by reviewers, with bounded
improvement loops). None of that is observable today: a subagent starts, works in
its own context, and returns a summary. Between those two moments the caller
knows nothing — not that it started, not that it hit its turn budget, not how
long it took.

Two constraints shape the answer. First, an orchestrator cannot schedule what it
cannot see, so progress reporting has to exist before the orchestration does.
Second, this template serves Claude Code *and* opencode, and their mechanisms do
not match: Claude Code fires `SubagentStart` and `SubagentStop` hooks carrying
`agent_type`, `agent_id` and the subagent's last message; opencode has no
equivalent event, only plugin hooks around the `task` tool.

Relying on the model to report its own progress is not an option for the same
reason the test gate is a hook: an instruction to "report when you finish" is
followed most of the time, and most of the time is not a protocol.

## Decision

1. Progress is recorded in **`.claude/run/ledger.jsonl`** — append-only, one JSON
   object per line, each carrying `session_id`.
2. The event shape is fixed:
   `{"ts","event","session_id","agent_id","agent_type","summary"}` with `event`
   one of `agent.start` or `agent.stop`.
3. Claude Code appends through `SubagentStart` and `SubagentStop` hooks calling
   `.claude/hooks/ledger.sh`. opencode appends the same lines from its guardrail
   plugin, around the `task` tool.
4. `summary` is the subagent's final message, truncated to 240 characters and
   **passed through the secret masker** already used by the other hooks.
5. `make agents` renders the ledger as a table. The file is gitignored.
6. No rotation. `make agents` shows the last 50 events; truncation is manual and
   documented.

## Rationale

**Why a file rather than an API.** The file is the only thing both tools can
write. Making the *protocol* the contract — rather than Claude's hook payload —
keeps the dual-agent promise intact: a third tool joins by appending lines, and
nothing in the reader changes. It also means a human can `tail -f` it, which an
in-memory event bus would not offer.

**Why JSONL.** Concurrent subagents append simultaneously. Line-oriented append
is the one write pattern that survives that without locking, and a partially
written line is a parse error on one record rather than a corrupt document.

**Why one file rather than a directory per run.** Every event carries
`session_id`, so filtering is a `grep`. A directory tree would need cleanup logic
to solve a problem that does not exist yet.

**Why the summary is masked.** A subagent's final message is model output written
to disk. If it quotes a token it found while reading a config file, that token
would be persisted. The masker already exists in `lib.sh`; reusing it costs one
call and closes the hole.

**Why 240 characters.** Enough to tell an orchestrator what happened, short
enough that a ledger of a hundred events stays readable and cheap to load.

**Why no rotation.** Rotation is machinery in service of a problem nobody has
measured. The file is gitignored, never read whole by an agent, and one line is
roughly 300 bytes. This is revisited when the orchestrator makes it necessary.

## Consequences

### Positive
- An orchestrator can measure progress without asking the model
- The same mechanism gives a human `make agents` and a live `tail -f`
- Turn-budget truncation becomes visible instead of silent
- Adding a third agent runtime means writing lines, not changing the reader

### Negative / Trade-offs
- The ledger grows without bound (see rationale). Accepted and documented
- Two hook invocations per subagent. Measured in milliseconds: the scripts append
  and exit, with a 5 second timeout and no network call
- The opencode side approximates: its events fire around the `task` tool rather
  than the agent lifecycle, so timings are close but not identical

### Neutral
- `SubagentStart` and `SubagentStop` cannot block, which suits an observer

## Alternatives considered

### Have each agent report in its own final message
- Description: instruct every agent to end with a structured status block.
- Rejected because: it is an instruction, so it holds most of the time. It also
  cannot report an agent that was cut off by its turn budget — precisely the case
  an orchestrator most needs to see.

### A SQLite database
- Description: durable, queryable, transactional.
- Rejected because: concurrent writers need locking, the file stops being
  human-readable, and it adds a dependency for an append-only log.

### Rely on Claude Code's own agent view
- Description: use the built-in background-agent UI.
- Rejected because: it serves the human, not the orchestrator, and it does not
  exist in opencode.

## Implementation

- [x] `.claude/hooks/ledger.sh`, masking through `lib.sh`
- [x] `SubagentStart` and `SubagentStop` wired in `.claude/settings.json`
- [x] Equivalent emission in `.opencode/plugins/guardrails.js`
- [x] `scripts/show-ledger.sh` and the `make agents` target
- [x] `.claude/run/` gitignored in the template and in generated projects
- [x] Protocol documented in `docs/DUAL-AGENT.md`
- [x] Covered by `scripts/test-hooks.sh`, including the masking assertion

## References

- ADR-001 — agent-governed development workflow
- ADR-002 — the test gate
- AGENTS.md A8 (observability), A11 (context engineering, dual-agent rules)
