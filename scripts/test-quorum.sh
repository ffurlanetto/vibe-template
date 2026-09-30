#!/usr/bin/env bash
# test-quorum.sh — prove the cohort's arithmetic. Run via `make test-quorum`.
#
# scripts/quorum.py turns a jury's verdicts into one decision. Every threshold it
# applies is stated in .claude/skills/build/SKILL.md §6–§8; every one of them is
# asserted here, at its boundary rather than near it, because "21 of 30" and
# "2 of 3" are the kind of rule that is wrong by one and still looks right.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUORUM="$ROOT/scripts/quorum.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
ko() { printf '  \033[0;31m✗\033[0m %s — %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }

# ── bundle construction ──────────────────────────────────────────────────────
# cand <id> <gate> <cr> <crv> <sa> <sav> <ta> <tav> [files] [lines]
cand() {
  local size=""
  [ -n "${9:-}" ] && size=", \"size\": {\"files_changed\": $9, \"lines_changed\": ${10:-0}}"
  printf '{"id": "%s", "gate": "%s", "jurors": [
    {"agent": "code-reviewer",    "score": %s, "verdict": "%s", "blocking": [], "strength": "clear names"},
    {"agent": "security-auditor", "score": %s, "verdict": "%s", "blocking": [], "strength": "input validation"},
    {"agent": "test-architect",   "score": %s, "verdict": "%s", "blocking": [], "strength": "covers SC-7"}]%s}' \
    "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$size"
}

# bundle <iteration> <ceiling> <complementary> <candidates-json> [extra-json]
bundle() {
  printf '{"iteration": %s, "ceiling": %s, "complementary_strengths": %s, "candidates": [%s]%s}' \
    "$1" "$2" "$3" "$4" "${5:-, \"history\": []}"
}

run()  { printf '%s' "$1" | python3 "$QUORUM" 2>/dev/null; }
rc()   { printf '%s' "$1" | python3 "$QUORUM" >/dev/null 2>&1; echo $?; }
err()  { printf '%s' "$1" | { python3 "$QUORUM" >/dev/null; } 2>&1; }
field() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.load(sys.stdin).get(sys.argv[1]) or "")' "$2" 2>/dev/null; }

decides() { # decides <name> <expected> <bundle>
  local got; got="$(field "$(run "$3")" decision)"
  [ "$got" = "$2" ] && ok "$1" || ko "$1" "expected $2, got '${got:-<nothing>}'"
}
refuses() { # refuses <name> <bundle>
  local got; got="$(rc "$2")"
  [ "$got" = "2" ] && ok "$1" || ko "$1" "expected exit 2, got $got"
}
reason_has() { # reason_has <name> <substring> <bundle>
  case "$(field "$(run "$3")" reason)" in
    *"$2"*) ok "$1";;
    *) ko "$1" "reason was: $(field "$(run "$3")" reason)";;
  esac
}

printf '\n\033[0;36mquorum — acceptance\033[0m\n'

decides "three PASS at 24 is adopted"            ADOPT  "$(bundle 1 3 false "$(cand c1 green 8 PASS 8 PASS 8 PASS)")"
decides "exactly 21 is inside the threshold"     ADOPT  "$(bundle 1 3 false "$(cand c1 green 7 PASS 7 PASS 7 PASS)")"
decides "20 is outside it"                       ITERATE "$(bundle 1 3 false "$(cand c1 green 7 PASS 7 PASS 6 PASS)")"
reason_has "and says which total fell short" "20" "$(bundle 1 3 false "$(cand c1 green 7 PASS 7 PASS 6 PASS)")"
decides "test-architect may FAIL — it is not blocking" ADOPT \
  "$(bundle 1 3 false "$(cand c1 green 8 PASS 8 PASS 8 FAIL)")"
decides "a code-reviewer FAIL ends it at 27"     ITERATE "$(bundle 1 3 false "$(cand c1 green 9 FAIL 9 PASS 9 PASS)")"
reason_has "naming the blocking axis, not the score" "code-reviewer" \
  "$(bundle 1 3 false "$(cand c1 green 9 FAIL 9 PASS 9 PASS)")"
