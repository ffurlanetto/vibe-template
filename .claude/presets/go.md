# Preset B3 — Go

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Structured logging: `log/slog` — never `fmt.Println` in production
- Errors wrapped with context: `fmt.Errorf("operation context: %w", err)`
- Interfaces defined on the consumer side (not the implementer side)
- No business logic in HTTP handlers — delegate to the service layer
- No `init()` except with documented justification
- `context.Context` as the first parameter of all I/O functions
- No unsupervised goroutines — use explicit lifecycle patterns

### Tests

- Framework: `testing` standard + `testify/assert` + `testify/require`
- Minimum coverage: 80% per package
- `-race` always enabled: `go test ./... -race -count=1`
- `testcontainers-go` for integration tests with DB or external services
- Mocks via interfaces — generate with `mockery` for large volumes
- Naming pattern: `Test[Function]_[Scenario]_[Result]`

### Lint & Quality

- `golangci-lint` with `.golangci.yml` configuration
- `go vet ./...` — zero warnings
- Enabled linters: `errcheck`, `staticcheck`, `gosec`, `unused`, `gocritic`
- Zero warnings tolerated in CI

### Commands (B4)

```bash
# Install
go mod download

# Test
go test ./... -race -count=1 -coverprofile=coverage.out

# Lint
golangci-lint run ./...
go vet ./...

# Build
go build ./...

# Run locally
go run ./cmd/<appname>/...
```

### Typical structure

```
cmd/
└── <appname>/
    └── main.go
internal/
├── <module1>/
│   ├── handler.go      # HTTP handlers (chi router)
│   ├── service.go      # Business logic
│   ├── repository.go   # Interface + DB implementation
│   └── model.go        # Domain types
├── <module2>/
└── shared/
    ├── middleware/
    └── config/
pkg/                    # Exportable code (internal libraries)
```
