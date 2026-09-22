#!/usr/bin/env bash
# test-template.sh — end-to-end tests for init.sh and the scaffolder.
#
# Fast by design: it asserts what the template controls (layout, substitution,
# idempotence, the command contract). Actually building each stack is the job of
# the matrix in .github/workflows/template-ci.yml.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
ko() { printf '  \033[0;31m✗\033[0m %s — %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
has() { [ -e "$1/$2" ] && ok "$3" || ko "$3" "missing $2"; }
hasnt() { [ ! -e "$1/$2" ] && ok "$3" || ko "$3" "unexpected $2"; }

printf '\n\033[0;36minit.sh --dry-run writes nothing\033[0m\n'
DRY="$TMP/dry"
"$ROOT/init.sh" dry-demo go "$DRY" --dry-run --yes >/dev/null 2>&1
if [ ! -d "$DRY" ] || [ -z "$(ls -A "$DRY" 2>/dev/null)" ]; then
  ok "no file created"
else
  ko "no file created" "$(ls -A "$DRY" | head -3)"
fi

printf '\n\033[0;36mstructure mode, both agents\033[0m\n'
P="$TMP/structure"
"$ROOT/init.sh" struct-demo rust "$P" --scaffold structure --yes >/dev/null 2>&1

has "$P" "AGENTS.md"                    "AGENTS.md installed"
has "$P" "CLAUDE.md"                    "CLAUDE.md installed"
has "$P" "opencode.json"                "opencode.json installed"
has "$P" ".claude/skills/plan/SKILL.md" "skills installed (shared by both agents)"
has "$P" ".claude/agents/architect.md"  "subagents installed"
has "$P" ".claude/hooks/scan-secrets.sh" "hooks installed"
has "$P" ".opencode/agents/architect.md" "generated opencode agents installed"
has "$P" ".opencode/plugins/guardrails.js" "opencode guardrail plugin installed"
has "$P" "Makefile"                     "Makefile installed"
has "$P" ".gitignore"                   ".gitignore installed"
has "$P" ".github/workflows/quality-gate.yml" "CI pipeline installed"
has "$P" "docs/adr/ADR-001-agent-governed-development.md" "seed ADR installed"
has "$P" "docs/specs/SPEC-001-health-endpoints.md" "seed spec installed"
has "$P" ".claude/.template-version"    "template version recorded"
hasnt "$P" ".git/hooks/pre-rebase.sample~" "no stray backup files"
hasnt "$P" ".claude/commands"           "no legacy commands directory"
hasnt "$P" "init.sh"                    "init.sh not copied into the project"
hasnt "$P" "templates"                  "template internals not copied"
hasnt "$P" "scripts/scaffold"           "scaffold modules not copied"

grep -q "^@AGENTS.md" "$P/CLAUDE.md" && ok "CLAUDE.md imports AGENTS.md" || ko "CLAUDE.md import" "missing"
grep -q "struct-demo" "$P/AGENTS.md" && ok "project name substituted in B1" || ko "project name" "placeholder left"
grep -q "PROJECT_NAME" "$P/AGENTS.md" && ko "placeholder cleared" "<PROJECT_NAME> still present" || ok "placeholder cleared"
grep -q "Auto-injected preset: rust" "$P/AGENTS.md" && ok "preset injected into B3" || ko "preset injection" "marker missing"
grep -qP "^\tcargo test" "$P/Makefile" && ok "Makefile carries the stack commands" || ko "Makefile commands" "recipe missing"
for target in install test lint typecheck build dev audit check; do
  grep -qE "^${target}:" "$P/Makefile" || ko "make ${target}" "target missing"
done
ok "the eight contract targets are declared"

printf '\n\033[0;36midempotence\033[0m\n'
cp "$P/AGENTS.md" "$TMP/agents-before.md"
"$ROOT/init.sh" struct-demo rust "$P" --scaffold structure --yes >/dev/null 2>&1
if diff -q "$TMP/agents-before.md" "$P/AGENTS.md" >/dev/null; then
  ok "re-running init.sh changes nothing"
else
  ko "re-running init.sh changes nothing" "AGENTS.md was modified"
fi

printf '\n\033[0;36magent selection\033[0m\n'
C="$TMP/claude-only"
"$ROOT/init.sh" claude-demo go "$C" --agent claude --scaffold none --yes >/dev/null 2>&1
has "$C" "CLAUDE.md" "claude-only: CLAUDE.md present"
hasnt "$C" "opencode.json" "claude-only: no opencode config"
hasnt "$C" ".opencode" "claude-only: no .opencode directory"

O="$TMP/opencode-only"
"$ROOT/init.sh" oc-demo go "$O" --agent opencode --scaffold none --yes >/dev/null 2>&1
has "$O" "opencode.json" "opencode-only: opencode.json present"
has "$O" "AGENTS.md" "opencode-only: AGENTS.md present"
hasnt "$O" "CLAUDE.md" "opencode-only: no CLAUDE.md"
has "$O" ".claude/skills/plan/SKILL.md" "opencode-only: skills still installed (read from .claude/)"

printf '\n\033[0;36mwalking skeleton (go, offline-capable)\033[0m\n'
G="$TMP/walking"
"$ROOT/init.sh" walk-demo go "$G" --yes >/dev/null 2>&1
has "$G" "internal/health/health.go" "health endpoints generated"
has "$G" "internal/health/health_test.go" "health tests generated"
has "$G" "internal/example/example.go" "example slice generated"
has "$G" "cmd/server/main.go" "entry point generated"
grep -q "walk-demo" "$G/cmd/server/main.go" && ok "module path substituted in imports" || ko "module path" "placeholder left"
grep -q "@@" "$G/cmd/server/main.go" && ko "no placeholder left in code" "@@ token found" || ok "no placeholder left in code"

printf '\n\033[0;36mrejects bad input\033[0m\n'
"$ROOT/init.sh" x nonexistent-stack "$TMP/bad" --yes >/dev/null 2>&1 && ko "unknown stack rejected" "exited 0" || ok "unknown stack rejected"
"$ROOT/init.sh" x go "$TMP/bad2" --scaffold wrong --yes >/dev/null 2>&1 && ko "bad --scaffold rejected" "exited 0" || ok "bad --scaffold rejected"
"$ROOT/init.sh" x go "$TMP/bad3" --agent wrong --yes >/dev/null 2>&1 && ko "bad --agent rejected" "exited 0" || ok "bad --agent rejected"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
