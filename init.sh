#!/usr/bin/env bash
# init.sh — bootstrap a project configured for Claude Code and opencode,
# with a skeleton that already runs and tests itself.
#
#   ./init.sh <project-name> <stack> [destination] [options]
#
# Options:
#   --scaffold full|structure|none   how much code to generate (default: full)
#   --agent both|claude|opencode     which agents to configure (default: both)
#   --variant react|vue|angular      frontend stack only (default: react)
#   --yes                            never prompt
#   --dry-run                        list the actions, write nothing
#
# Nothing existing is ever overwritten.
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
info()    { echo -e "${CYAN}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

STACKS=(java-spring java-spring-gradle java-quarkus dotnet-aspnet python-fastapi go nestjs rust rails react-native flutter monorepo frontend sre)
TIER_A=(python-fastapi go nestjs java-spring java-spring-gradle java-quarkus frontend)

usage() {
  cat <<USAGE

Usage: $0 <project-name> <stack> [destination] [options]

Stacks (★ = ships a walking skeleton that runs and tests itself):
USAGE
  local stack marker
  for stack in "${STACKS[@]}"; do
    marker="  "
    for tier_a in "${TIER_A[@]}"; do [[ "$stack" == "$tier_a" ]] && marker=" ★"; done
    printf '  %s %s\n' "$marker" "$stack"
  done
  cat <<USAGE

Options:
  --scaffold full|structure|none   how much code to generate (default: full)
  --agent both|claude|opencode     which agents to configure (default: both)
  --variant react|vue|angular      frontend stack only (default: react)
  --yes                            never prompt
  --dry-run                        list the actions, write nothing

Examples:
  $0 payment-api python-fastapi
  $0 payment-api go ~/projects/payment-api --yes
  $0 platform monorepo --scaffold structure --agent opencode

USAGE
  exit 1
}

# ── Arguments ────────────────────────────────────────────────────────────────
[[ $# -lt 2 ]] && usage

PROJECT_NAME="$1"; shift
STACK="$1"; shift

DEST=""
SCAFFOLD_MODE="full"
AGENT_MODE="both"
ASSUME_YES=false
DRY_RUN=false
export FRONTEND_VARIANT="${FRONTEND_VARIANT:-react}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scaffold) SCAFFOLD_MODE="${2:?--scaffold needs a value}"; shift 2 ;;
    --agent)    AGENT_MODE="${2:?--agent needs a value}"; shift 2 ;;
    --variant)  FRONTEND_VARIANT="${2:?--variant needs a value}"; shift 2 ;;
    --yes|-y)   ASSUME_YES=true; shift ;;
    --dry-run)  DRY_RUN=true; shift ;;
    -h|--help)  usage ;;
    -*)         error "Unknown option '$1'" ;;
    *)          if [[ -z "$DEST" ]]; then DEST="$1"; else error "Unexpected argument '$1'"; fi; shift ;;
  esac
done

DEST="${DEST:-$(pwd)/$PROJECT_NAME}"

valid_stack=false
for stack in "${STACKS[@]}"; do [[ "$STACK" == "$stack" ]] && valid_stack=true; done
$valid_stack || error "Unknown stack '$STACK'. Run '$0 --help' for the list."

case "$SCAFFOLD_MODE" in full|structure|none) ;; *) error "--scaffold must be full, structure or none" ;; esac
case "$AGENT_MODE"    in both|claude|opencode) ;; *) error "--agent must be both, claude or opencode" ;; esac

PRESET_FILE="$TEMPLATE_DIR/.claude/presets/${STACK}.md"
[[ -f "$PRESET_FILE" ]] || error "Preset not found: $PRESET_FILE"

# ── Destination ──────────────────────────────────────────────────────────────
if [[ -d "$DEST" && -n "$(ls -A "$DEST" 2>/dev/null)" ]] && ! $ASSUME_YES && ! $DRY_RUN; then
  warn "'$DEST' already exists and is not empty."
  warn "Existing files are never overwritten; missing ones are added."
  read -r -p "Continue? [y/N] " -n 1 reply; echo
  [[ "$reply" =~ ^[Yy]$ ]] || error "Cancelled."
fi

copy() {                      # copy <relative-source> [relative-destination]
  local src="$TEMPLATE_DIR/$1" dst="$DEST/${2:-$1}"
  [[ -e "$src" ]] || return 0
  if [[ -e "$dst" ]]; then echo -e "${DIM}  · kept existing ${2:-$1}${NC}"; return 0; fi
  $DRY_RUN && { echo -e "${DIM}  · would add ${2:-$1}${NC}"; return 0; }
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
}

echo ""
echo -e "${BOLD}Bootstrapping '${PROJECT_NAME}'${NC}"
echo -e "  stack     : ${STACK}"
echo -e "  agents    : ${AGENT_MODE}"
echo -e "  scaffold  : ${SCAFFOLD_MODE}"
echo -e "  target    : ${DEST}"
$DRY_RUN && echo -e "  ${YELLOW}dry run — nothing will be written${NC}"
echo ""

