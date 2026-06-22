# Agent Installation Guide

> **Audience:** LLM agents or automated systems tasked with bootstrapping a new project using this template.
> **Format:** Deterministic, step-by-step instructions. Follow exactly. Do not infer or skip steps.

---

## Overview

This guide instructs an LLM agent to configure a new software project using the Claude Code template. The agent will:

1. Read existing project context
2. Copy and configure the template files
3. Fill in the project-specific configuration (Part B)
4. Verify the installation

---

## Required inputs (collect before starting)

Before executing any step, confirm you have the following information. If any value is missing, **ask the user** before proceeding.

| Input | Variable | Example | Required |
|-------|----------|---------|----------|
| Project name | `PROJECT_NAME` | `payment-api` | ✅ |
| Stack | `STACK` | `python-fastapi` | ✅ |
| Project description | `DESCRIPTION` | `REST API for payment processing` | ✅ |
| Project type | `PROJECT_TYPE` | `API` | ✅ |
| Team / owner | `TEAM` | `payments-team` | ✅ |
| Ticket prefix | `TICKET_PREFIX` | `PAY` | ✅ |
| Destination path | `DEST` | `/workspace/payment-api` | ✅ |
| Template path | `TEMPLATE_PATH` | `/path/to/template` | ✅ |
| Main branch | `MAIN_BRANCH` | `main` | ✅ |
| Merge strategy | `MERGE_STRATEGY` | `PR with mandatory review` | ✅ |
| Tech stack details | (see B2 fields below) | | ✅ |

**Valid stacks:** `java-spring` · `dotnet-aspnet` · `python-fastapi` · `go` · `nestjs` · `rust` · `rails` · `react-native` · `flutter` · `monorepo` · `frontend`

If `STACK` is not in the list above, stop and ask the user to choose a valid stack or provide their own preset content.

---

## Step 1 — Verify template integrity

Before copying, verify that the required template files exist. If any file is missing, stop and report the missing file.

**Required files to verify:**
```
{TEMPLATE_PATH}/CLAUDE.md
{TEMPLATE_PATH}/.claude/settings.json
{TEMPLATE_PATH}/.claude/commands/plan.md
{TEMPLATE_PATH}/.claude/commands/adr.md
{TEMPLATE_PATH}/.claude/commands/review.md
{TEMPLATE_PATH}/.claude/commands/security-audit.md
{TEMPLATE_PATH}/.claude/commands/debug.md
{TEMPLATE_PATH}/.claude/presets/{STACK}.md
{TEMPLATE_PATH}/docs/adr/README.md
{TEMPLATE_PATH}/docs/specs/SPEC-TEMPLATE.md
```

**Action:** Run `ls` or equivalent to confirm each file exists. If `{TEMPLATE_PATH}/.claude/presets/{STACK}.md` does not exist, stop and ask the user to choose a different stack.

---

## Step 2 — Copy the template

```bash
mkdir -p {DEST}
cp -r {TEMPLATE_PATH}/. {DEST}/
rm -f {DEST}/init.sh
```

**Verify:** `{DEST}/CLAUDE.md` exists after the copy.

---

## Step 3 — Fill in CLAUDE.md Part B

Read the file `{DEST}/CLAUDE.md`. Locate the section `# PART B — PROJECT CONFIGURATION`. Fill in every placeholder using the values collected in the Required Inputs section.

### B1 — Project Identity

Replace exactly:
```
<PROJECT_NAME>   → {PROJECT_NAME}
<One sentence describing what this project does>  → {DESCRIPTION}
<web app | API | CLI | library | service | monorepo | ...>  → {PROJECT_TYPE}
<team name or responsible person>  → {TEAM}
<PROJ>  → {TICKET_PREFIX}
```

### B2 — Tech Stack

Keep only the lines that apply to this project. Remove all others. Fill in specific versions where known.

**Minimum required:** at least one Backend or Frontend line must be filled in.

### B3 — Language / Framework Standards

Read the file `{TEMPLATE_PATH}/.claude/presets/{STACK}.md`. Copy its entire content and **replace** the `<...>` block in the B3 "Code conventions" section with the preset content.

Do not modify the preset content — paste it verbatim.

### B4 — Development Commands

Fill in the six commands. Use the values from the preset file (`{STACK}.md`) under "Commands (B4)" as the default. If the user provided specific commands, use those instead.

Replace:
```
<install_cmd>   → [exact install command for this project]
<test_cmd>      → [exact test command]
<lint_cmd>      → [exact lint command]
<typecheck_cmd> → [exact type-check command, or remove this line if not applicable]
<build_cmd>     → [exact build command]
<dev_cmd>       → [exact dev server command]
```

### B5 — Architecture

If the user provided a directory structure or module breakdown, fill it in here. If not, leave the template placeholder and note it as "TO BE COMPLETED BY THE TEAM".

### B6 — Project-Specific Constraints

**Do not invent constraints.** Only fill in what the user explicitly stated. If none were provided, leave the placeholder and add a comment: `# No specific constraints defined yet`.

### B7 — External Integrations

List only the integrations explicitly mentioned by the user. Leave the placeholder row if none were specified.

### B8 — Team Context & Workflow

Replace:
```
<main | master | develop>  → {MAIN_BRANCH}
<PR with mandatory review | trunk-based | gitflow>  → {MERGE_STRATEGY}
<dev | staging | prod | ...>  → [environments if known, else "TO BE DEFINED"]
<number of required approvers, criteria>  → [if known, else "TO BE DEFINED"]
<who can deploy to prod, approval process>  → [if known, else "TO BE DEFINED"]
```

