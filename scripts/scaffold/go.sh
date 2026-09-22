# shellcheck shell=bash
# Stack module: sourced by scripts/scaffold.sh, which consumes every variable below.
# shellcheck disable=SC2034
STACK_TIER="A"
STACK_LABEL="Go 1.23 / chi"
STACK_REQUIRES="go"
STACK_DIRS="cmd/server internal/health internal/example internal/platform/config internal/platform/logging"
CMD_INSTALL="go mod download"
CMD_TEST="go test ./... -race -count=1 -cover"
CMD_LINT="gofmt -l . | (! grep .) && go vet ./...
command -v golangci-lint >/dev/null && golangci-lint run ./... || echo 'golangci-lint not installed — skipped'"
CMD_TYPECHECK="go build ./..."
CMD_BUILD="go build -o bin/server ./cmd/server"
CMD_DEV="go run ./cmd/server"
CMD_AUDIT="go vet ./... && (command -v govulncheck >/dev/null && govulncheck ./... || echo 'govulncheck not installed: go install golang.org/x/vuln/cmd/govulncheck@latest')"

stack_generate() {
  [[ -f "$DEST/go.mod" ]] && { skip "go.mod already present"; return 0; }
  $DRY_RUN && { skip "would run go mod init"; return 0; }
  ( cd "$DEST" && go mod init "$PROJECT_KEBAB" >/dev/null 2>&1 ) || return 1
}

stack_overlay() {
  copy_tree_if_absent "$SKELETON" "$DEST"
  $DRY_RUN && return 0
  have go && ( cd "$DEST" && go mod tidy >/dev/null 2>&1 ) || true
}