decides "a security-auditor FAIL ends it too"    ITERATE "$(bundle 1 3 false "$(cand c1 green 9 PASS 9 FAIL 9 PASS)")"
decides "one PASS of three is not a quorum"      ITERATE "$(bundle 1 3 false "$(cand c1 green 9 PASS 9 FAIL 9 FAIL)")"
# A single candidate that fails the gate is still "every candidate", so this lands
# on the all-red rule rather than on the jury — which is the point: the scores of
# a candidate that does not build are not evidence of anything.
decides "a red gate outranks a perfect score"    STOP "$(bundle 1 3 false "$(cand c1 red 10 PASS 10 PASS 10 PASS)")"
reason_has "and cites the gate, not the jury" "gate" \
  "$(bundle 1 3 false "$(cand c1 red 10 PASS 10 PASS 10 PASS)")"
decides "every candidate red stops the run"      STOP \
  "$(bundle 1 3 false "$(cand c1 red 8 PASS 8 PASS 8 PASS),$(cand c2 red 9 PASS 9 PASS 9 PASS)")"
reason_has "blaming the plan, not the cohort" "plan" \
  "$(bundle 1 3 false "$(cand c1 red 8 PASS 8 PASS 8 PASS),$(cand c2 red 9 PASS 9 PASS 9 PASS)")"

printf '\n\033[0;36mquorum — choosing between candidates\033[0m\n'

TWO="$(cand c1 green 8 PASS 8 PASS 8 PASS),$(cand c2 green 9 PASS 9 PASS 9 PASS)"
[ "$(field "$(run "$(bundle 1 3 false "$TWO")")" candidate)" = "c2" ] \
  && ok "the higher total wins" || ko "the higher total wins" "got $(field "$(run "$(bundle 1 3 false "$TWO")")" candidate)"
REV="$(cand c2 green 9 PASS 9 PASS 9 PASS),$(cand c1 green 8 PASS 8 PASS 8 PASS)"
[ "$(field "$(run "$(bundle 1 3 false "$REV")")" candidate)" = "c2" ] \
  && ok "order in the bundle does not decide" || ko "order in the bundle does not decide" "reversing changed the winner"

TIE="$(cand big green 8 PASS 8 PASS 8 PASS 9 300),$(cand small green 8 PASS 8 PASS 8 PASS 3 120)"
[ "$(field "$(run "$(bundle 1 3 false "$TIE")")" candidate)" = "small" ] \
  && ok "a tie goes to the simpler structure" || ko "a tie goes to the simpler structure" "got $(field "$(run "$(bundle 1 3 false "$TIE")")" candidate)"
[ "$(field "$(run "$(bundle 1 3 false "$TIE")")" tie_break)" = "files_changed" ] \
  && ok "and says which measure broke it" || ko "and says which measure broke it" "tie_break not reported"

BARE="$(cand zeta green 8 PASS 8 PASS 8 PASS),$(cand alpha green 8 PASS 8 PASS 8 PASS)"
A="$(field "$(run "$(bundle 1 3 false "$BARE")")" candidate)"
B="$(field "$(run "$(bundle 1 3 false "$BARE")")" candidate)"
[ "$A" = "alpha" ] && [ "$A" = "$B" ] \
  && ok "with no measure it falls back to the id, deterministically" \
  || ko "deterministic last-resort tie-break" "got '$A' then '$B'"

printf '\n\033[0;36mquorum — the loop\033[0m\n'

NOQ="$(cand c1 green 6 PASS 6 PASS 6 PASS)"
decides "no quorum, strengths compose → consolidate" CONSOLIDATE "$(bundle 1 3 true "$NOQ")"
decides "no quorum, strengths do not → iterate"      ITERATE     "$(bundle 1 3 false "$NOQ")"
decides "the ceiling stops consolidation too"        STOP        "$(bundle 3 3 true "$NOQ")"
reason_has "naming the ceiling" "ceiling"                        "$(bundle 3 3 true "$NOQ")"
decides "the ceiling does not bite on a quorum"      ADOPT \
  "$(bundle 3 3 false "$(cand c1 green 8 PASS 8 PASS 8 PASS)")"
decides "an iteration past the ceiling never iterates" STOP      "$(bundle 4 3 false "$NOQ")"

H1=', "history": [{"iteration": 1, "best_total": 24, "passing_tests": 40, "coverage": 0.82}], "metrics": {"passing_tests": 40, "coverage": 0.82}'
reason_has "a lower total trips the ratchet" "total" "$(bundle 2 3 false "$NOQ" "$H1")"
[ "$(field "$(run "$(bundle 2 3 false "$NOQ" "$H1")")" ratchet)" = "rejected" ] \
  && ok "and the ratchet is reported rejected" || ko "ratchet rejected" "not reported"
