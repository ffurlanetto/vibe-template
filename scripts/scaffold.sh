#!/usr/bin/env bash
# scaffold.sh — build a project skeleton on top of the agent configuration.
#
#   scaffold.sh <dest> <project-name> <stack> <mode> [--dry-run]
#     mode: full      layer 1 (official generator) + 2 (architecture) + 3 (walking skeleton)
#           structure layers 1 and 2 only
#           none      nothing
#
# Three layers, three owners (docs/SCAFFOLD.md):
#   1. framework boilerplate → the stack's own official generator
#   2. architecture          → the directory layout declared by the preset (B5)
#   3. walking skeleton      → health endpoints + one vertical slice + its tests
#
# Nothing is ever overwritten: an existing file always wins.
set -uo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; DIM='\033[2m'; NC='\033[0m'
info()    { echo -e "${CYAN}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
fail()    { echo -e "${RED}✗${NC} $*" >&2; exit 1; }
skip()    { echo -e "${DIM}  ·${NC} $*"; }

DEST="${1:?destination required}"
PROJECT="${2:?project name required}"
STACK="${3:?stack required}"
MODE="${4:-full}"
DRY_RUN=false
[[ "${5:-}" == "--dry-run" ]] && DRY_RUN=true

MODULE="$TEMPLATE_DIR/scripts/scaffold/${STACK}.sh"
[[ -f "$MODULE" ]] || fail "No scaffold module for stack '$STACK' ($MODULE)"

# Identifier-safe variants of the project name, for package and module names.
PROJECT_SNAKE="$(printf '%s' "$PROJECT" | tr '[:upper:]-' '[:lower:]_' | tr -cd '[:alnum:]_')"
PROJECT_KEBAB="$(printf '%s' "$PROJECT" | tr '[:upper:]_' '[:lower:]-' | tr -cd '[:alnum:]-')"
PROJECT_CAMEL="$(printf '%s' "$PROJECT_KEBAB" | awk -F- '{for(i=1;i<=NF;i++) printf toupper(substr($i,1,1)) substr($i,2)}')"
TODAY="$(date +%Y-%m-%d)"

# ── Helpers available to the stack modules ───────────────────────────────────

run() {                       # run a command unless this is a dry run
  if $DRY_RUN; then skip "would run: $*"; return 0; fi
  "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

substitute() {                # replace the @@PLACEHOLDER@@ tokens in a file
  local file="$1"
  $DRY_RUN && return 0
  [[ -f "$file" ]] || return 0
  case "$file" in *.png|*.jpg|*.gif|*.ico|*.jar|*.zip) return 0 ;; esac
  sed -i.bak \
    -e "s|@@PROJECT@@|${PROJECT}|g" \
    -e "s|@@PROJECT_SNAKE@@|${PROJECT_SNAKE}|g" \
    -e "s|@@PROJECT_KEBAB@@|${PROJECT_KEBAB}|g" \
    -e "s|@@PROJECT_CAMEL@@|${PROJECT_CAMEL}|g" \
    -e "s|@@STACK@@|${STACK}|g" \
    -e "s|@@DATE@@|${TODAY}|g" \
    "$file" && rm -f "${file}.bak"
}

copy_if_absent() {            # copy_if_absent <src-file> <dest-file>
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then skip "kept existing $(realpath --relative-to="$DEST" "$dst" 2>/dev/null || echo "$dst")"; return 0; fi
  if $DRY_RUN; then skip "would create ${dst#"$DEST"/}"; return 0; fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  substitute "$dst"
}

copy_tree_if_absent() {       # copy_tree_if_absent <src-dir> <dest-dir>
  local src="$1" dst="$2" rel
  [[ -d "$src" ]] || return 0
  while IFS= read -r file; do
    rel="${file#"$src"/}"
    # Placeholders are expanded in paths too, so a skeleton can carry
    # src/@@PROJECT_SNAKE@@/main.py and land in the project's real package.
    rel="${rel//@@PROJECT_SNAKE@@/$PROJECT_SNAKE}"
    rel="${rel//@@PROJECT_KEBAB@@/$PROJECT_KEBAB}"
    rel="${rel//@@PROJECT_CAMEL@@/$PROJECT_CAMEL}"
    copy_if_absent "$file" "$dst/$rel"
  done < <(find "$src" -type f | sort)
}

make_dirs() {                 # keep empty architecture directories meaningful
  local dir
  for dir in "$@"; do
    [[ -z "$dir" ]] && continue
    if $DRY_RUN; then skip "would create $dir/"; continue; fi
    mkdir -p "$DEST/$dir"
    [[ -n "$(ls -A "$DEST/$dir" 2>/dev/null)" ]] || : > "$DEST/$dir/.gitkeep"
  done
}

# ── Defaults a stack module may override ────────────────────────────────────

stack_generate() { return 1; }               # layer 1: official generator
stack_overlay()  { copy_tree_if_absent "$SKELETON" "$DEST"; }   # layer 3

# ── Load the stack module ────────────────────────────────────────────────────
# shellcheck source=/dev/null
. "$MODULE"

# The Makefile generator reads the command contract from the environment.
export STACK CMD_INSTALL CMD_TEST CMD_LINT CMD_TYPECHECK CMD_BUILD CMD_DEV CMD_AUDIT

echo ""
info "Scaffolding ${STACK} (${STACK_LABEL}) — tier ${STACK_TIER}, mode ${MODE}"

[[ "$MODE" == "none" ]] && { success "Scaffolding skipped (--scaffold none)"; exit 0; }

# ── Layer 1 — framework boilerplate, from the official generator ─────────────
#
# Generators are run in an empty scratch directory and merged in afterwards:
# most of them (create-vite, rails new, cargo init) refuse to write into a
# directory that already holds files, and by this point the agent configuration
# is already there. The merge never clobbers an existing file.
GENERATED=false
GEN_DIR=""
if [[ "$MODE" == "full" ]]; then
  MISSING=""
  # shellcheck disable=SC2086  # STACK_REQUIRES is a deliberate word list
  for tool in ${STACK_REQUIRES:-}; do have "$tool" || MISSING="$MISSING $tool"; done
  if [[ -z "$MISSING" ]]; then
    info "Layer 1 — running the ${STACK} generator"
    GEN_DIR="$(mktemp -d)"
    trap 'rm -rf "$GEN_DIR"' EXIT
    if stack_generate; then
      GENERATED=true
      if ! $DRY_RUN && [[ -n "$(ls -A "$GEN_DIR" 2>/dev/null)" ]]; then
        # A generator's repository and its environment directories stay behind:
        # .git would graft a foreign history onto the project, and a virtualenv
        # or node_modules built in a temp path is broken once moved.
        rm -rf "$GEN_DIR/.git" "$GEN_DIR/.venv" "$GEN_DIR/node_modules" \
               "$GEN_DIR/target" "$GEN_DIR/.gradle" "$GEN_DIR/vendor"
        cp -rn "$GEN_DIR/." "$DEST/" 2>/dev/null || true
      fi
    else
      warn "generator failed — falling back to the committed build files"
    fi
    rm -rf "$GEN_DIR"
  else
    warn "missing toolchain:${MISSING} — skipping the official generator"
    warn "install it and re-run, or keep the fallback build files below"
  fi
fi

# ── Layer 2 — architecture declared by the preset (B5) ───────────────────────
info "Layer 2 — architecture"
# shellcheck disable=SC2086  # STACK_DIRS is a deliberate word list
make_dirs ${STACK_DIRS:-}

# ── Common overlay: command contract, docs, editor and env conventions ───────
info "Common overlay — Makefile, docs, conventions"
if [[ ! -e "$DEST/Makefile" ]]; then
  if $DRY_RUN; then
    skip "would create Makefile"
  else
    python3 - "$TEMPLATE_DIR/templates/common/Makefile.tpl" "$DEST/Makefile" <<'PY'
import sys, os
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
for token in ("INSTALL", "TEST", "LINT", "TYPECHECK", "BUILD", "DEV", "AUDIT"):
    value = os.environ.get("CMD_" + token, 'echo "TODO(TPL-1): define this command"')
    # A recipe line must start with a tab; keep multi-line commands valid.
    text = text.replace("\t@@%s@@" % token, "\n".join("\t" + line for line in value.splitlines()))
text = text.replace("@@STACK@@", os.environ.get("STACK", ""))
open(dst, "w", encoding="utf-8").write(text)
PY
    substitute "$DEST/Makefile"
  fi
else
  skip "kept existing Makefile"
fi

copy_if_absent "$TEMPLATE_DIR/templates/common/.editorconfig" "$DEST/.editorconfig"
copy_if_absent "$TEMPLATE_DIR/templates/common/.env.example"  "$DEST/.env.example"
copy_tree_if_absent "$TEMPLATE_DIR/templates/common/docs" "$DEST/docs"

# ── Layer 3 — walking skeleton (tier A stacks only) ──────────────────────────
SKELETON="$TEMPLATE_DIR/templates/skeleton/${STACK}"
if [[ "$MODE" == "full" && -d "$SKELETON" ]]; then
  info "Layer 3 — walking skeleton (health endpoints + example slice + tests)"
  stack_overlay
elif [[ "$MODE" == "full" ]]; then
  warn "no walking skeleton for ${STACK} (tier B) — the layout is created, the slices are yours to write"
fi

echo ""
success "Skeleton ready"
echo ""
echo -e "  Next: ${CYAN}cd $DEST && make install && make check${NC}"
$GENERATED || echo -e "  ${DIM}(the official ${STACK} generator did not run — see docs/SCAFFOLD.md)${NC}"
echo ""
