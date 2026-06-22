# CLAUDE.md

<!--
  ╔══════════════════════════════════════════════════════════════════╗
  ║  CONFIGURATION GUIDE                                             ║
  ║                                                                  ║
  ║  This file is split into two parts:                              ║
  ║                                                                  ║
  ║  ── PART A: COMMON KERNEL ───────────────────────────────────── ║
  ║     Do not modify. Universal rules applied to every project.    ║
  ║     Update only via the template source.                        ║
  ║                                                                  ║
  ║  ── PART B: PROJECT CONFIGURATION ──────────────────────────── ║
  ║     Fill in for each project. Replace all values in             ║
  ║     angle brackets  <...>  with real values.                    ║
  ╚══════════════════════════════════════════════════════════════════╝
-->

---

# PART A — COMMON KERNEL
<!-- ⛔ DO NOT MODIFY THIS SECTION -->

---

## A1 · CORE RULE: PLAN FIRST

**For every request, without exception:**

1. **ANALYZE** the request — impacts, dependencies, regression risks
2. **WRITE** a structured plan in the format defined in A2 below
3. **WAIT** for explicit approval before any implementation
   - Accepted keywords: `ok` · `proceed` · `go` · `approved` · `✓`
4. **IMPLEMENT** following the approved plan, step by step
5. **VERIFY**: tests green · lint clean · build OK · zero regressions

> ⛔ No code before the plan is approved.
> ⛔ Any deviation from the approved plan must be flagged and re-approved.
> ⛔ An incomplete plan (missing tests, unlisted impacts) must be completed before submission.

---

## A2 · IMPLEMENTATION PLAN FORMAT

```
## Plan: [Concise task title]

### Context
[Problem solved, value delivered, relationship to project modules]

### Scope
- Files created    : [list with full paths]
- Files modified   : [list with full paths]
- Files deleted    : [list or "none"]
- Impacted components/modules : [list]
- ADR required : yes / no — [if yes, to be created before implementation]

### Implementation steps
1. [Precise action — file(s) involved]
2. [...]

### Required tests
- Unit        : [functions / classes / methods to cover]
- Integration : [component interactions to test]
- Regression  : [what could break and how to verify]
- Security    : [auth / perms / crypto checkpoints]

### Acceptance criteria
- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] All existing tests pass (zero regressions)
- [ ] Lint / type-check / format OK
- [ ] Security checklist completed

### Risks & trade-offs
- [Identified risk → mitigation]

### Documentation
- [ ] ADR created if architectural decision
- [ ] Comments/docs on public exports
- [ ] README / changelog updated if applicable

---
✅ Awaiting approval before implementation.
```

---

## A3 · UNIVERSAL DEVELOPMENT STANDARDS

### Non-negotiable principles

- **Separation of concerns**: business logic isolated from handlers / controllers / routes
- **Explicit interfaces / contracts** between components (facilitates mocking and testing)
- **Fail fast**: validate inputs at the boundary, never propagate invalid state
- **Immutability**: prefer immutable structures, avoid hidden side effects
- **Least surprise**: name things by what they actually do, not by intent

### Error handling

- Errors are always wrapped with context (`cause: original error`)
- Never silently swallow an error (`catch (e) {}` is forbidden)
- API error messages are generic; detail goes in structured logs
- Distinguish: expected error (business) vs unexpected error (system)

### Logging

- Structured logging required (JSON or equivalent) — never `print` / `console.log` in production
- Levels: `DEBUG` (dev) · `INFO` (nominal) · `WARN` (degraded) · `ERROR` (action required)
- Never log sensitive data (secrets, PII, tokens, production hashes)

### Git conventions (Conventional Commits)

Format: `type(scope): short imperative description`

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `test` | Add / fix tests |
| `refactor` | Refactoring without behavior change |
| `chore` | Maintenance, dependencies, config |
| `security` | Security fix or hardening |
| `perf` | Performance improvement |

- Scope = name of the impacted component/module (defined in Part B)
- **No commit without green tests**
- **No commit with secrets or credentials**

---

## A4 · TESTS — ABSOLUTE RULES

### Zero regressions tolerated

The complete test suite must pass before every commit.
Exact commands are defined in **Part B · B4**.

### Required test levels

