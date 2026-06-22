# CLAUDE.md
<!-- Part A: common kernel — do not modify | Part B: fill in per project — replace all <angle brackets> -->

---

# PART A — COMMON KERNEL

---

## A1 · CORE RULE: PLAN FIRST

**For every request, without exception:**

1. **ANALYZE** the request — impacts, dependencies, regression risks
2. **WRITE** a structured plan (format: `/plan` command)
3. **WAIT** for explicit approval — accepted: `ok` · `proceed` · `go` · `approved` · `✓`
4. **IMPLEMENT** following the approved plan, step by step
5. **VERIFY**: tests green · lint clean · build OK · zero regressions

> ⛔ No code before the plan is approved.
> ⛔ Any deviation from the approved plan must be flagged and re-approved.

### Context window management

- Run `/compact` after plan approval and before starting implementation
- Run `/compact` when the session exceeds 15 exchanges
- After `/clear`: open the next session with — "Working on `<feature>`, plan approved, current state: `<X>`"

---

## A2 · IMPLEMENTATION PLAN FORMAT

See `.claude/commands/plan.md` — invoked via `/plan`.

---

## A3 · UNIVERSAL DEVELOPMENT STANDARDS

### Non-negotiable principles

- **Separation of concerns**: business logic isolated from handlers / controllers / routes
- **Explicit interfaces / contracts** between components
- **Fail fast**: validate inputs at the boundary, never propagate invalid state
- **Immutability**: prefer immutable structures, avoid hidden side effects
- **Least surprise**: name things by what they actually do, not by intent

### Error handling

- Errors always wrapped with context (`cause: original error`)
- Never silently swallow an error (`catch (e) {}` is forbidden)
- API error messages are generic; detail goes in structured logs
- Distinguish: expected error (business) vs unexpected error (system)

### Logging

- Structured JSON logging — never `print` / `console.log` in production
- Levels: `DEBUG` (dev) · `INFO` (nominal) · `WARN` (degraded) · `ERROR` (action required)
- Never log sensitive data (secrets, PII, tokens)

### Git conventions (Conventional Commits)

Format: `type(scope): short imperative description`
Types: `feat` · `fix` · `docs` · `test` · `refactor` · `chore` · `security` · `perf`
Scope = impacted component/module (defined in Part B). **No commit without green tests or with secrets.**

---

## A4 · TESTS — ABSOLUTE RULES

Test suite must pass before every commit. Commands defined in B4.

| Level | Trigger | Minimum |
|-------|---------|---------|
| **Unit** | Every new public function / method | 80% branches |
| **Integration** | Every cross-component interaction | Nominal + error paths |
| **E2E** | Critical business workflows | Happy path + edge cases |
| **Security** | Every endpoint, every crypto op | Auth, perms, injection |

**Naming:** `[Subject]_[Scenario]_[ExpectedResult]` — e.g. `CreateUser_WithDuplicateEmail_ThrowsConflictError`

**Rules:** one test = one behavior · mocks only at system boundaries · deterministic · no arbitrary `sleep`

---

## A5 · SECURITY — SYSTEMATIC CHECKLIST

**Secrets & Credentials**
- [ ] No hardcoded secrets (token, key, password, DSN)
- [ ] Secrets from environment variables or a vault only
- [ ] `.gitignore` covers all local config files

**Validation & Injection**
- [ ] All external inputs validated and sanitized server-side
- [ ] DB queries via ORM or prepared statements — no string concatenation
- [ ] No path traversal possible on file operations

**Authentication & Authorization**
- [ ] Every endpoint checks authentication
- [ ] Permissions verified before any sensitive operation
- [ ] Principle of least privilege applied

**Dependencies**
- [ ] No known critical CVE in added dependencies
- [ ] Versions pinned — no `latest` in production

**Cryptography** (if applicable)
- [ ] Approved algorithms: SHA-256+, AES-256, RSA-4096, ECDSA P-256+
- [ ] Cryptographic random only — never `Math.random()` for crypto
- [ ] IV/Nonce never reused

---

## A6 · DOCUMENTATION

**ADR**: any architectural change requires an ADR **before** implementation.
Location: `docs/adr/ADR-NNN-short-title.md` — create via `/adr [decision]`

**Code**: every public export has a doc comment · TODO only with ticket ref: `TODO(PROJ-123)` · no commented-out code

---

## A7 · AVAILABLE SLASH COMMANDS

| Command | Description |
|---------|-------------|
| `/plan [request]` | Generate a structured plan — waits for approval |
| `/adr [decision]` | Create a numbered ADR in `docs/adr/` |
| `/review` | Quality + security + performance review of session code |
| `/security-audit [scope]` | Targeted security audit: secrets, crypto, auth, injection |
| `/debug [problem]` | Systematic debugging: reproduce → isolate → fix |

---

## A8 · OBSERVABILITY

**Tracing**: instrument HTTP entry points, events, and jobs with **OpenTelemetry** · propagate `traceparent` header · never generate trace-id manually · export target defined in B6

**Metrics** (Prometheus format): request latency histogram (P50/P95/P99) · error rate per HTTP code · request volume · business metrics defined in B6

**Health checks**: `GET /health/live` (process alive) · `GET /health/ready` (dependencies reachable) · return `503` if critical dependency unavailable

**Rules**: no trace-id in public API responses · error spans include message + type, not full stack trace · no PII in metric labels

---

## A9 · AI-ASSISTED DEVELOPMENT

- Break any request involving > 200 lines into separate tasks before submitting
- Open each session with: "Working on `<X>`, current state: `<Y>`"
- Use `/debug` for bugs — more effective than free-form descriptions
- A human reads the full diff before every merge, even if `/review` returns PASS
- The approved plan is a contract — any deviation must be flagged and re-approved

**Known limitations**: no memory between sessions — CLAUDE.md is the shared memory · plans may underestimate system interactions: get an external review for critical tasks · generated tests must be read and understood, not just executed

---

## A10 · PERFORMANCE

- Measure before optimizing — no premature optimization without profiling data
- Define performance budgets in B6 **before** coding (typical: API P99 < 500ms, bundle < 500KB, LCP < 2.5s)
- Any regression detected in `/review` is a blocker

Performance anti-patterns checklist: see `/review` grid.

---

# PART B — PROJECT CONFIGURATION
<!-- Replace all <angle brackets> with real values. Remove inapplicable lines. -->

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

<!-- Preset content injected here by init.sh -->

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

```bash
<install_cmd>     # install dependencies
<test_cmd>        # run tests — required before every commit
<lint_cmd>        # lint / style check — zero warnings
<typecheck_cmd>   # type check (if applicable)
<build_cmd>       # full build
<dev_cmd>         # run locally
```

---

## B5 · PROJECT ARCHITECTURE

```
<project-name>/
├── CLAUDE.md
├── docs/
│   ├── adr/        # Architecture Decision Records
│   ├── specs/      # Functional specifications
│   └── runbooks/
├── .claude/
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
>
```

---

## B7 · EXTERNAL INTEGRATIONS

| System | Role | Protocol | Notes |
|--------|------|----------|-------|
| `<system>` | `<role>` | `<REST / gRPC / event>` | `<notes>` |

---

## B8 · TEAM CONTEXT & WORKFLOW

```
Main branches    : <main | master | develop>
Merge strategy   : <PR with mandatory review | trunk-based | gitflow>
Environments     : <dev | staging | prod>
Code review      : <required approvers, criteria>
Deploy gate      : <who can deploy to prod>
```
