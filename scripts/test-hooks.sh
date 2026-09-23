#!/usr/bin/env bash
# test-hooks.sh — prove the guardrails actually fire. Run via `make test-hooks`.
#
# Every case is asserted in BOTH invocation modes, because the same scripts are
# driven by Claude Code (JSON on stdin) and by the opencode plugin (argv).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="$ROOT/.claude/hooks"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
ko()   { printf '  \033[0;31m✗\033[0m %s — %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
check() { # check <name> <expected-exit> <actual-exit>
  [ "$2" = "$3" ] && ok "$1" || ko "$1" "expected exit $2, got $3"
}

printf '\n\033[0;36mscan-secrets.sh\033[0m\n'

cat > "$TMP/leaky.py" <<'EOF'
API_KEY = "sk-abcdefghijklmnopqrstuvwx"
EOF
cat > "$TMP/clean.py" <<'EOF'
import os
api_key = os.environ["API_KEY"]
placeholder = "CHANGEME"
EOF

OUT="$("$HOOKS/scan-secrets.sh" "$TMP/leaky.py" 2>&1)"; RC=$?
check "warns on a hardcoded secret (argv mode)" 0 "$RC"
case "$OUT" in *"Potential hardcoded secret"*) ok "warning message emitted";; *) ko "warning message emitted" "not found";; esac
case "$OUT" in *"sk-abcdefghijklmnopqrstuvwx"*) ko "secret value masked" "raw value leaked into the report";; *) ok "secret value masked";; esac

OUT="$(printf '{"tool_input":{"file_path":"%s"},"hook_event_name":"PostToolUse"}' "$TMP/leaky.py" | "$HOOKS/scan-secrets.sh" 2>/dev/null)"
case "$OUT" in *'"hookEventName":"PostToolUse"'*) ok "emits Claude Code JSON (stdin mode)";; *) ko "emits Claude Code JSON (stdin mode)" "no hookSpecificOutput";; esac

OUT="$("$HOOKS/scan-secrets.sh" "$TMP/clean.py" 2>&1)"; RC=$?
check "stays silent on env-var usage" 0 "$RC"
[ -z "$OUT" ] && ok "no false positive on placeholders" || ko "no false positive on placeholders" "$OUT"

printf '\n\033[0;36mblock-commit-secrets.sh\033[0m\n'

REPO="$TMP/repo"; mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email hooks@test.local
git -C "$REPO" config user.name "hook test"

printf 'token = "ghp_abcdefghijklmnopqrstuvwxyz0123"\n' > "$REPO/conf.py"
git -C "$REPO" add conf.py
( cd "$REPO" && "$HOOKS/block-commit-secrets.sh" "git commit -m test" >/dev/null 2>&1 ); RC=$?
check "blocks a commit carrying a secret (argv mode)" 2 "$RC"

( cd "$REPO" && printf '{"tool_input":{"command":"git commit -m x"}}' | "$HOOKS/block-commit-secrets.sh" >/dev/null 2>&1 ); RC=$?
check "blocks a commit carrying a secret (stdin mode)" 2 "$RC"

( cd "$REPO" && "$HOOKS/block-commit-secrets.sh" "git status" >/dev/null 2>&1 ); RC=$?
check "ignores commands that are not commits" 0 "$RC"

git -C "$REPO" reset -q
printf 'token = os.environ["GH_TOKEN"]\n' > "$REPO/conf.py"
git -C "$REPO" add conf.py
( cd "$REPO" && "$HOOKS/block-commit-secrets.sh" "git commit -m test" >/dev/null 2>&1 ); RC=$?
check "lets a clean commit through" 0 "$RC"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
