# Preset B3 — Python / FastAPI

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Type hints required on all public functions
- Pydantic v2 for API input/output validation
- `BaseModel` for data schemas — never raw `dict` at boundaries
- No `Any` in public signatures
- Dependencies injected via the FastAPI DI system (`Depends`)
- Separation: `routers/` (HTTP) → `services/` (logic) → `repositories/` (data)
- Consistent async/await: no sync/async mixing within the same layer
- All dependencies declared in `pyproject.toml` — no `requirements.txt`
- Dev dependencies in `[dependency-groups]` (uv) or `[project.optional-dependencies]`

### Tests

- Framework: pytest + pytest-asyncio + httpx (for API tests)
- Minimum coverage: 80% (`uv run pytest --cov`)
- pytest fixtures for shared test data
- `TestClient` or httpx `AsyncClient` for integration tests
- Naming pattern: `test_[subject]_[scenario]_[result]`

### Lint & Quality

- `ruff check` — fast linter (replaces flake8, isort, pyupgrade)
- `ruff format` — formatter (replaces black)
- `mypy --strict` for type checking
- Zero mypy and ruff errors in CI
- All tools run via `uv run` — no global installs required

### Commands (B4)

```bash
# Install (creates .venv automatically)
uv sync

# Test
uv run pytest --cov=src --cov-report=term-missing

# Lint
uv run ruff check .
uv run ruff format --check .

# Type check
uv run mypy src/

# Run locally
uv run uvicorn src.<project>.main:app --reload
```

### Typical structure

```
pyproject.toml           # Single source of truth for deps and tools
src/<project>/
├── main.py              # FastAPI entry point
├── config.py            # Pydantic BaseSettings (reads from env)
├── routers/             # FastAPI endpoints
├── services/            # Business logic
├── repositories/        # Data access
├── models/              # SQLAlchemy / ODM models
├── schemas/             # Pydantic schemas (request/response)
└── core/                # Auth, middleware, utilities
tests/
├── unit/
├── integration/
└── conftest.py          # Shared fixtures
```

### pyproject.toml baseline

```toml
[project]
name = "<project>"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.32",
    "pydantic>=2.9",
    "pydantic-settings>=2.6",
]

[dependency-groups]
dev = [
    "pytest>=8",
    "pytest-asyncio>=0.24",
    "pytest-cov>=6",
    "httpx>=0.27",
    "ruff>=0.8",
    "mypy>=1.13",
]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]

[tool.mypy]
strict = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
```
