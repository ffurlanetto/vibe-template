# shellcheck shell=bash
# Stack module: sourced by scripts/scaffold.sh, which consumes every variable below.
# shellcheck disable=SC2034
STACK_TIER="A"
STACK_LABEL="React 18 + Vite + TypeScript (Vue and Angular via FRONTEND_VARIANT)"
STACK_REQUIRES="npm"
STACK_DIRS="src/components src/lib src/routes tests"
CMD_INSTALL="npm ci || npm install"
CMD_TEST="npm run test -- --run"
CMD_LINT="npm run lint"
CMD_TYPECHECK="npx tsc --noEmit"
CMD_BUILD="npm run build"
CMD_DEV="npm run dev"
CMD_AUDIT="npm audit --audit-level=high"

# FRONTEND_VARIANT=react|vue|angular — react is the default and the only one
# carrying a walking skeleton; the others delegate entirely to their generator.
FRONTEND_VARIANT="${FRONTEND_VARIANT:-react}"

stack_generate() {
  [[ -f "$DEST/package.json" ]] && { skip "package.json already present"; return 0; }
  $DRY_RUN && { skip "would scaffold the ${FRONTEND_VARIANT} app"; return 0; }
  case "$FRONTEND_VARIANT" in
    react)   ( cd "$DEST" && npx --yes create-vite@latest . --template react-ts >/dev/null 2>&1 ) || return 1
             # Declare the test tooling; `make install` resolves it in one pass.
             ( cd "$DEST" \
               && npm pkg set scripts.test="vitest run" >/dev/null 2>&1 \
               && npm pkg set scripts.lint="eslint ." >/dev/null 2>&1 \
               && npm pkg set devDependencies.vitest="^2.1.8" >/dev/null 2>&1 \
               && npm pkg set devDependencies.jsdom="^25.0.1" >/dev/null 2>&1 \
               && npm pkg set devDependencies.@testing-library/react="^16.1.0" >/dev/null 2>&1 \
               && npm pkg set devDependencies.@testing-library/jest-dom="^6.6.3" >/dev/null 2>&1 ) ;;
    vue)     ( cd "$DEST" && npx --yes create-vite@latest . --template vue-ts >/dev/null 2>&1 ) || return 1 ;;
    angular) ( cd "$DEST" && npx --yes @angular/cli@latest new "$PROJECT_KEBAB" --directory . \
                 --skip-git --skip-install --style=css --routing >/dev/null 2>&1 ) || return 1 ;;
    *) warn "unknown FRONTEND_VARIANT '$FRONTEND_VARIANT'"; return 1 ;;
  esac
}

stack_overlay() {
  [[ "$FRONTEND_VARIANT" == "react" ]] || { warn "walking skeleton available for the react variant only"; return 0; }
  copy_tree_if_absent "$SKELETON" "$DEST"
}