| Level | Trigger | Minimum coverage |
|-------|---------|-----------------|
| **Unit** | Every new public function / method | 80% of branches |
| **Integration** | Every interaction between distinct components | Nominal paths + errors |
| **E2E** | Critical business workflows | Happy path + edge cases |
| **Security** | Every exposed endpoint, every crypto operation | Auth, perms, injection |

### Test naming (universal pattern)

```
[Function/Class]_[Scenario]_[ExpectedResult]

Examples:
  CreateUser_WithValidInput_ReturnsCreatedUser
  CreateUser_WithDuplicateEmail_ThrowsConflictError
  ParseToken_WithExpiredToken_ThrowsUnauthorizedError
```

### Test quality rules

- One test = one behavior (no conditional logic inside tests)
- Mocks only make sense at system boundaries (I/O, network, time)
- Tests must be deterministic (no dependency on system time or execution order)
- No arbitrary `sleep` / `wait` — use explicit waiting mechanisms

---

## A5 · SECURITY — SYSTEMATIC CHECKLIST

To verify for **every change**:

**Secrets & Credentials**
- [ ] No hardcoded secrets (token, key, password, DSN)
- [ ] Secrets come exclusively from environment variables or a vault
- [ ] `.gitignore` covers all local config files

**Validation & Injection**
- [ ] All external inputs are validated and sanitized server-side
- [ ] Database queries via ORM or prepared statements (no string concatenation)
- [ ] No path traversal possible on file operations

**Authentication & Authorization**
- [ ] Every endpoint checks authentication
- [ ] Permissions are verified before any sensitive operation
- [ ] Principle of least privilege applied

**Dependencies**
- [ ] No known critical CVE in added dependencies
- [ ] Versions pinned (no `latest` in production)

**Cryptography** (if applicable)
- [ ] Approved algorithms only: SHA-256+, AES-256, RSA-4096, ECDSA P-256+
- [ ] Cryptographic random generation (never `Math.random()` or equivalent for crypto)
- [ ] IV/Nonce never reused

---

## A6 · DOCUMENTATION

### ADR (Architecture Decision Records)

Any architectural change requires an ADR **before** implementation.
Location: `docs/adr/ADR-NNN-short-title.md`
Create via: `/adr [decision description]`

### Code documentation

- Every public exported element: documentation comment (Javadoc / GoDoc / JSDoc / docstring…)
- Complex interfaces include a usage example
- TODO only with ticket reference: `TODO(PROJ-123): description`
- No commented-out code in production (use Git for history)

---

## A7 · AVAILABLE SLASH COMMANDS

| Command | Description |
|---------|-------------|
| `/plan [request]` | Generate a structured plan — waits for approval before implementation |
| `/adr [decision]` | Create a numbered ADR in `docs/adr/` |
| `/review` | Quality + security review of code changed in the session |
| `/security-audit [scope]` | Targeted security audit: secrets, crypto, auth, injection |
| `/debug [problem]` | Systematic debugging workflow: reproduce → isolate → fix |

---

## A8 · OBSERVABILITY

### Structured logging (see A3)

JSON required, levels `DEBUG / INFO / WARN / ERROR` — see A3.

### Distributed tracing

- Instrument HTTP entry points, events, and jobs with **OpenTelemetry**
- Propagate `trace-id` across all inter-service calls (header `traceparent`)
- Never generate a trace-id manually — use the OTel SDK
- Export to Jaeger / Tempo / Datadog per project infra (B6)

### Application metrics

- Expose `/metrics` in Prometheus format where applicable
- Minimum metrics to instrument:
  - Request latency: histogram (P50, P95, P99)
  - Error rate: counter per HTTP code
  - Request volume: counter
  - Project-specific business metrics (define in B6)

### Health checks

- `GET /health/live` : process is alive (no dependencies checked)
- `GET /health/ready` : critical dependencies are reachable (DB, cache, brokers)
- Return `503` if a critical dependency is unavailable

### Rules

- No trace-id or correlation-id in public API responses
- Error spans include message and error type (not the full stack trace)
- Metrics labels never contain personal data

---

## A9 · AI-ASSISTED DEVELOPMENT — BEST PRACTICES

### Writing effective requests

- **One request = one clear, measurable objective** — avoid composite requests
- Always reference the files and components involved in the request
- Specify constraints not derivable from code (SLA, team decision, legal constraint)
- Tasks involving > 200 lines of code must be broken down before submission

### Recommended workflow

