# shellcheck shell=bash
# Stack module: sourced by scripts/scaffold.sh, which consumes every variable below.
# shellcheck disable=SC2034
STACK_TIER="B"
STACK_LABEL="React Native / Expo"
STACK_REQUIRES="npx"
STACK_DIRS="src/screens src/components src/services src/hooks __tests__"
CMD_INSTALL="npm ci || npm install"
CMD_TEST="npm run test -- --watchAll=false"
CMD_LINT="npx eslint ."
CMD_TYPECHECK="npx tsc --noEmit"
CMD_BUILD="npx expo export"
CMD_DEV="npx expo start"
CMD_AUDIT="npm audit --audit-level=high"

stack_generate() {
  [[ -f "$DEST/package.json" ]] && { skip "package.json already present"; return 0; }
  $DRY_RUN && { skip "would run create-expo-app"; return 0; }
  ( cd "$DEST" && npx --yes create-expo-app@latest . --template blank-typescript >/dev/null 2>&1 ) || return 1
}
