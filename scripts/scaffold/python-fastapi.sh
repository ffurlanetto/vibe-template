# shellcheck shell=bash
# Stack module: sourced by scripts/scaffold.sh, which consumes every variable below.
# shellcheck disable=SC2034
STACK_TIER="A"
STACK_LABEL="Python 3.12 / FastAPI"
STACK_REQUIRES="uv"
STACK_DIRS="src/@@PROJECT_SNAKE@@/routers src/@@PROJECT_SNAKE@@/services src/@@PROJECT_SNAKE@@/repositories src/@@PROJECT_SNAKE@@/schemas src/@@PROJECT_SNAKE@@/core tests/unit tests/integration"
CMD_INSTALL="uv sync"
CMD_TEST="uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=80"
CMD_LINT="uv run ruff check .
uv run ruff format --check ."
CMD_TYPECHECK="uv run mypy src/"
CMD_BUILD="uv build"
CMD_DEV="uv run uvicorn ${PROJECT_SNAKE}.main:app --reload --port \$\${PORT:-8080}"
CMD_AUDIT="uv run pip-audit || echo 'pip-audit not installed: uv add --dev pip-audit'"

# STACK_DIRS carries placeholders; expand them before the orchestrator uses it.
STACK_DIRS="${STACK_DIRS//@@PROJECT_SNAKE@@/$PROJECT_SNAKE}"

stack_generate() {
  [[ -f "$DEST/pyproject.toml" ]] && { skip "pyproject.toml already present"; return 0; }
  run uv init --package --name "$PROJECT_KEBAB" --directory "$DEST" >/dev/null 2>&1 || return 1
  $DRY_RUN && return 0
  ( cd "$DEST" && uv add fastapi "uvicorn[standard]" pydantic-settings >/dev/null 2>&1 \
    && uv add --dev pytest pytest-asyncio pytest-cov httpx ruff mypy >/dev/null 2>&1 )
}

stack_overlay() {
  copy_tree_if_absent "$SKELETON" "$DEST"
  # `uv init --package` leaves a "Hello from ..." placeholder module. It is
  # generator scaffolding, not project code, so the skeleton version wins.
  local pkg_init="$DEST/src/$PROJECT_SNAKE/__init__.py"
  if [[ -f "$pkg_init" ]] && grep -q "Hello from" "$pkg_init"; then
    $DRY_RUN && return 0
    cp "$SKELETON/src/@@PROJECT_SNAKE@@/__init__.py" "$pkg_init"
    substitute "$pkg_init"
  fi
}
