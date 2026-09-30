# PART B — PROJECT CONFIGURATION
---

## B1 · PROJECT IDENTITY

```
Project name  : <PROJECT_NAME>
Description   : <One sentence describing what this project does>
Type          : <web app | API | CLI | library | service | monorepo>
Team / Owner  : <team name or responsible person>
Ticket prefix : <PROJ>
```

---

## B2 · TECH STACK

```
Backend   : <framework + version>
Frontend  : <framework + version | N/A>
Mobile    : <framework | N/A>
Database  : <engine + version>
Cache     : <engine | N/A>
Messaging : <broker | N/A>
Infra     : <Docker + Kubernetes | cloud provider | on-prem>
CI/CD     : <GitHub Actions | GitLab CI | ...>
```

---

## B3 · LANGUAGE / FRAMEWORK-SPECIFIC STANDARDS

> Paste the matching preset from `.claude/presets/<stack>.md`. `init.sh` does this automatically.

### Code conventions

### Naming and structure

```
<
- File naming: kebab-case | PascalCase | snake_case
- Class / interface / type naming convention
- Directory structure: feature-based | layer-based
>
```

---

## B4 · DEVELOPMENT COMMANDS

Every project exposes the **same command contract** through its `Makefile`,
whatever the stack. Agents call these — never the raw stack commands.

```bash
make install      # install dependencies
make test         # run tests — required before every commit
make lint         # lint / style check — zero warnings
make typecheck    # type check (no-op if not applicable)
make build        # full build
make dev          # run locally
make audit        # dependency / CVE audit
make check        # test + lint + typecheck + build — the quality gate
make sync         # regenerate the .opencode/ artifacts
make agents       # what the subagents have been doing (A8)
```

The stack-specific implementation lives in the generated `Makefile`.

---

## B5 · PROJECT ARCHITECTURE

```
<project-name>/
├── AGENTS.md       # ← this file (source of truth)
├── CLAUDE.md       # imports AGENTS.md + Claude Code specifics
├── opencode.json   # opencode configuration
├── Makefile        # B4 command contract
├── docs/
│   ├── adr/        # Architecture Decision Records
│   ├── specs/      # Functional specifications
│   └── runbooks/
├── .claude/        # skills (shared), agents, hooks, settings
├── .opencode/      # GENERATED — do not edit
├── <src>/          # Detail per module
└── <tests>/
```

| Component | Responsibility |
|-----------|---------------|
| `<module-1>` | <description> |

---

## B6 · PROJECT-SPECIFIC CONSTRAINTS

```
<
- GDPR / compliance rules
- SLA targets (P99, P50, error budget)
- Data sovereignty / retention requirements
- Multi-tenancy isolation rules
- Performance budgets (override A10 defaults here)
- LLM budgets if applicable (A12): max tokens/call, P99 latency, allowed model ids
>
```

---

## B7 · EXTERNAL INTEGRATIONS

| System | Role | Protocol | Notes |
|--------|------|----------|-------|
| `<system>` | `<role>` | `<REST / gRPC / event>` | `<notes>` |

---

## B8 · TEAM CONTEXT & DELIVERY

> Agents read this section instead of guessing. An empty field is a question an
> agent will have to ask, or worse, answer on its own.

### Forge and git model

```
Forge            : <github | gitlab | bitbucket>
Repository URL   : <https://...>
Git model        : <trunk-based | github-flow | gitflow>
Integration branch : <main | master | develop>
Release branches : <none | release/x.y>
Protected branches : <which, and what protection>
```

### Branch naming

```
Convention       : <feat/PROJ-123-short-slug | feature/... | user/topic>
Types allowed    : <feat | fix | chore | docs | refactor | perf | security>
Lifetime         : <deleted on merge | kept>
```

### Commits, tags and versions

```
Commit convention : Conventional Commits (A3)
Versioning        : <SemVer 2.0.0>
Tag format        : <vX.Y.Z>  — e.g. v3.1.0
Pre-release       : <vX.Y.Z-rc.N | none>
Who tags          : <maintainer | release pipeline>
Changelog source  : <CHANGELOG.md, Keep a Changelog | generated from commits>
```

### Pull requests

```
Opened as         : draft (A14)
Ready criteria    : CI green on head · make check green · threads resolved ·
                    no conflict · template followed
Required approvals: <n>  — <who, or CODEOWNERS>
Merge strategy    : <squash | merge commit | rebase>
Branch on merge   : <delete | keep>
Description       : .github/pull_request_template.md
```

### CI

```
Provider          : <GitHub Actions | GitLab CI | Bitbucket Pipelines | ...>
Required checks   : <exact check names that must pass>
Typical duration  : <n minutes>
Agent wait budget : <20 minutes>  — after this, hand back the status as it stands
Watch command     : <gh pr checks --watch | glab ci status --live | ...>
```

### Environments and ownership

```
Environments     : <dev | staging | prod>
Deploy gate      : <who can deploy to prod, and how>
Code owners      : <.github/CODEOWNERS, or who reviews what>
On-call / runbooks : <docs/runbooks/>
```
