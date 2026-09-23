# Installing — for developers

## Requirements

| Tool | Why |
|------|-----|
| `bash` 4+ | the scripts |
| `git` | repository initialisation |
| `make` | the command contract (on Windows: WSL, or `winget install GnuWin32.Make`) |
| `python3` | the opencode generator and the hooks' JSON fallback |
| `jq` *(optional)* | faster hook parsing; `python3` covers it otherwise |

Plus your stack's own toolchain: `uv`, `go`, `npm`, a JDK, `dotnet`, `cargo`…
If it is missing, `init.sh` skips the framework generator, says so, and still
produces the architecture, the `Makefile` and the agent configuration.

---

## Get the template

```bash
git clone <this-repository> ~/tools/vibe-template
cd ~/tools/vibe-template
make check          # optional: confirm the template is healthy
```

---

## Bootstrap a project

```bash
~/tools/vibe-template/init.sh payment-api python-fastapi
cd payment-api
make install && make check
```

`make check` should be green immediately — that is the point of the walking
skeleton. If it is not, the output tells you which toolchain step is missing.

### Options

```bash
--scaffold full        code + architecture + configuration (default)
--scaffold structure   architecture + configuration, no example slice
--scaffold none        agent configuration only — use this on an existing project
--agent both           Claude Code and opencode (default)
--agent claude         no opencode.json, no .opencode/
--agent opencode       no CLAUDE.md; AGENTS.md is read directly
--variant react|vue|angular    frontend stack only
--yes                  never prompt
--dry-run              list the actions, write nothing
```

### On an existing project

```bash
cd ~/work/existing-project
~/tools/vibe-template/init.sh existing-project go . --scaffold none --yes
```

Nothing is overwritten. Your `README`, your `Makefile`, your sources stay as they
are; you receive only what is missing.

---

## Verify the installation

```bash
make test-hooks     # the security guardrails actually fire
make check-sync     # the two agents' configurations agree
ls .claude/skills   # 12 skills
```

Then open a session:

- **Claude Code** — `claude`, then `/prime`. `/context` lists the memory files;
  `CLAUDE.md` and the imported `AGENTS.md` must both appear.
- **opencode** — `opencode`, then `/prime`. Tab switches agents, `@architect`
  calls a subagent.

---

## Troubleshooting

**A skill does not show up.** The `name` in its frontmatter must equal its
directory name, lowercase with single hyphens. Run `make validate`.

**The commit hook does not fire.** It is wired to `PreToolUse` on `Bash`,
narrowed with `if: "Bash(git commit*)"`. Check `.claude/hooks/*.sh` is
executable, then run `make test-hooks`.

**opencode ignores my `CLAUDE.md`.** By design: when both files exist, opencode
reads `AGENTS.md` only. Put shared content there.

**`make: command not found` on Windows.** Use WSL, or install GNU Make. The
target names are what the agents and the pipeline rely on.

**The generator was skipped.** Its toolchain was not on `PATH`, or its service
was unreachable. Install it and re-run `init.sh` — existing files are kept.