```
Write the request
        ↓
/plan → structured plan submitted for approval
        ↓
Approve or amend the plan (keyword: ok / proceed / approved)
        ↓
Step-by-step implementation
        ↓
/review → quality + security report
        ↓
Commit if review PASS — never without review
```

### Session context management

- Start each new session with a status update: "I'm working on X, current state is Y"
- If a session exceeds 20 exchanges, open a new session with a context summary
- CLAUDE.md is read at every session — keeping Part B up to date is the best way to preserve context
- For complex bugs, use `/debug` rather than a free-form description

### Non-negotiable human validation

- A human reads the full diff before every merge, even if `/review` returns PASS
- The approved plan is a contract — any deviation is flagged and re-approved before implementation
- Never accept "it works" without understanding why: read the generated code, don't just run it

### Known limitations

- The AI has no memory between sessions — CLAUDE.md is your shared memory
- Generated plans may underestimate the complexity of system interactions: validate with an external perspective for critical tasks
- Generated tests must be read and understood, not just executed

---

## A10 · PERFORMANCE

### Principles

- Measure before optimizing — no premature optimization without profiling data
- Define performance budgets **before** coding, not after (see B6)
- Any performance regression detected in review is a blocker, same as a bug

### Performance budgets (define in B6)

| Metric | Typical target | Blocking if exceeded |
|--------|---------------|---------------------|
| API latency P99 | < 500 ms | Yes |
| API latency P50 | < 100 ms | No (warning) |
| Build time | < 5 min | No (warning) |
| Frontend bundle size | < 500 KB (initial) | Yes |
| LCP (Web Vitals) | < 2.5 s | Yes |

> The values above are examples. Define real budgets in **B6**.

### Anti-patterns to systematically avoid

**Database**
- N+1 queries: always check the number of queries generated on list endpoints
- Missing index on frequently filtered or joined columns
- Long-running transactions blocking rows

**Network / API**
- Unpaginated payloads on collections
- Missing HTTP cache (`Cache-Control`, `ETag`) on static resources
- Sequential calls where parallel calls are possible

**Frontend**
- Full component re-render when only state changes
- Unoptimized images (format, dimensions, lazy loading)
- Missing route-level bundle splitting

### Profiling — when and how

- Profile on data representative of production volume (not on empty datasets)
- Identify the **real** bottleneck before any fix (flamegraph, query plan, network waterfall)
- Document the measured gain after optimization in the commit message

### Benchmarks

- Benchmarks are versioned in the repository (`benches/` or equivalent)
- Compare benchmarks before/after any performance-critical code change
- Benchmark results are never compared across different environments

---

# PART B — PROJECT CONFIGURATION
<!-- ✏️  FILL IN THIS SECTION FOR EACH PROJECT -->
<!-- Replace all values in <angle brackets> with real values -->

---

## B1 · PROJECT IDENTITY

```
Project name  : <PROJECT_NAME>
Description   : <One sentence describing what this project does>
Type          : <web app | API | CLI | library | service | monorepo | ...>
Team / Owner  : <team name or responsible person>
Ticket prefix : <PROJ> (e.g. RAMP, MYAPP, API — used in TODOs and commits)
```

---

## B2 · TECH STACK

> Remove inapplicable lines. Add whatever is missing.

```
Backend   : <Java 21 / Spring Boot 3 | .NET 8 / ASP.NET Core | Python 3.12 / FastAPI
             | Go 1.23 / chi | Node.js 22 / NestJS | Ruby 3.3 / Rails | Rust 1.78 | ...>

Frontend  : <Vue 3 + Vuetify 3 | Angular 18 | React 18 + shadcn/ui | ...>

Mobile    : <React Native (Expo) | Flutter | N/A>

Database  : <PostgreSQL 16 | MySQL 8 | SQL Server 2022 | MongoDB 7 | ...>

Cache     : <Redis 7 | Memcached | N/A>

Messaging : <Kafka | RabbitMQ | Azure Service Bus | N/A>

Infra     : <Docker + Kubernetes | Azure AKS | AWS EKS | on-prem | ...>

CI/CD     : <GitHub Actions | GitLab CI | Jenkins | Azure DevOps | ...>
```

---

## B3 · LANGUAGE / FRAMEWORK-SPECIFIC STANDARDS

> Copy-paste the matching preset from `.claude/presets/` and complete it.

### Code conventions