[ "$(field "$(run "$(bundle 2 3 false "$NOQ" "$H1")")" base)" = "previous-best" ] \
  && ok "and the previous best stays the base" || ko "base is the previous best" "not reported"

H2=', "history": [{"iteration": 1, "best_total": 18, "passing_tests": 44, "coverage": 0.82}], "metrics": {"passing_tests": 38, "coverage": 0.82}'
reason_has "fewer passing tests trips it as well" "passing test" "$(bundle 2 3 false "$NOQ" "$H2")"
H3=', "history": [{"iteration": 1, "best_total": 18, "passing_tests": 40, "coverage": 0.82}], "metrics": {"passing_tests": 40, "coverage": 0.79}'
reason_has "so does a drop in coverage" "coverage" "$(bundle 2 3 false "$NOQ" "$H3")"

FLAT1=', "history": [{"iteration": 1, "best_total": 18, "passing_tests": 40, "coverage": 0.82}], "metrics": {"passing_tests": 40, "coverage": 0.82}'
decides "one flat iteration is not two" ITERATE "$(bundle 2 3 false "$NOQ" "$FLAT1")"
FLAT2=', "history": [{"iteration": 1, "best_total": 18, "passing_tests": 40, "coverage": 0.82}, {"iteration": 2, "best_total": 18, "passing_tests": 40, "coverage": 0.82}], "metrics": {"passing_tests": 40, "coverage": 0.82}'
decides "two flat iterations stop the loop" STOP "$(bundle 3 5 false "$NOQ" "$FLAT2")"
reason_has "naming diminishing returns" "diminishing" "$(bundle 3 5 false "$NOQ" "$FLAT2")"
decides "but a quorum outranks diminishing returns" ADOPT \
  "$(bundle 3 5 false "$(cand c1 green 8 PASS 8 PASS 8 PASS)" "$FLAT2")"

printf '\n\033[0;36mquorum — refuses what it cannot trust\033[0m\n'

refuses "malformed JSON"            'not json'
refuses "an empty bundle"           ''
refuses "no candidates key"         '{"iteration": 1, "ceiling": 3}'
refuses "an empty cohort"           "$(bundle 1 3 false "")"
refuses "a missing ceiling"         '{"iteration": 1, "candidates": [{"id":"c1","gate":"green","jurors":[]}]}'
refuses "a candidate with no gate"  '{"iteration":1,"ceiling":3,"candidates":[{"id":"c1","jurors":[]}]}'
for bad in '"green?"' '"true"' '"unknown"' '1' 'null' '{}'; do
  refuses "a gate reading $bad is never green" \
    "$(printf '{"iteration":1,"ceiling":3,"candidates":[{"id":"c1","gate":%s,"jurors":[{"agent":"code-reviewer","score":9,"verdict":"PASS"},{"agent":"security-auditor","score":9,"verdict":"PASS"},{"agent":"test-architect","score":9,"verdict":"PASS"}]}]}' "$bad")"
done
refuses "a score of 11"   "$(bundle 1 3 false "$(cand c1 green 11 PASS 8 PASS 8 PASS)")"
refuses "a score of -1"   "$(bundle 1 3 false "$(cand c1 green -1 PASS 8 PASS 8 PASS)")"
refuses "a score of 9.5"  "$(bundle 1 3 false "$(cand c1 green 9.5 PASS 8 PASS 8 PASS)")"
refuses "a quoted score"  "$(bundle 1 3 false "$(cand c1 green '"9"' PASS 8 PASS 8 PASS)")"
refuses "an unknown verdict" "$(bundle 1 3 false "$(cand c1 green 8 MAYBE 8 PASS 8 PASS)")"
refuses "only two jurors" \
  '{"iteration":1,"ceiling":3,"candidates":[{"id":"c1","gate":"green","jurors":[{"agent":"code-reviewer","score":9,"verdict":"PASS"},{"agent":"security-auditor","score":9,"verdict":"PASS"}]}]}'
