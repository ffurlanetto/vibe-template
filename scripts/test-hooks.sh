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

# ── A Test-Exempt trailer that was never needed ──────────────────────────────
# The gate exits silently whenever no source changed, so a trailer added out of
# habit passed unremarked — two commits in the v3.2.0 branch carry one. It stays
# an advisory: exit 0, a line on stderr. A gate that blocked on a reflex would be
# the kind people route around, which is what ADR-002 exists to avoid.
NEEDED='the trailer was not required'

# docs/x.md is already in the fixture's baseline commit, so `git add` alone stages
# nothing and the gate returns before it classifies anything. Give it new content
# each time, or the docs-only cases assert the early return instead of the rule.
DOC_REV=0
stage_doc() {
  DOC_REV=$((DOC_REV + 1))
  printf '# doc revision %s\n' "$DOC_REV" > "$GATE/docs/x.md"
  git -C "$GATE" add docs/x.md
}

git -C "$GATE" reset -q
stage_doc
check "an unnecessary trailer never blocks" 0 \
  "$(gate 'git commit -m "docs: x

Test-Exempt: documentation only, no behaviour")')"
case "$(gate_out 'git commit -m "docs: x

Test-Exempt: documentation only, no behaviour")')" in
  *"$NEEDED"*) ok "says the trailer was not required";;
  *) ko "says the trailer was not required" "no advisory";;
esac
case "$(gate_out 'git commit -m "docs: x"')" in
  "") ok "stays silent when there is no trailer";;
  *) ko "stays silent when there is no trailer" "unexpected output";;
esac

# A reason under 15 characters is refused only when the trailer is load-bearing.
case "$(gate_out 'git commit -m "docs: x

Test-Exempt: wip")')" in
  *"$NEEDED"*) ok "an unnecessary short reason is advised, not refused";;
  *) ko "an unnecessary short reason" "no advisory";;
esac
check "an unnecessary short reason still exits 0" 0 \
  "$(gate 'git commit -m "docs: x

Test-Exempt: wip")')"

# Only a line-anchored trailer counts; the words in prose must not trip it.
case "$(gate_out 'git commit -m "docs: never write Test-Exempt: inline like this"')" in
  "") ok "ignores Test-Exempt written mid-line";;
  *) ko "ignores Test-Exempt written mid-line" "false positive";;
esac

# An indented trailer is still a trailer, and two of them are still one mistake.
case "$(gate_out "$(printf 'git commit -m "docs: x\n\n\tTest-Exempt: indented but real enough"')")" in
  *"$NEEDED"*) ok "sees an indented trailer";;
  *) ko "sees an indented trailer" "missed";;
esac
count=$(gate_out 'git commit -m "docs: x

Test-Exempt: first reason, long enough
Test-Exempt: second reason, long enough")' | grep -c "$NEEDED")
[ "$count" = "1" ] && ok "two trailers produce one advisory" \
  || ko "two trailers produce one advisory" "got $count"

# The message may arrive through -F or --message=; both are read, and a -F
# pointing nowhere is as unreadable as an editor session.
printf 'docs: x\n\nTest-Exempt: reason supplied through a file\n' > "$TMP/msg.txt"
case "$(gate_out "git commit -F $TMP/msg.txt")" in
  *"$NEEDED"*) ok "reads the trailer from -F";;
  *) ko "reads the trailer from -F" "missed";;
esac
case "$(gate_out 'git commit --message="docs: x

Test-Exempt: reason supplied inline"')" in
  *"$NEEDED"*) ok "reads the trailer from --message=";;
  *) ko "reads the trailer from --message=" "missed";;
esac
case "$(gate_out "git commit -F $TMP/does-not-exist.txt")" in
  ""|*"no such"*) ok "an unreadable -F says nothing about a trailer";;
  *) ko "an unreadable -F says nothing" "unexpected: $(gate_out "git commit -F $TMP/nope.txt")";;
esac
case "$(gate_out 'git commit')" in
  "") ok "editor mode says nothing about a trailer";;
  *) ko "editor mode says nothing" "the message cannot be read, so nothing may be claimed";;
esac

# A commit that genuinely needed the trailer must get the waiver, not the advice.
git -C "$GATE" reset -q
printf 'def h():\n    return 3\n' > "$GATE/src/h.py"
git -C "$GATE" add src/h.py
OUT="$(gate_out 'git commit -m "refactor: h

Test-Exempt: pure rename, behaviour unchanged")')"
case "$OUT" in
  *"$NEEDED"*) ko "a required trailer is not called unnecessary" "advised anyway";;
  *"waived"*) ok "a required trailer is waived, not advised";;
  *) ko "a required trailer is waived" "no waiver";;
esac

# Source and test both changed: the trailer was not required either (D13).
printf 'def test_h():\n    assert True\n' > "$GATE/tests/test_h.py"
git -C "$GATE" add tests/test_h.py
case "$(gate_out 'git commit -m "feat: h

Test-Exempt: added out of habit, not needed")')" in
  *"$NEEDED"*) ok "advises when the test was there all along";;
  *) ko "advises when the test was there all along" "silent";;
esac