$DRY_RUN || mkdir -p "$DEST"

# ── Agent configuration ──────────────────────────────────────────────────────
info "Agent configuration"
copy "AGENTS.md"
copy ".claude/skills"
copy ".claude/agents"
copy ".claude/hooks"
copy ".claude/presets/${STACK}.md" ".claude/presets/${STACK}.md"
copy "scripts/test-hooks.sh"
copy "docs/DUAL-AGENT.md"
copy ".mcp.json.example"

if [[ "$AGENT_MODE" == "both" || "$AGENT_MODE" == "claude" ]]; then
  copy "CLAUDE.md"
  copy ".claude/settings.json"
fi

if [[ "$AGENT_MODE" == "both" || "$AGENT_MODE" == "opencode" ]]; then
  copy "opencode.json"
  copy ".opencode/agents"
  copy ".opencode/commands"
  copy ".opencode/plugins"
  copy "scripts/sync-opencode.py"
fi

if [[ "$AGENT_MODE" == "opencode" ]]; then
  # opencode reads AGENTS.md directly; the Claude import wrapper would be noise.
  $DRY_RUN || rm -f "$DEST/CLAUDE.md"
fi

copy ".github/workflows/quality-gate.yml"
copy ".github/PULL_REQUEST_TEMPLATE.md"
copy "templates/common/.gitignore" ".gitignore"

# ── Project identity ─────────────────────────────────────────────────────────
info "Project identity"
if ! $DRY_RUN; then
  while IFS= read -r file; do
    sed -i.bak "s|<PROJECT_NAME>|${PROJECT_NAME}|g" "$file" && rm -f "${file}.bak"
  done < <(find "$DEST" -maxdepth 2 -name 'AGENTS.md' -o -maxdepth 2 -name 'CLAUDE.md' 2>/dev/null)
fi

# ── Preset injection into section B3 ─────────────────────────────────────────
info "Injecting the ${STACK} preset into B3"
if ! $DRY_RUN; then
  python3 - "$DEST/AGENTS.md" "$PRESET_FILE" "$STACK" <<'PY'
import sys, pathlib
agents, preset, stack = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
text = agents.read_text(encoding="utf-8")
if f"Auto-injected preset: {stack}" in text:
    sys.exit(0)
body = preset.read_text(encoding="utf-8")
# Drop the preset's own title and copy-paste instruction: it lands in B3 itself.
lines = [line for line in body.splitlines() if not line.startswith("# Preset B3")]
while lines and (lines[0].startswith(">") or not lines[0].strip() or lines[0].strip() == "---"):
    lines.pop(0)
block = f"\n<!-- Auto-injected preset: {stack} -->\n\n" + "\n".join(lines).rstrip() + "\n"
marker = "### Code conventions"
index = text.find(marker)
if index == -1:
    agents.write_text(text.rstrip() + "\n" + block, encoding="utf-8")
else:
    agents.write_text(text[:index] + block.lstrip("\n") + "\n" + text[index + len(marker):].lstrip("\n"), encoding="utf-8")
PY
fi

# ── Skeleton ─────────────────────────────────────────────────────────────────
DRY_FLAG=""
$DRY_RUN && DRY_FLAG="--dry-run"
"$TEMPLATE_DIR/scripts/scaffold.sh" "$DEST" "$PROJECT_NAME" "$STACK" "$SCAFFOLD_MODE" $DRY_FLAG

# ── Repository ───────────────────────────────────────────────────────────────
if ! $DRY_RUN; then
  if ! git -C "$DEST" rev-parse --git-dir >/dev/null 2>&1; then
    info "Initialising the git repository"
    git -C "$DEST" init -q
  fi
  cat "$TEMPLATE_DIR/VERSION" 2>/dev/null > "$DEST/.claude/.template-version" || echo unknown > "$DEST/.claude/.template-version"
  chmod +x "$DEST"/.claude/hooks/*.sh 2>/dev/null || true
  chmod +x "$DEST"/scripts/*.sh 2>/dev/null || true
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
success "Ready — ${DEST}"
echo ""
echo -e "${BOLD}Next steps${NC}"
echo "  1. cd $DEST"
echo "  2. make install && make check          # the gate should already be green"
echo "  3. Complete sections B1–B8 in AGENTS.md (replace every <angle bracket>)"
echo "  4. Open an agent session and run /prime"
echo ""
if [[ "$AGENT_MODE" == "both" ]]; then
  echo -e "  ${DIM}Claude Code reads CLAUDE.md (which imports AGENTS.md); opencode reads"
  echo -e "  AGENTS.md directly. Both share .claude/skills/. See docs/DUAL-AGENT.md.${NC}"
fi
echo ""
