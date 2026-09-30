#!/usr/bin/env bash
# validate-template.sh — structural checks on the template itself.
# Catches the mistakes that silently disable a skill, an agent, or a hook.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

PASS=0; FAIL=0
ok() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
ko() { printf '  \033[0;31m✗\033[0m %s — %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }

printf '\n\033[0;36mJSON\033[0m\n'
while IFS= read -r file; do
  if python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$file" 2>/dev/null; then
    ok "$file"
  else
    ko "$file" "invalid JSON"
  fi
done < <(find . -name '*.json' -not -path './.git/*' -not -path '*/node_modules/*' | sort)

printf '\n\033[0;36mSkills\033[0m\n'
for skill in .claude/skills/*/SKILL.md; do
  [ -e "$skill" ] || { ko "skills" "no SKILL.md found"; break; }
  dir="$(basename "$(dirname "$skill")")"
  name="$(awk -F': *' '/^name:/{print $2; exit}' "$skill" | tr -d '"'"'"'')"
  desc="$(awk -F': *' '/^description:/{print $2; exit}' "$skill")"
  if [ "$name" != "$dir" ]; then
    ko "$dir" "frontmatter name '$name' must match the directory name (opencode requirement)"
  elif ! printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    ko "$dir" "name must be lowercase alphanumeric with single hyphens"
  elif [ -z "$desc" ]; then
    ko "$dir" "missing description"
  elif [ "${#desc}" -gt 1024 ]; then
    ko "$dir" "description exceeds 1024 characters"
  else
    ok "$dir"
  fi
done

printf '\n\033[0;36mAgents\033[0m\n'
for agent in .claude/agents/*.md; do
  [ -e "$agent" ] || { ko "agents" "no agent found"; break; }
  base="$(basename "$agent" .md)"
  name="$(awk -F': *' '/^name:/{print $2; exit}' "$agent")"
  desc="$(awk -F': *' '/^description:/{print $2; exit}' "$agent")"
  turns="$(awk -F': *' '/^maxTurns:/{print $2; exit}' "$agent")"
  if [ "$name" != "$base" ]; then
    ko "$base" "frontmatter name '$name' must match the file name"
  elif [ -z "$desc" ]; then
    ko "$base" "missing description"
  elif ! printf '%s' "$turns" | grep -qE '^[0-9]+$'; then
    ko "$base" "missing a maxTurns budget — an agent with no ceiling can loop"
  else
    ok "$base (maxTurns $turns)"
  fi
done

printf '\n\033[0;36mHooks\033[0m\n'
for hook in .claude/hooks/*.sh; do
  [ -x "$hook" ] && ok "$(basename "$hook") is executable" || ko "$(basename "$hook")" "not executable"
done
for script in scripts/*.sh init.sh; do
  [ -x "$script" ] && ok "$script is executable" || ko "$script" "not executable"
done

# Every hook referenced by settings.json must exist on disk.
while IFS= read -r referenced; do
  path="${referenced/\$\{CLAUDE_PROJECT_DIR\}\//}"
  [ -f "$path" ] && ok "settings.json → $path exists" || ko "settings.json → $path" "missing"
done < <(grep -oE '\$\{CLAUDE_PROJECT_DIR\}/[^"]+' .claude/settings.json | sort -u)

printf '\n\033[0;36mGenerated artifacts\033[0m\n'
for generated in .opencode/agents/*.md .opencode/commands/*.md; do
  [ -e "$generated" ] || continue
  grep -q 'DO NOT EDIT' "$generated" \
    && ok "$(basename "$generated") carries the generated banner" \
    || ko "$generated" "missing DO NOT EDIT banner"
done

printf '\n\033[0;36mTest-gate policies\033[0m\n'
for policy in .claude/test-policy.json templates/common/.claude/test-policy.json; do
  if [ ! -f "$policy" ]; then
    ko "$policy" "missing"
  elif python3 -c "
import json, sys
required = {'version', 'sources', 'tests', 'exempt', 'test_markers'}
data = json.load(open(sys.argv[1]))
missing = required - set(data)
sys.exit(1 if missing else 0)
" "$policy" 2>/dev/null; then
    ok "$policy declares every required key"
  else
    ko "$policy" "a required key is missing (version, sources, tests, exempt, test_markers)"
  fi
done
count=$(grep -lc 'TEST_SOURCES=' scripts/scaffold/*.sh 2>/dev/null | wc -l | tr -d ' ')
[ "$count" = "14" ] && ok "all 14 stack modules declare a test boundary" \
  || ko "stack modules" "only $count of 14 declare TEST_SOURCES"

printf '\n\033[0;36mHygiene\033[0m\n'
found="$(find . -name '.DS_Store' -not -path './.git/*' | head -5)"
[ -z "$found" ] && ok "no .DS_Store committed" || ko "hygiene" ".DS_Store present: $found"

[ -f AGENTS.md ] && ok "AGENTS.md present" || ko "AGENTS.md" "missing"
grep -q '^@AGENTS.md' CLAUDE.md && ok "CLAUDE.md imports AGENTS.md" || ko "CLAUDE.md" "missing @AGENTS.md import"

# ── The Part A / Part B split (ADR-006) ──────────────────────────────────────
# AGENTS.md holds the kernel and this repository's own Part B; the blank Part B a
# generated project starts from lives in templates/common/. init.sh joins them, so
# the marker is load-bearing and neither half may drift into the other.
MARKER='# PART B — PROJECT CONFIGURATION'
PART_B_TPL='templates/common/AGENTS.part-b.md'

markers=$(grep -cFx "$MARKER" AGENTS.md || true)
[ "$markers" = "1" ] && ok "AGENTS.md carries the Part B marker exactly once" \
  || ko "Part B marker" "found $markers occurrences in AGENTS.md, expected 1"

[ -f "$PART_B_TPL" ] && ok "blank Part B template present" \
  || ko "$PART_B_TPL" "missing — init.sh cannot compose AGENTS.md"

if [ -f "$PART_B_TPL" ]; then
  [ "$(head -1 "$PART_B_TPL")" = "$MARKER" ] && ok "blank Part B starts at the marker" \
    || ko "blank Part B" "first line is not the marker"
  missing=""
  for section in B1 B2 B3 B4 B5 B6 B7 B8; do
    grep -qE "^## ${section} " "$PART_B_TPL" || missing="$missing $section"
  done
  [ -z "$missing" ] && ok "blank Part B carries B1 through B8" \
    || ko "blank Part B" "missing sections:$missing"
  [ "$(grep -cF '<PROJECT_NAME>' "$PART_B_TPL")" = "1" ] \
    && ok "blank Part B carries the project-name placeholder" \
    || ko "blank Part B" "expected exactly one <PROJECT_NAME>"
  grep -qF '### Code conventions' "$PART_B_TPL" \
    && ok "blank Part B carries the preset injection marker" \
    || ko "blank Part B" "'### Code conventions' missing — the B3 preset would be appended at EOF"
  grep -qF 'Auto-injected preset:' "$PART_B_TPL" \
    && ko "blank Part B" "contains init.sh's idempotence key — the preset would never be injected" \
    || ok "blank Part B free of the idempotence key"
fi

# The template's own Part B is filled in: an agent reads it as fact, so a surviving
# <angle-bracket> placeholder is a question it would have to answer on its own.
# A letter must follow '<' so that '->', '<=' and '<!--' are not flagged.
left=$(awk -v m="$MARKER" 'f && /<[A-Za-z][^>]*>/ { print } $0 == m { f = 1 }' AGENTS.md)
[ -z "$left" ] && ok "AGENTS.md Part B is filled in — no placeholder left" \
  || ko "Part B placeholders" "$(printf '%s' "$left" | head -3 | tr '\n' ' ')"
[ -d .claude/commands ] && ko "legacy" ".claude/commands/ still present — skills replaced it" || ok "no legacy .claude/commands/"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