# Both runtimes. Claude Code sends JSON on stdin and reads stdout; opencode passes
# argv and surfaces stderr. The stdout payload is asserted to be well-formed and
# to name the event — not that any runtime renders it.
git -C "$GATE" reset -q
stage_doc
PAYLOAD='{"tool_input":{"command":"git commit -m \"docs: x\n\nTest-Exempt: documentation only, no behaviour\""}}'
ERR="$( cd "$GATE" && { printf '%s' "$PAYLOAD" | "$HOOKS/require-tests.sh" >/dev/null; } 2>&1 )"
case "$ERR" in
  *"$NEEDED"*) ok "advises in stdin mode too";;
  *) ko "advises in stdin mode too" "no advisory";;
esac
STDOUT="$( cd "$GATE" && printf '%s' "$PAYLOAD" | "$HOOKS/require-tests.sh" 2>/dev/null )"
if printf '%s' "$STDOUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["hookSpecificOutput"]["hookEventName"]=="PreToolUse" else 1)' 2>/dev/null; then
  ok "stdin mode emits well-formed PreToolUse JSON"
else
  ko "stdin mode emits well-formed PreToolUse JSON" "got: $(printf '%s' "$STDOUT" | head -c 80)"
fi
OUT="$(gate_out 'git commit -m "docs: x

Test-Exempt: documentation only, no behaviour")')"
case "$OUT" in
  *hookSpecificOutput*) ko "argv mode keeps stdout clean" "JSON leaked into the argv path";;
  *) ok "argv mode keeps stdout clean";;
esac

# Nothing staged: git refuses the commit anyway, so the gate says nothing.
git -C "$GATE" reset -q
case "$(gate_out 'git commit -m "docs: x

Test-Exempt: nothing is staged at all")')" in
  "") ok "says nothing when nothing is staged";;
  *) ko "says nothing when nothing is staged" "spoke about a commit that cannot exist";;
esac

# A commit message is model output on its way to a terminal: never echo a secret.
stage_doc
case "$(gate_out 'git commit -m "docs: x

Test-Exempt: rotating ghp_AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH now")')" in
  *ghp_AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH*) ko "never echoes a credential from the message" "leaked";;
  *) ok "never echoes a credential from the message";;
esac

printf '\n\033[0;36mledger.sh\033[0m\n'

LEDGER="$TMP/ledger.jsonl"
ledger() { CLAUDE_LEDGER_FILE="$LEDGER" "$HOOKS/ledger.sh" "$@"; }

printf '{"hook_event_name":"SubagentStart","session_id":"s1","agent_type":"code-reviewer","agent_id":"a1"}' \
  | CLAUDE_LEDGER_FILE="$LEDGER" "$HOOKS/ledger.sh"
[ -s "$LEDGER" ] && ok "records a subagent start" || ko "records a subagent start" "nothing written"

printf '{"hook_event_name":"SubagentStop","session_id":"s1","agent_type":"code-reviewer","agent_id":"a1","last_assistant_message":"Reviewed. token = \\"ghp_abcdefghijklmnopqrstuvwxyz0123\\" was hardcoded."}' \
  | CLAUDE_LEDGER_FILE="$LEDGER" "$HOOKS/ledger.sh"

if grep -q "ghp_abcdefghijklmnopqrstuvwxyz0123" "$LEDGER"; then
  ko "masks a secret before persisting it" "the token reached the ledger"
else
  ok "masks a secret before persisting it"
fi

if python3 -c "
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
assert len(lines) == 2, lines
assert lines[0]['event'] == 'agent.start' and lines[1]['event'] == 'agent.stop'
assert all(set(l) >= {'ts','event','session_id','agent_type','agent_id','summary'} for l in lines)
" "$LEDGER" 2>/dev/null; then
  ok "every line is valid JSON with the agreed fields"
else
  ko "every line is valid JSON with the agreed fields" "schema mismatch"
fi

ledger agent.start test-engineer opencode-call-1 >/dev/null 2>&1
ledger agent.stop test-engineer opencode-call-1 "Added 4 tests" >/dev/null 2>&1
if python3 -c "
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
assert lines[-1]['agent_id'] == 'opencode-call-1' and lines[-1]['summary'] == 'Added 4 tests'
" "$LEDGER" 2>/dev/null; then
  ok "accepts the argv form the opencode plugin uses"
else
  ko "accepts the argv form the opencode plugin uses" "fields not recorded"
fi

LONG="$(head -c 600 /dev/zero | tr '\0' 'x')"
ledger agent.stop docs-writer a2 "$LONG" >/dev/null 2>&1
if python3 -c "
import json, sys
last = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip()][-1]
assert len(last['summary']) <= 240, len(last['summary'])
" "$LEDGER" 2>/dev/null; then
  ok "bounds the summary at 240 characters"
else
  ko "bounds the summary at 240 characters" "summary not truncated"
fi

printf 'not json' | CLAUDE_LEDGER_FILE="$LEDGER" "$HOOKS/ledger.sh"
check "never fails on a malformed payload" 0 "$?"

printf '{"hook_event_name":"PreToolUse","session_id":"s1"}' | CLAUDE_LEDGER_FILE="$LEDGER" "$HOOKS/ledger.sh"
if [ "$(wc -l < "$LEDGER")" = "5" ]; then
  ok "ignores events that are not subagent lifecycle"
else
  ko "ignores events that are not subagent lifecycle" "extra line written"
fi

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