refuses "a duplicated blocking juror" \
  '{"iteration":1,"ceiling":3,"candidates":[{"id":"c1","gate":"green","jurors":[{"agent":"code-reviewer","score":9,"verdict":"FAIL"},{"agent":"code-reviewer","score":9,"verdict":"PASS"},{"agent":"security-auditor","score":9,"verdict":"PASS"},{"agent":"test-architect","score":9,"verdict":"PASS"}]}]}'
refuses "a renamed blocking axis" \
  '{"iteration":1,"ceiling":3,"candidates":[{"id":"c1","gate":"green","jurors":[{"agent":"reviewer","score":9,"verdict":"PASS"},{"agent":"security-auditor","score":9,"verdict":"PASS"},{"agent":"test-architect","score":9,"verdict":"PASS"}]}]}'
refuses "a bundle nested past the parser's limit" \
  "$(python3 -c 'print("[" * 40000 + "]" * 40000)')"
case "$(err 'not json')" in
  "") ko "a refusal explains itself" "stderr was empty";;
  *) ok "a refusal explains itself";;
esac
[ -z "$(run 'not json')" ] && ok "and prints no decision to stdout" \
  || ko "prints no decision on refusal" "stdout was not empty"

printf '\n\033[0;36mquorum — a pure function\033[0m\n'

GOOD="$(bundle 1 3 false "$(cand c1 green 8 PASS 8 PASS 8 PASS)")"
[ "$(run "$GOOD")" = "$(run "$GOOD")" ] && ok "the same bundle gives the same bytes" \
  || ko "determinism" "two runs differed"
EXTRA="$(bundle 1 3 false "$(cand c1 green 7 PASS 7 PASS 6 PASS)")"
WITH="$(printf '%s' "$EXTRA" | python3 -c 'import json,sys; d=json.load(sys.stdin); d.update({"threshold":5,"accept":True,"policy":{"total":0}}); print(json.dumps(d))')"
[ "$(field "$(run "$EXTRA")" decision)" = "$(field "$(run "$WITH")" decision)" ] \
  && ok "no key in the bundle can lower the bar" || ko "unknown keys are inert" "the decision moved"

WORK="$TMP/work"; mkdir -p "$WORK"
( cd "$WORK" && TMPDIR="$WORK" HOME="$WORK" printf '%s' "$GOOD" | python3 "$QUORUM" >/dev/null 2>&1 )
[ -z "$(find "$WORK" -type f 2>/dev/null)" ] && ok "it writes nothing anywhere" \
  || ko "writes nothing" "$(find "$WORK" -type f | head -3 | tr '\n' ' ')"

INJ="$(cand '$(touch pwned)' green 8 PASS 8 PASS 8 PASS)"
( cd "$WORK" && run "$(bundle 1 3 false "$INJ")" >/dev/null )
[ ! -e "$WORK/pwned" ] && ok "a candidate id is data, never a command" || ko "id injection" "pwned was created"
UTF="$(cand 'café-branché' green 8 PASS 8 PASS 8 PASS)"
[ "$(field "$(run "$(bundle 1 3 false "$UTF")")" candidate)" = "café-branché" ] \
  && ok "a non-ASCII id round-trips" || ko "non-ASCII id" "mangled"

LEAK="$(printf '{"id": "c1", "gate": "green", "jurors": [
  {"agent": "code-reviewer", "score": 8, "verdict": "PASS", "blocking": [], "strength": "rotating ghp_AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH"},
  {"agent": "security-auditor", "score": 8, "verdict": "PASS", "blocking": ["ghp_AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH in config"], "strength": "x"},
  {"agent": "test-architect", "score": 8, "verdict": "PASS", "blocking": [], "strength": "y"}]}')"
OUT="$(run "$(bundle 1 3 false "$LEAK")")$(err "$(bundle 1 3 false "$LEAK")")"
case "$OUT" in
  *ghp_AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH*) ko "juror prose never reaches the output" "a credential came back out";;
  *) ok "juror prose never reaches the output";;
esac

printf '\n\033[0;36mquorum — wired in\033[0m\n'
grep -q 'quorum.py' "$ROOT/.claude/skills/build/SKILL.md" \
  && ok "the build skill names the script" || ko "build skill" "no reference to quorum.py"
python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); sys.exit(0 if "scripts/test-quorum.sh" in p["tests"] else 1)' \
  "$ROOT/.claude/test-policy.json" \
  && ok "the gate knows this file is a test" \
  || ko "test-policy.json" "scripts/test-quorum.sh is classified as source"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