```
<
Adapt to your stack — examples:

-- Java / Spring Boot --
- Annotations: @Service, @Repository, @Controller strictly separated
- DTOs for all API inputs/outputs (no JPA entities exposed directly)
- Tests: JUnit 5 + Mockito + AssertJ — 80% coverage minimum
- Lint: Checkstyle + SpotBugs — zero warnings
- Build: Maven / Gradle — no test skip in CI

-- .NET / ASP.NET Core --
- Architecture: Clean Architecture (Domain / Application / Infrastructure / Presentation)
- DTOs via record types (C# 9+)
- Tests: xUnit + Moq + FluentAssertions
- Lint: Roslyn analyzers — zero warnings treated as errors in CI

-- Python / FastAPI --
- Type hints required on all public functions
- Pydantic for input/output validation
- Tests: pytest + pytest-cov — 80% coverage minimum
- Lint: ruff + mypy strict

-- Go --
- Logging: log/slog — never fmt.Println
- Errors wrapped: fmt.Errorf("context: %w", err)
- Explicit interfaces for dependencies
- Tests: testing + testify — go test ./... -race

-- Vue 3 --
- Composition API only (<script setup>)
- State: Pinia — no Vuex
- No TypeScript any
- Tests: Vitest + Vue Test Utils

-- React --
- Functional components only
- State: Zustand or React Query
- No TypeScript any
- Tests: Vitest + React Testing Library
>
```

### Naming and structure

```
<
Describe project-specific naming conventions:
- File naming (kebab-case, PascalCase, snake_case...)
- Class, interface, type naming
- Directory structure
- Code organization pattern (feature-based, layer-based...)
>
```

---

## B4 · DEVELOPMENT COMMANDS

> These commands will be used automatically to validate every change.

```bash
# Install dependencies
<install_cmd>        # e.g. mvn install | dotnet restore | pip install -e . | go mod download | npm install

# Run tests (REQUIRED before every commit)
<test_cmd>           # e.g. mvn test | dotnet test | pytest | go test ./... -race | npm run test

# Check style / lint (zero warnings tolerated)
<lint_cmd>           # e.g. mvn checkstyle:check | dotnet build -warnaserror | ruff check . | golangci-lint run | npm run lint

# Type check (if applicable)
<typecheck_cmd>      # e.g. mypy . | tsc --noEmit | npm run type-check

# Full build
<build_cmd>          # e.g. mvn package | dotnet build | python -m build | go build ./... | npm run build

# Run locally
<dev_cmd>            # e.g. mvn spring-boot:run | dotnet run | uvicorn main:app | go run ./cmd/... | npm run dev
```

---

## B5 · PROJECT ARCHITECTURE

> Describe the directory structure and the responsibilities of each component.

```
<project-name>/
├── CLAUDE.md
├── docs/
│   ├── adr/                  # Architecture Decision Records
│   ├── specs/                # Functional specifications
│   └── runbooks/             # Operational procedures
├── .claude/
│   ├── commands/             # Slash commands
│   └── settings.json
│
├── <source-directory>/       # Detail according to stack
│   ├── <module-1>/           # Module description
│   ├── <module-2>/
│   └── <module-3>/
│
└── <tests-directory>/
```

### Modules / Components

| Component | Responsibility |
|-----------|---------------|
| `<module-1>` | <description> |
| `<module-2>` | <description> |

---

## B6 · PROJECT-SPECIFIC CONSTRAINTS

> List business, legal, performance, or infrastructure constraints
> that must be respected at all times.

```
<
Examples:
- GDPR compliance: no personal data in plaintext in logs
- SLA: P99 response time < 500ms on critical endpoints
- Multi-tenant: strict data isolation per tenant on every request
- Legal retention: artifacts kept 7 years minimum, immutable (WORM)
- Data sovereignty: entity X data must not leave region Y
- No cloud-vendor-specific dependencies in the domain layer
>
```

---

## B7 · EXTERNAL INTEGRATIONS

> List third-party systems this project interacts with.

| System | Role | Protocol | Notes |
|--------|------|----------|-------|
| `<system>` | `<role>` | `<REST / gRPC / event / ...>` | `<notes>` |

---

## B8 · TEAM CONTEXT & WORKFLOW

```
Main branches    : <main | master | develop>
Merge strategy   : <PR with mandatory review | trunk-based | gitflow>
Environments     : <dev | staging | prod | ...>
Code review      : <number of required approvers, criteria>
Deploy gate      : <who can deploy to prod, approval process>
```
