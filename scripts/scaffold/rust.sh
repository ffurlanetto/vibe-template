# shellcheck shell=bash
STACK_TIER="B"
STACK_LABEL="Rust / axum"
STACK_REQUIRES="cargo"
STACK_DIRS="src/api src/domain src/infrastructure tests"
CMD_INSTALL="cargo fetch"
CMD_TEST="cargo test --all-features"
CMD_LINT="cargo fmt --check && cargo clippy --all-targets --all-features -- -D warnings"
CMD_TYPECHECK="cargo check --all-targets"
CMD_BUILD="cargo build --release"
CMD_DEV="cargo run"
CMD_AUDIT="cargo audit || echo 'cargo-audit not installed: cargo install cargo-audit'"

stack_generate() {
  [[ -f "$DEST/Cargo.toml" ]] && { skip "Cargo.toml already present"; return 0; }
  $DRY_RUN && { skip "would run cargo init"; return 0; }
  ( cd "$DEST" && cargo init --name "$PROJECT_SNAKE" >/dev/null 2>&1 \
    && cargo add axum tokio --features tokio/full >/dev/null 2>&1 \
    && cargo add tracing tracing-subscriber >/dev/null 2>&1 ) || return 1
}
