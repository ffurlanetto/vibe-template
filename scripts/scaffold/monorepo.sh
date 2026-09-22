# shellcheck shell=bash
STACK_TIER="B"
STACK_LABEL="Nx or Turborepo monorepo"
STACK_REQUIRES="npx"
STACK_DIRS="apps packages tools"
CMD_INSTALL="npm ci || npm install"
CMD_TEST="npx turbo run test 2>/dev/null || npx nx run-many -t test"
CMD_LINT="npx turbo run lint 2>/dev/null || npx nx run-many -t lint"
CMD_TYPECHECK="npx turbo run typecheck 2>/dev/null || npx nx run-many -t typecheck"
CMD_BUILD="npx turbo run build 2>/dev/null || npx nx run-many -t build"
CMD_DEV="npx turbo run dev 2>/dev/null || npx nx run-many -t serve"
CMD_AUDIT="npm audit --audit-level=high"

stack_generate() {
  [[ -f "$DEST/package.json" ]] && { skip "package.json already present"; return 0; }
  $DRY_RUN && { skip "would scaffold a turborepo workspace"; return 0; }
  ( cd "$DEST" && npx --yes create-turbo@latest . -m npm >/dev/null 2>&1 ) || return 1
}
