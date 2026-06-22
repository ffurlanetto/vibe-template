# Developer Installation Guide

> **Audience:** Software engineers setting up the Claude Code template on a new or existing project.
> **Time required:** ~5 minutes for a new project, ~15 minutes if integrating into an existing codebase.

---

## Prerequisites

| Requirement | Minimum version | Check |
|-------------|----------------|-------|
| [Claude Code CLI](https://claude.ai/code) | Latest | `claude --version` |
| Git | 2.x+ | `git --version` |
| Python | 3.8+ | `python3 --version` |
| bash | 3.2+ | `bash --version` |

> **Python 3** is required for the built-in secret detection hooks. It is available by default on macOS and most Linux distributions.

---

## Option A — New project (recommended)

### 1. Clone or download the template

```bash
git clone <template-repo-url> claude-template
cd claude-template
```

### 2. Run the init script

```bash
./init.sh <project-name> <stack>
```

**Available stacks:**

| Stack | Technology |
|-------|-----------|
| `java-spring` | Java 21 / Spring Boot 3 |
| `java-spring-gradle` | Java 21 / Spring Boot 3 / Gradle |
| `java-quarkus` | Java 21 / Quarkus 3 / Gradle |
| `dotnet-aspnet` | .NET 8 / ASP.NET Core |
| `python-fastapi` | Python 3.12 / FastAPI |
| `go` | Go 1.23 / chi |
| `nestjs` | Node.js 22 / NestJS |
| `rust` | Rust (axum / actix-web) |
| `rails` | Ruby 3.3 / Rails 7 |
| `react-native` | React Native (Expo or CLI) |
| `flutter` | Flutter / Dart |
| `monorepo` | Nx or Turborepo |
| `frontend` | Vue 3 / Angular / React |
| `sre` | SRE / Infrastructure as Code (Terraform, Kubernetes) |

**Example:**
```bash
./init.sh payment-api python-fastapi
# or with a custom destination:
./init.sh payment-api python-fastapi ~/projects/payment-api
```

### 3. Complete the project configuration

Open `CLAUDE.md` in your project and fill in **sections B1 through B8**. Replace every `<angle bracket>` placeholder with a real value.

Key sections:
- **B1** — Project name, type, ticket prefix
- **B2** — Full tech stack (remove inapplicable lines)
- **B3** — The preset was auto-injected; customize naming conventions and directory structure
- **B4** — Replace `<install_cmd>`, `<test_cmd>`, `<lint_cmd>`, `<build_cmd>`, `<dev_cmd>` with your actual commands
- **B6** — Critical: list SLAs, compliance constraints, data sovereignty rules

### 4. Activate CI permissions

In `.claude/settings.json`, uncomment the `allow` entries for your stack:

```json
// For a Python project, uncomment:
"Bash(pytest*)",
"Bash(ruff check*)",
"Bash(ruff format*)",
"Bash(mypy*)",
"Bash(uv sync*)",
```

### 5. Adapt the CI pipeline

Edit `.github/workflows/quality-gate.yml` — replace the four placeholder `echo` steps with your actual B4 commands.

### 6. Verify the setup

```bash
cd <your-project>
claude
```

Inside the Claude session, type:
```
/plan Create a GET /health endpoint that returns {"status": "ok"}
```

Expected result: Claude generates a structured plan and waits for your approval before writing any code.

---

## Option B — Integrate into an existing project

### 1. Copy the `.claude/` directory

```bash
cp -r claude-template/.claude /path/to/existing-project/
cp claude-template/CLAUDE.md /path/to/existing-project/
```

### 2. Merge CLAUDE.md with your existing documentation

- **Part A** (A1–A10): keep as-is — do not modify
- **Part B** (B1–B8): fill in from your existing project's conventions

### 3. Copy the docs structure (optional but recommended)

```bash
cp -r claude-template/docs /path/to/existing-project/
```

### 4. Follow steps 4–6 from Option A

---

## Updating the template

When a new version of the template is released:

```bash
# Check your project's current template version
cat .claude/.template-version

# Check the latest template version
cat /path/to/claude-template/VERSION
```

**To update Part A only** (never overwrite Part B):

```bash
# View what changed in Part A
diff /path/to/claude-template/CLAUDE.md CLAUDE.md

# Manually copy only the Part A changes into your CLAUDE.md
# Part A ends just before "# PART B — PROJECT CONFIGURATION"
```

---

## Daily workflow

Once the template is set up, every development session follows this pattern:

```
1. Open a Claude session in your project directory
   $ claude

2. Describe what you want to build
   "Add an endpoint to export user data as CSV"

3. Claude generates a /plan and waits for your approval
   → Review the plan, check file paths and test coverage
   → Reply: "ok" / "proceed" / "approved"

4. Claude implements step by step

5. Run /review before committing
   /review

6. Commit only if review returns 🟢 PASS
```

---

## Available slash commands

| Command | When to use |
|---------|------------|
| `/plan [request]` | Before any implementation — mandatory |
| `/adr [decision]` | Before any architectural change |
| `/review` | Before every commit |
| `/security-audit [scope]` | Before merging security-sensitive code |
| `/debug [problem]` | When hitting a bug — follow the structured workflow |

---

## Troubleshooting

**The secret detection hook doesn't trigger**

Verify Python 3 is in `PATH`:
```bash
python3 --version
```
If Python 3 is absent, install it or adjust the hook command in `.claude/settings.json`.

**Claude ignores the plan-first rule**

Ensure `CLAUDE.md` is at the root of the directory where you launch `claude`. Claude Code reads CLAUDE.md from the current working directory.

**The /plan command is not recognized**

Verify the commands directory exists and contains the file:
```bash
ls .claude/commands/
# Should list: plan.md, adr.md, review.md, security-audit.md, debug.md
```

**Permissions prompt on every command**

In `.claude/settings.json`, uncomment the allow entries for your stack. The file uses string-based comments — entries starting with `//` are treated as documentation and ignored by Claude Code.

---

## Reference

- Overview & quick start: `README.md`
- Full template documentation: `SETUP.md`
- Common kernel rules: `CLAUDE.md` Part A (A1–A10)
- Project configuration: `CLAUDE.md` Part B (B1–B8)
- ADR process: `docs/adr/README.md`
- Spec template: `docs/specs/SPEC-TEMPLATE.md`
