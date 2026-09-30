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

printf '\n\033[0;36mrequire-tests.sh\033[0m\n'

GATE="$TMP/gate"; mkdir -p "$GATE/src" "$GATE/tests" "$GATE/docs" "$GATE/.claude"
git -C "$GATE" init -q
git -C "$GATE" config user.email gate@test.local
git -C "$GATE" config user.name "gate test"
cp "$ROOT/templates/common/.claude/test-policy.json" "$GATE/.claude/test-policy.json"
printf 'def f():\n    return 1\n' > "$GATE/src/a.py"

gate() { ( cd "$GATE" && "$HOOKS/require-tests.sh" "$1" >/dev/null 2>&1 ); echo $?; }
# stderr carries the verdict; stdout is the machine-readable JSON we do not want here.
gate_out() { ( cd "$GATE" && { "$HOOKS/require-tests.sh" "$1" >/dev/null; } 2>&1 ); }

git -C "$GATE" add src/a.py
check "blocks source with no test" 2 "$(gate 'git commit -m "feat: a"')"
case "$(gate_out 'git commit -m "feat: a"')" in
  *"src/a.py"*) ok "names the offending source files";;
  *) ko "names the offending source files" "file not listed";;
esac

printf 'def test_f():\n    assert True\n' > "$GATE/tests/test_a.py"
git -C "$GATE" add tests/test_a.py
check "lets source plus test through" 0 "$(gate 'git commit -m "feat: a"')"

git -C "$GATE" reset -q
printf '# doc\n' > "$GATE/docs/x.md"
git -C "$GATE" add docs/x.md
check "ignores a documentation-only commit" 0 "$(gate 'git commit -m "docs: x"')"

git -C "$GATE" reset -q
git -C "$GATE" add src/a.py
check "accepts a Test-Exempt trailer with a reason" 0 \
  "$(gate 'git commit -m "refactor: rename

Test-Exempt: pure rename, behaviour unchanged")')"
case "$(gate_out 'git commit -m "x

Test-Exempt: pure rename, behaviour unchanged")')" in
  *"waived"*) ok "prints the waiver so it is not silent";;
  *) ko "prints the waiver so it is not silent" "no notice";;
esac
check "rejects a Test-Exempt reason under 15 chars" 2 "$(gate 'git commit -m "x

Test-Exempt: wip")')"
check "refuses a commit with no -m to inspect" 2 "$(gate 'git commit')"
check "ignores commands that are not commits" 0 "$(gate 'git status')"

# `git commit -a` stages tracked changes at commit time: the staged diff alone
# would miss them, so the gate must look at git diff HEAD instead.
git -C "$GATE" reset -q
git -C "$GATE" add -A
git -C "$GATE" commit -qm "chore: fixture baseline

Test-Exempt: baseline commit for the gate fixture"
printf 'def f():\n    return 2\n' > "$GATE/src/a.py"
check "sees changes staged by -a" 2 "$(gate 'git commit -am "feat: b"')"
check "passes when nothing is staged at all" 0 "$(gate 'git commit -m "feat: b"')"

( cd "$GATE" && printf '{"tool_input":{"command":"git commit -am \\"feat: b\\""}}' \
  | "$HOOKS/require-tests.sh" >/dev/null 2>&1 ); check "blocks in stdin mode too" 2 "$?"

mv "$GATE/.claude/test-policy.json" "$GATE/policy.bak"
check "falls back to built-in defaults with no policy" 2 "$(gate 'git commit -am "feat: b"')"
printf 'not json\n' > "$GATE/.claude/test-policy.json"
case "$(gate_out 'git commit -am "feat: b"')" in
  *"unreadable"*) ok "warns on an unreadable policy instead of failing closed";;
  *) ko "warns on an unreadable policy" "no warning";;
esac
mv "$GATE/policy.bak" "$GATE/.claude/test-policy.json"

# Rust and friends keep unit tests inside the source file, where no path glob
# can see them.
git -C "$GATE" reset -q
printf 'pub fn f() -> i32 { 1 }\n\n#[cfg(test)]\nmod tests {\n    #[test]\n    fn works() {}\n}\n' > "$GATE/src/lib.rs"
git -C "$GATE" add src/lib.rs
check "accepts an inline #[cfg(test)] module" 0 "$(gate 'git commit -m "feat: f"')"

git -C "$GATE" reset -q
printf 'pub fn g() -> i32 { 2 }\n' > "$GATE/src/plain.rs"
git -C "$GATE" add src/plain.rs
check "still blocks source with no inline test" 2 "$(gate 'git commit -m "feat: g"')"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
