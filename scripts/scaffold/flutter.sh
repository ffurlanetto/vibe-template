# shellcheck shell=bash
STACK_TIER="B"
STACK_LABEL="Flutter / Dart"
STACK_REQUIRES="flutter"
STACK_DIRS="lib/features lib/core lib/data test/unit test/widget"
CMD_INSTALL="flutter pub get"
CMD_TEST="flutter test --coverage"
CMD_LINT="dart format --set-exit-if-changed . && flutter analyze"
CMD_TYPECHECK="flutter analyze"
CMD_BUILD="flutter build apk --debug"
CMD_DEV="flutter run"
CMD_AUDIT="flutter pub outdated"

stack_generate() {
  [[ -f "$DEST/pubspec.yaml" ]] && { skip "pubspec.yaml already present"; return 0; }
  $DRY_RUN && { skip "would run flutter create"; return 0; }
  ( cd "$DEST" && flutter create --project-name "$PROJECT_SNAKE" . >/dev/null 2>&1 ) || return 1
}
