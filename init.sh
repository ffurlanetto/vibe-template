#!/usr/bin/env bash
# init.sh — Bootstrap a new project from the Claude Code template
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✗${NC} $*"; exit 1; }

# ── Available stacks ──────────────────────────────────────────────────────────
STACKS=("java-spring" "dotnet-aspnet" "python-fastapi" "go" "nestjs" "rust" "rails" "react-native" "flutter" "monorepo" "frontend")

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo "Usage: $0 <project-name> <stack> [destination]"
  echo ""
  echo "Available stacks:"
  for s in "${STACKS[@]}"; do echo "  - $s"; done
  echo ""
  echo "Examples:"
  echo "  $0 my-api python-fastapi"
  echo "  $0 my-api python-fastapi /path/to/new-project"
  echo ""
  exit 1
}

# ── Argument validation ───────────────────────────────────────────────────────
[[ $# -lt 2 ]] && usage

PROJECT_NAME="$1"
STACK="$2"
DEST="${3:-$(pwd)/$PROJECT_NAME}"
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate stack
VALID_STACK=false
for s in "${STACKS[@]}"; do [[ "$STACK" == "$s" ]] && VALID_STACK=true && break; done
[[ "$VALID_STACK" == false ]] && error "Unknown stack '$STACK'. Valid stacks: ${STACKS[*]}"

PRESET_FILE="$TEMPLATE_DIR/.claude/presets/${STACK}.md"
[[ ! -f "$PRESET_FILE" ]] && error "Preset not found: $PRESET_FILE"

# ── Destination ───────────────────────────────────────────────────────────────
if [[ -d "$DEST" ]]; then
  warn "Directory '$DEST' already exists."
  read -p "Continue and overwrite template files? [y/N] " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && error "Cancelled."
fi

# ── Copy template ─────────────────────────────────────────────────────────────
info "Creating $DEST..."
mkdir -p "$DEST"
cp -r "$TEMPLATE_DIR/." "$DEST/"
rm -f "$DEST/init.sh"         # Do not copy this script into the project

# ── Project name substitution ─────────────────────────────────────────────────
info "Configuring project '$PROJECT_NAME'..."
if command -v sed &>/dev/null; then
  sed -i.bak "s/<PROJECT_NAME>/$PROJECT_NAME/g" "$DEST/CLAUDE.md" && rm -f "$DEST/CLAUDE.md.bak"
  sed -i.bak "s/<PROJECT_NAME>/$PROJECT_NAME/g" "$DEST/docs/adr/README.md" && rm -f "$DEST/docs/adr/README.md.bak"
fi

# ── Inject preset into CLAUDE.md ──────────────────────────────────────────────
info "Injecting $STACK preset..."
PRESET_CONTENT=$(cat "$PRESET_FILE")
MARKER="### Code conventions"
if grep -q "$MARKER" "$DEST/CLAUDE.md"; then
  echo "" >> "$DEST/CLAUDE.md"
  echo "<!-- Auto-injected preset: $STACK -->" >> "$DEST/CLAUDE.md"
  echo "$PRESET_CONTENT" >> "$DEST/CLAUDE.md"
fi

# ── Create .gitignore if absent ───────────────────────────────────────────────
if [[ ! -f "$DEST/.gitignore" ]]; then
  info "Creating .gitignore..."
  cat > "$DEST/.gitignore" <<'GITIGNORE'
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
GITIGNORE
fi

# ── Create docs directories ───────────────────────────────────────────────────
mkdir -p "$DEST/docs/specs" "$DEST/docs/runbooks"

# ── CI/CD templates ───────────────────────────────────────────────────────────
if [[ ! -d "$DEST/.github" ]]; then
  info "Creating GitHub Actions CI pipeline..."
  mkdir -p "$DEST/.github/workflows"
  cat > "$DEST/.github/workflows/quality-gate.yml" <<YAML
name: Quality Gate

on:
  pull_request:
    branches: [main, master, develop]
  push:
    branches: [main, master]

jobs:
  quality:
    name: Tests · Lint · Build
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4

      # Adapt steps below to your stack (see B4 in CLAUDE.md)
      - name: Install dependencies
        run: echo "Replace with <install_cmd> from section B4"

      - name: Run tests
        run: echo "Replace with <test_cmd> from section B4"

      - name: Lint
        run: echo "Replace with <lint_cmd> from section B4"

      - name: Build
        run: echo "Replace with <build_cmd> from section B4"
YAML
fi

# ── Template version marker ───────────────────────────────────────────────────
TEMPLATE_VERSION=$(cat "$TEMPLATE_DIR/VERSION" 2>/dev/null || echo "unknown")
echo "$TEMPLATE_VERSION" > "$DEST/.claude/.template-version"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
success "Project '$PROJECT_NAME' initialized at $DEST"
echo ""
echo "  Stack    : $STACK"
echo "  Template : v$TEMPLATE_VERSION"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. cd $DEST"
echo "  2. Complete sections B1–B8 in CLAUDE.md"
echo "     (replace all <angle bracket> values)"
echo "  3. Uncomment the permissions matching your stack in .claude/settings.json"
echo "  4. Adapt .github/workflows/quality-gate.yml with the B4 commands"
echo "  5. Create your first ADR: /adr [initial architectural decision]"
echo ""
