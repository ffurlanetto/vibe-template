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

### Tests

- Framework: pytest + pytest-asyncio + httpx (for API tests)
- Minimum coverage: 80% (pytest-cov)
- pytest fixtures for shared test data
- `TestClient` or httpx `AsyncClient` for integration tests
- Naming pattern: `test_[subject]_[scenario]_[result]`

### Lint & Quality

- `ruff check` — fast linter (replaces flake8, isort, pyupgrade)
- `ruff format` — formatter (replaces black)
- `mypy --strict` for type checking
- Zero mypy and ruff errors in CI

### Commands (B4)

```bash
# Install
uv sync  # or: pip install -e ".[dev]"

# Test
pytest --cov=src --cov-report=term-missing

# Lint
ruff check .
ruff format --check .

# Type check
mypy src/

# Run locally
uvicorn src.<project>.main:app --reload
```

### Typical structure

```
src/<project>/
├── main.py              # FastAPI entry point
├── config.py            # Pydantic BaseSettings
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
