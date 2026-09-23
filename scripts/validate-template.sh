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
  if [ "$name" != "$base" ]; then
    ko "$base" "frontmatter name '$name' must match the file name"
  elif [ -z "$desc" ]; then
    ko "$base" "missing description"
  else
    ok "$base"
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

printf '\n\033[0;36mHygiene\033[0m\n'
found="$(find . -name '.DS_Store' -not -path './.git/*' | head -5)"
[ -z "$found" ] && ok "no .DS_Store committed" || ko "hygiene" ".DS_Store present: $found"

[ -f AGENTS.md ] && ok "AGENTS.md present" || ko "AGENTS.md" "missing"
grep -q '^@AGENTS.md' CLAUDE.md && ok "CLAUDE.md imports AGENTS.md" || ko "CLAUDE.md" "missing @AGENTS.md import"
[ -d .claude/commands ] && ko "legacy" ".claude/commands/ still present — skills replaced it" || ok "no legacy .claude/commands/"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
