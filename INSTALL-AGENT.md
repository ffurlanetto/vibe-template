# Installing — for an agent

Instructions for an AI agent asked to install this template into a repository.
Deterministic, idempotent, no interactive prompt.

---

## Procedure

```bash
# 1. Bootstrap — never overwrites an existing file
<TEMPLATE_DIR>/init.sh <PROJECT_NAME> <STACK> <DESTINATION> --yes

# 2. Verify
cd <DESTINATION>
make test-hooks       # guardrails fire
make check-sync       # the two agents' configurations agree
```

`<STACK>` is one of: `java-spring` `java-spring-gradle` `java-quarkus`
`dotnet-aspnet` `python-fastapi` `go` `nestjs` `rust` `rails` `react-native`
`flutter` `monorepo` `frontend` `sre`.

Options worth knowing: `--scaffold none` (configuration only — use it on an
existing codebase), `--agent claude|opencode|both`, `--dry-run`.

Exit code 0 means success. A non-zero exit prints the reason on stderr; do not
retry with different arguments without reading it.

---

## What the command produces

```
AGENTS.md                  source of truth, Part A kernel + Part B to fill in
CLAUDE.md                  "@AGENTS.md" + Claude-specific wiring
opencode.json              opencode configuration; "permission" is generated
Makefile                   make install|test|lint|typecheck|build|dev|audit|check
.claude/skills/            12 skills — read by BOTH agents, never duplicate them
.claude/agents/            6 subagents (source)
.claude/hooks/             guardrail scripts, shared by both agents
.claude/settings.json      permissions + hook wiring (source)
.opencode/                 GENERATED from .claude/ — never edit by hand
scripts/                   sync-opencode.py, test-hooks.sh
docs/                      adr/ specs/ runbooks/ DUAL-AGENT.md
.github/workflows/         quality-gate.yml
```

---

## After installing

Complete Part B of `AGENTS.md` — replace every `<angle bracket>`. Derive the
values from the repository rather than inventing them:

| Section | Where to look |
|---------|---------------|
| B1 identity | the README, the package manifest |
| B2 stack | the manifest and lockfile, with exact versions |
| B4 commands | existing scripts; map them onto the `make` targets |
| B5 architecture | the real directory tree, not an idealised one |
| B7 integrations | HTTP clients, SDKs, connection strings in the config |
| B8 workflow | `.github/workflows/`, CODEOWNERS, branch names |

Leave a section as `<...>` rather than guessing, and say which ones you left.

---

## Rules

1. **Never overwrite** a file the repository already has. `init.sh` enforces
   this; do not work around it.
2. **Never edit `.opencode/agents/`, `.opencode/commands/`, or the `permission`
   block of `opencode.json`.** Edit the source under `.claude/`, then `make sync`.
3. **Never duplicate a skill** into `.opencode/`. opencode reads
   `.claude/skills/` directly.
4. **Never disable a hook** to get a commit through, and never use
   `git commit --no-verify`. A firing guardrail means fix the code or fix the
   pattern in `.claude/hooks/lib.sh`.
5. **Do not commit** unless the repository's own gate passes: `make check`.

---

## Verification checklist

```bash
test -f AGENTS.md && grep -q '^@AGENTS.md' CLAUDE.md   # instruction chain intact
ls .claude/skills | wc -l                              # 12
make test-hooks                                        # guardrails green
make check-sync                                        # no drift
make check                                             # project gate green
```

Report what you installed, which Part B sections remain unfilled, and any
toolchain that was missing when the scaffolder ran.
