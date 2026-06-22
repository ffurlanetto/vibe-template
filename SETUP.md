# Claude Code Template — Usage Guide v2.0

## Template structure

```
template/
├── README.md                          # Project overview and quick start
├── CLAUDE.md                          # Main configuration (Part A + B)
├── SETUP.md                           # Detailed usage guide (this file)
├── INSTALL-DEV.md                     # Installation guide for developers
├── INSTALL-AGENT.md                   # Installation guide for LLM agents
├── VERSION                            # Template version
├── init.sh                            # Automated bootstrap script
├── docs/
│   ├── adr/
│   │   └── README.md                  # ADR index (keep empty at start)
│   └── specs/
│       └── SPEC-TEMPLATE.md           # Functional specification template
├── .github/
│   └── workflows/
│       └── quality-gate.yml           # Base CI pipeline (to adapt)
└── .claude/
    ├── settings.json                  # Permissions and hooks (to adapt)
    ├── commands/
    │   ├── plan.md                    # /plan
    │   ├── adr.md                     # /adr
    │   ├── review.md                  # /review
    │   ├── security-audit.md          # /security-audit
    │   └── debug.md                   # /debug
    └── presets/
        ├── java-spring.md             # Java / Spring Boot
        ├── dotnet-aspnet.md           # .NET / ASP.NET Core
        ├── python-fastapi.md          # Python / FastAPI
        ├── go.md                      # Go
        ├── nestjs.md                  # Node.js / NestJS
        ├── rust.md                    # Rust
        ├── rails.md                   # Ruby on Rails
        ├── react-native.md            # React Native (Expo / CLI)
        ├── flutter.md                 # Flutter / Dart
        ├── monorepo.md                # Monorepo (Nx / Turborepo)
        └── frontend.md               # Vue 3 / Angular / React
```

---

## Bootstrap a new project (2 minutes)

### Option A — Automated script (recommended)

```bash
# From the template root directory:
./init.sh <project-name> <stack> [destination]

# Examples:
./init.sh my-api python-fastapi
./init.sh backend-service go /workspace/my-project
./init.sh frontend-app frontend ~/projects/frontend-app
```

**Available stacks:** `java-spring` · `dotnet-aspnet` · `python-fastapi` · `go` · `nestjs` · `rust` · `rails` · `react-native` · `flutter` · `monorepo` · `frontend`

The script automatically creates:
- The full directory structure
- A `.gitignore` covering common secrets
- The CI pipeline `.github/workflows/quality-gate.yml`
- The version marker `.claude/.template-version`

**After the script:** complete sections B1–B8 in `CLAUDE.md` and adapt `quality-gate.yml`.

---

### Option B — Manual bootstrap (for full control)

#### Step 1 — Copy the template

```bash
cp -r template/ /path/to/new-project/
cd /path/to/new-project
```

#### Step 2 — Fill in Part B of CLAUDE.md

Open `CLAUDE.md` and complete all sections `B1` to `B8`:
- Replace all `<angle bracket>` values with real values
- Remove inapplicable lines

**Using presets:**
```bash
# Example for a Python/FastAPI project:
cat .claude/presets/python-fastapi.md
# → Copy the content into section B3 of CLAUDE.md
```

#### Step 3 — Adapt settings.json

In `.claude/settings.json`, uncomment the `allow` blocks matching your stack:

```json
// Uncomment for a Python project:
"Bash(pytest*)",
"Bash(ruff check*)",
"Bash(mypy*)",
// etc.
```

#### Step 4 — Verify

```bash
claude
# Inside the session:
/plan Create a GET /health endpoint that returns the application status
# → Should generate a structured plan and wait for your approval
```

---

## Daily workflow

```
Write the request
        ↓
Claude reads CLAUDE.md (Part A + B)
        ↓
/plan → structured plan submitted for approval
        ↓
You reply: "ok" / "proceed" / "approved"
        ↓
Step-by-step implementation
        ↓
/review → quality + security report
        ↓
Commit if review PASS
```

**For bugs:** use `/debug` rather than a free-form description — the structured workflow is significantly more effective.

---

## Available commands

| Command | Usage |
|---------|-------|
| `/plan [request]` | Generate a plan before any development |
| `/adr [decision]` | Document an architectural decision |
| `/review` | Quality + security review of the session's code |
| `/security-audit [scope]` | Targeted security audit |
| `/debug [problem]` | Systematic debugging: reproduce → isolate → fix |

---

## Built-in security hooks

`settings.json` includes two active hooks from day one:

| Hook | Trigger | Behavior |
|------|---------|----------|
| **PostToolUse** | After each `Edit` / `Write` | Scans the modified file for hardcoded secrets — warning if detected |
| **PreToolUse** | Before `git commit` | Scans staged files — **blocks the commit** if a secret is detected |

These hooks work without additional configuration. They require Python 3 (available on any modern development environment).

---

## Template maintenance principles

- **Part A**: never modify per project — update only in the template source and increment `VERSION`
- **Part B**: project-specific — document all local conventions here
- **Presets**: enrich over time — every reusable new pattern deserves a preset
- **ADR**: create at least one ADR for the initial structural decisions of the project
- **VERSION**: track the template version in each project via `.claude/.template-version`

---

## Updating the template in an existing project

```bash
# Check the version used in the project
cat .claude/.template-version

# See the current version of the template source
cat /path/to/template/VERSION

# Update Part A only (common kernel)
# Do NOT overwrite Part B — it is project-specific
diff /path/to/template/CLAUDE.md CLAUDE.md
```
