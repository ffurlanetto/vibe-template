# Claude Code Template

A production-ready project template for AI-assisted development with Claude Code. Enforces structured workflows, security guardrails, and engineering standards across any tech stack — from day one.

---

## What this is

A drop-in `.claude/` configuration that turns Claude Code into a disciplined engineering partner:

- **Plan-first workflow** — Claude generates a structured plan and waits for your approval before writing a single line of code
- **Built-in security hooks** — hardcoded secret detection on every file write and before every commit
- **Stack-specific presets** — opinionated conventions for 12 tech stacks, ready to paste
- **Slash commands** — `/plan`, `/review`, `/security-audit`, `/debug`, `/adr` wired up and ready
- **ADR + spec templates** — architectural decisions and functional specs as first-class artifacts

---

## Quick start

```bash
# Bootstrap a new project in ~2 minutes
./init.sh <project-name> <stack>

# Examples
./init.sh payment-api python-fastapi
./init.sh mobile-app flutter ~/projects/mobile-app
./init.sh platform monorepo
```

Then complete sections B1–B8 in `CLAUDE.md` and open a Claude session:

```bash
cd <project-name>
claude
# → /plan Create a GET /health endpoint
```

---

## Supported stacks

| Stack | Technology |
|-------|-----------|
| `java-spring` | Java 21 / Spring Boot 3 |
| `java-quarkus` | Java 21 / Quarkus 3 / Gradle |
| `dotnet-aspnet` | .NET 8 / ASP.NET Core |
| `python-fastapi` | Python 3.12 / FastAPI |
| `go` | Go 1.23 / chi |
| `nestjs` | Node.js 22 / NestJS |
| `rust` | Rust / axum |
| `rails` | Ruby 3.3 / Rails 7 |
| `react-native` | React Native (Expo or CLI) |
| `flutter` | Flutter / Dart |
| `monorepo` | Nx or Turborepo |
| `frontend` | Vue 3 / Angular 17+ / React 18+ |

---

## How it works

```
CLAUDE.md
├── Part A — Common kernel (DO NOT MODIFY)
│   ├── A1  Plan-first rule
│   ├── A2  Implementation plan format
│   ├── A3  Universal development standards
│   ├── A4  Testing rules
│   ├── A5  Security checklist
│   ├── A6  Documentation standards
│   ├── A7  Available slash commands
│   ├── A8  Observability
│   ├── A9  AI-assisted development best practices
│   └── A10 Performance
└── Part B — Project configuration (FILL IN PER PROJECT)
    ├── B1  Project identity
    ├── B2  Tech stack
    ├── B3  Language/framework standards (paste preset here)
    ├── B4  Development commands
    ├── B5  Project architecture
    ├── B6  Project-specific constraints
    ├── B7  External integrations
    └── B8  Team context & workflow
```

Part A is the shared kernel — never modified per project. Part B is filled in once per project and kept up to date as the source of truth for every Claude session.

---

## What's included

```
template/
├── README.md                          ← you are here
├── CLAUDE.md                          # Main configuration
├── SETUP.md                           # Detailed usage guide
├── INSTALL-DEV.md                     # Installation guide for developers
├── INSTALL-AGENT.md                   # Installation guide for LLM agents
├── init.sh                            # Automated bootstrap script
├── VERSION                            # Template version
├── .claude/
│   ├── settings.json                  # Permissions + security hooks
│   ├── commands/                      # Slash commands
│   │   ├── plan.md                    # /plan
│   │   ├── adr.md                     # /adr
│   │   ├── review.md                  # /review
│   │   ├── security-audit.md          # /security-audit
│   │   └── debug.md                   # /debug
│   └── presets/                       # Stack-specific conventions
│       └── [11 preset files]
├── .github/
│   └── workflows/
│       └── quality-gate.yml           # CI pipeline template
└── docs/
    ├── adr/
    │   └── README.md                  # ADR index
    └── specs/
        └── SPEC-TEMPLATE.md           # Functional specification template
```

---

## Daily workflow

```
Write a request
      ↓
/plan → plan submitted for approval
      ↓
Reply "ok" / "proceed"
      ↓
Step-by-step implementation
      ↓
/review → 🟢 PASS / 🟡 ATTENTION / 🔴 BLOCKING
      ↓
Commit only if PASS
```

---

## Security hooks (active by default)

| Hook | Trigger | Action |
|------|---------|--------|
| PostToolUse | After any file write | Scans for hardcoded secrets — warning |
| PreToolUse | Before `git commit` | Scans staged files — **blocks commit** if secret found |

Requires Python 3 (available on any modern development environment).

---

## Installation

- **Developers** → see [`INSTALL-DEV.md`](INSTALL-DEV.md)
- **LLM agents / automation** → see [`INSTALL-AGENT.md`](INSTALL-AGENT.md)
- **Detailed usage** → see [`SETUP.md`](SETUP.md)

---

## Template version

Current version: `2.0.0`

Each bootstrapped project stores its template version in `.claude/.template-version` for traceability.
