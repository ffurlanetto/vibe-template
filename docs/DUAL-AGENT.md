# Working with two agents

This project is configured for **Claude Code** and **opencode** at the same time.
The rule behind every choice below: *one source per concept, everything else generated.*

---

## Compatibility matrix

| Concept | Claude Code | opencode | How it is handled here |
|---|---|---|---|
| Instructions | `CLAUDE.md` | `AGENTS.md` — **wins** over `CLAUDE.md`, they never stack | `AGENTS.md` is the source; `CLAUDE.md` is one `@AGENTS.md` import plus Claude-only wiring |
| Skills | `.claude/skills/<n>/SKILL.md` | reads `.claude/skills/` natively | **one shared copy**, no duplication |
| Slash commands | the skills above | `.opencode/commands/*.md` | generated wrappers that include the shared skill |
| Subagents | `.claude/agents/*.md` | `.opencode/agents/*.md` | generated: frontmatter translated, prompt body copied |
| Guardrails | hooks in `.claude/settings.json` | plugin `.opencode/plugins/guardrails.js` | both call the same `.claude/hooks/*.sh` |
| Permissions | `.claude/settings.json` | `opencode.json` → `permission` | generated from the Claude rules |
| MCP servers | `.mcp.json` | `opencode.json` → `mcp` | mirrored by hand — declare the server in both |

---

## What you may edit

```
AGENTS.md              ← edit freely: the source of truth for both agents
CLAUDE.md              ← Claude-specific section only, below the import
.claude/skills/**      ← edit freely: shared, read by both
.claude/agents/**      ← edit freely: the source of the subagents
.claude/hooks/**       ← edit freely: shared guardrail implementation
.claude/settings.json  ← edit freely: the source of the permission rules

.opencode/agents/**    ← GENERATED — do not edit
.opencode/commands/**  ← GENERATED — do not edit
opencode.json          ← the "permission" block is GENERATED; the rest is yours
```

After touching anything under `.claude/`:

```bash
make sync         # regenerate
make check-sync   # what CI runs; fails if the two sides drifted
```

---

## Things that will bite you

**A `CLAUDE.local.md` silences `AGENTS.md` for Claude.** Claude Code reads
`AGENTS.md` only when no `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md`
exists above the working directory. Here a `CLAUDE.md` exists on purpose and
imports `AGENTS.md`, so the content always arrives — but do not delete that
import.

**opencode stops at the first instruction file it finds.** With both files
present it reads `AGENTS.md` and ignores `CLAUDE.md` entirely. Anything that
must reach both agents belongs in `AGENTS.md`.

**Skill names are stricter on the opencode side.** The `name` in the frontmatter
must equal the directory name, be 1–64 characters, lowercase alphanumeric with
single hyphens. `make validate` checks this.

**Claude model aliases are not opencode model ids.** The generator drops
`model:` when translating a subagent: an opencode subagent inherits the model of
the agent that invoked it. Set a provider-qualified model in
`.opencode/agents/` only if you really want to pin one, and expect `make sync`
to overwrite it — pin it in `opencode.json` instead.

**Both tools can disable the compatibility.** `OPENCODE_DISABLE_CLAUDE_CODE=1`
makes opencode ignore `.claude/` entirely, including the shared skills.

---

## Adding a third agent

Add a generator target to `scripts/sync-opencode.py` (or a sibling script) that
reads the same sources, and add its check to `make check-sync`. Do not fork
`AGENTS.md`.