---

## Step 4 — Configure settings.json

Read `{DEST}/.claude/settings.json`.

In the `"allow"` array, locate the section corresponding to `{STACK}`. Remove the `// ` prefix from every line in that section to uncomment the permissions.

**Example — for `python-fastapi`:**

Before:
```json
"// Bash(pytest*)",
"// Bash(ruff check*)",
"// Bash(ruff format*)",
"// Bash(mypy*)",
"// Bash(uv sync*)",
"// Bash(uv run*)",
"// Bash(pip install*)",
```

After:
```json
"Bash(pytest*)",
"Bash(ruff check*)",
"Bash(ruff format*)",
"Bash(mypy*)",
"Bash(uv sync*)",
"Bash(uv run*)",
"Bash(pip install*)",
```

Leave all other stack sections commented out.

---

## Step 5 — Update the ADR index

Read `{DEST}/docs/adr/README.md`. Replace:
```
<PROJECT_NAME>  → {PROJECT_NAME}
```

---

## Step 6 — Create the .gitignore

If `{DEST}/.gitignore` does not exist, create it with the following content:

```
# Secrets & credentials
.env
.env.local
.env.production
.env.staging
*.key
*.pem
*.p12
*.pfx
*.jks
*.credentials
id_rsa
id_rsa.pub
id_ed25519
id_ed25519.pub

# OS
.DS_Store
Thumbs.db

# Editors
.idea/
.vscode/settings.json
*.swp
```

If `.gitignore` already exists, append only the "Secrets & credentials" section if it is not already present. Do not overwrite the existing file.

---

## Step 7 — Configure the CI pipeline

Read `{DEST}/.github/workflows/quality-gate.yml`. Replace the four placeholder `echo` steps with the actual commands from B4:

```yaml
- name: Install dependencies
  run: {install_cmd}

- name: Run tests
  run: {test_cmd}

- name: Lint
  run: {lint_cmd}

- name: Build
  run: {build_cmd}
```

If `<typecheck_cmd>` was filled in B4, add a fifth step:

```yaml
- name: Type check
  run: {typecheck_cmd}
```

---

## Step 8 — Write the template version marker

Read `{TEMPLATE_PATH}/VERSION`. Write its content (without trailing newline) to:
```
{DEST}/.claude/.template-version
```

---

## Step 9 — Verification checklist

After completing all steps, verify each item. Report any failure before declaring success.

```
□ {DEST}/CLAUDE.md — no remaining <angle bracket> placeholders in Part B
□ {DEST}/CLAUDE.md — Part A unchanged (compare with {TEMPLATE_PATH}/CLAUDE.md Part A)
□ {DEST}/.claude/settings.json — correct stack permissions uncommented
□ {DEST}/.claude/settings.json — deny list and hooks unchanged
□ {DEST}/.gitignore — exists and covers .env, *.pem, *.key
□ {DEST}/.github/workflows/quality-gate.yml — no remaining echo placeholders
□ {DEST}/docs/adr/README.md — PROJECT_NAME substituted
□ {DEST}/.claude/.template-version — file exists with version number
□ {DEST}/.claude/commands/ — contains: plan.md, adr.md, review.md, security-audit.md, debug.md
□ {DEST}/docs/specs/SPEC-TEMPLATE.md — exists (no modification required)
```

**For each □ that fails:** describe exactly what is missing and what the correct value should be. Do not silently skip failures.

---

## Step 10 — Report to the user

After all verifications pass, generate a summary report in this exact format:

```
## Template Installation Summary

Project      : {PROJECT_NAME}
Stack        : {STACK}
Location     : {DEST}
Template v   : [contents of .claude/.template-version]

### Completed
- [x] Template files copied
- [x] CLAUDE.md Part B filled (sections B1–B8)
- [x] Stack permissions activated in settings.json
- [x] CI pipeline configured
- [x] .gitignore created / updated
- [x] ADR index configured
- [x] Version marker written

### Requires manual completion
- [ ] B5 — Project architecture (directory structure and module responsibilities)
      Reason: insufficient context provided
- [ ] B6 — Project-specific constraints
      Reason: [reason if applicable]

### Recommended next steps
1. Review CLAUDE.md Part B and complete any remaining TO BE DEFINED sections
2. Run the first test: claude → /plan Create a GET /health endpoint
3. Create the first ADR for any initial architectural decision: /adr [decision]
```

Replace `### Requires manual completion` with the actual list of items that could not be filled in automatically. If all sections are complete, replace the block with `### All sections completed automatically`.

---

## Error handling

| Situation | Action |
|-----------|--------|
| Missing required input | Stop. Ask the user for the missing value. Do not guess. |
| Unknown stack | Stop. List valid stacks. Ask the user to choose. |
| Template file missing | Stop. Report the exact missing path. |
| Destination already exists and non-empty | Ask the user to confirm overwrite or provide a different path. |
| CLAUDE.md still contains `<angle brackets>` after Step 3 | List all remaining placeholders. Ask the user to provide values. |
| `.claude/settings.json` cannot be parsed | Report the parse error. Do not attempt to modify the file. |

**Never silently ignore an error.** Always report failures explicitly, even if you can continue with the remaining steps.
