# Vibe Template

A project template for teams who develop with AI coding agents — and want the
result to look like engineering rather than autocomplete.

Bootstrap a project in two minutes and get, from the first commit: a plan-first
workflow both **Claude Code** and **opencode** obey, security guardrails enforced
outside the model, and a skeleton that already runs, already tests itself, and
whose quality gate is already green.

---

## Quick start

```bash
./init.sh payment-api python-fastapi
cd payment-api
make install && make check     # green, on a project nobody has written yet
```

Then complete sections B1–B8 of `AGENTS.md`, open an agent session, and type
`/prime`.

```bash
./init.sh <name> <stack> [destination] [options]

  --scaffold full|structure|none   how much code to generate (default: full)
  --agent both|claude|opencode     which agents to configure (default: both)
  --variant react|vue|angular      frontend stack only (default: react)
  --yes                            never prompt
  --dry-run                        list the actions, write nothing
```

Nothing existing is ever overwritten, so running `init.sh` on a live project
only adds what is missing.

---

## What you get

**A plan-first workflow.** No implementation before an approved plan, and the
plan is a contract: any deviation is flagged and re-approved.

**Twelve skills**, invoked with `/name` and read by *both* agents:

| | | |
|---|---|---|
| `/plan` | `/spec` | `/adr` |
| `/tdd` | `/debug` | `/review` |
| `/security-audit` | `/deps-audit` | `/perf-audit` |
| `/commit` | `/pr` | `/prime` |

**Six subagents** with isolated context — `architect`, `code-reviewer`,
`security-auditor`, `test-engineer`, `debugger`, `docs-writer`. The auditors are
read-only by construction: they have no `Write` tool at all.

**Guardrails the model cannot talk its way past.** A hook scans every file
written for hardcoded secrets, and a second one **blocks** a commit whose staged
diff contains one. Both run outside the model, back both agents, and are covered
by their own test suite (`make test-hooks`).

**A walking skeleton.** `/health/live` and `/health/ready` per a seed spec, one
vertical slice (route → service → repository behind an interface), structured
JSON logging, configuration read from the environment, and the unit and
integration tests for all of it.

**One command contract.** `make install test lint typecheck build dev audit check`
— identical across all fourteen stacks, which is why the CI pipeline never needs
to know your language.

---

## Supported stacks

★ ships a walking skeleton that runs and is tested; the rest ship the official
generator's output plus the imposed architecture, the wired `Makefile` and a
green pipeline.

| Stack | Technology | |
|-------|-----------|---|
| `python-fastapi` | Python 3.12 / FastAPI | ★ |
| `go` | Go 1.23 | ★ |
| `nestjs` | Node.js 22 / NestJS | ★ |
| `frontend` | React 18 + Vite + TS (Vue, Angular via `--variant`) | ★ |
| `java-spring` | Java 21 / Spring Boot 3 / Maven | ★ |
| `java-spring-gradle` | Java 21 / Spring Boot 3 / Gradle | ★ |
| `java-quarkus` | Java 21 / Quarkus 3 / Gradle | ★ |
| `dotnet-aspnet` | .NET 8 / ASP.NET Core | |
| `rust` | Rust / axum | |
| `rails` | Ruby 3.3 / Rails 7 | |
| `react-native` | React Native / Expo | |
| `flutter` | Flutter / Dart | |
| `monorepo` | Nx or Turborepo | |
| `sre` | Terraform + Kubernetes | |

Promoting a stack to ★ is documented in [`docs/SCAFFOLD.md`](docs/SCAFFOLD.md).

---

## Two agents, one source of truth

Claude Code and opencode disagree about where configuration lives. The template
resolves that with one rule: **one source per concept, everything else generated.**

| Concept | Source | Generated |
|---|---|---|
| Instructions | `AGENTS.md` | `CLAUDE.md` imports it with `@AGENTS.md` |
| Skills | `.claude/skills/` | — *(opencode reads them natively)* |
| Subagents | `.claude/agents/` | `.opencode/agents/` |
| Commands | the skills | `.opencode/commands/` |
| Permissions | `.claude/settings.json` | `opencode.json` → `permission` |
| Guardrails | `.claude/hooks/*.sh` | called by `.opencode/plugins/guardrails.js` |

`make sync` regenerates; `make check-sync` fails the build if the two sides
drifted. Details and the traps to avoid: [`docs/DUAL-AGENT.md`](docs/DUAL-AGENT.md).

---

## How the configuration is organised

```
AGENTS.md
├── Part A — Common kernel (do not modify per project)
│   ├── A1  Plan first          A7  Available skills
│   ├── A2  Plan format         A8  Observability
│   ├── A3  Development standards  A9  AI-assisted development
│   ├── A4  Testing rules       A10 Performance
│   ├── A5  Security checklist  A11 Context engineering & agentic workflows
│   ├── A6  Documentation       A12 LLM features in the product
│   │                           A13 Supply chain
└── Part B — Project configuration (fill in once, keep current)
    B1 identity · B2 stack · B3 conventions · B4 commands
    B5 architecture · B6 constraints · B7 integrations · B8 workflow
```

---

## What's in the box

```
AGENTS.md · CLAUDE.md · opencode.json · Makefile · init.sh
.claude/
  skills/      12 skills, shared by both agents
  agents/      6 subagents
  hooks/       guardrail scripts (stdin JSON or argv)
  presets/     14 stack conventions for section B3
  settings.json
.opencode/     generated — agents, commands, guardrail plugin
scripts/       scaffolder, generator, three test suites
templates/     common overlay + 7 walking skeletons
docs/          adr/ · specs/ · runbooks/ · DUAL-AGENT.md · SCAFFOLD.md
.github/       quality-gate.yml · template-ci.yml · PR template
```

---

## Daily workflow

```
request → /plan → "ok" → implementation → /review → /commit → /pr
                                  ↑
                     hooks refuse the commit if a secret slipped in
```

---

## Installing

- Developers → [`INSTALL-DEV.md`](INSTALL-DEV.md)
- Agents and automation → [`INSTALL-AGENT.md`](INSTALL-AGENT.md)
- Day-to-day usage → [`SETUP.md`](SETUP.md)
- Upgrading from v2 → [`CHANGELOG.md`](CHANGELOG.md)

Requires `bash`, `git`, `make` and `python3`. Everything else depends on your stack.

---

## Contributing to the template

```bash
make check     # validate + lint + typecheck + hook tests + init.sh tests + sync check
make demo STACK=go
```

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Current version: **3.0.0**.
