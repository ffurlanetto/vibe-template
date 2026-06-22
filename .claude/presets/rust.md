# Preset B3 — Rust

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- `unwrap()` and `expect()` forbidden in production code — propagate with `?`
- Errors: `thiserror` for libraries, `anyhow` for applications
- `unsafe` only with a comment block justifying the safety invariant and mandatory review
- No systematic `clone()` — prefer references and explicit lifetimes
- `Arc<Mutex<T>>` only when shared mutability is genuinely required
- No `unwrap_or_default()` to silently mask errors
- `#[must_use]` on Result / Option types returned by public functions
- Structured logging: `tracing` — never `println!` in production

### Tests

- Framework: `cargo test` (built-in) + `proptest` for property-based testing
- Minimum coverage: 80% (`cargo llvm-cov`)
- Integration tests in `tests/` (separate from unit tests inside modules)
- Benchmarks in `benches/` with `criterion`
- Naming pattern: `test_[function]_[scenario]_[result]`

### Lint & Quality

- `clippy::pedantic` in CI — zero warnings (`cargo clippy -- -D warnings -W clippy::pedantic`)
- `cargo fmt --check` — formatting required
- `cargo audit` — CVE scan on dependencies
- `cargo deny` — license and duplicate dependency check
- Zero `rustc` warnings tolerated

### Commands (B4)

```bash
# Install
cargo build

# Test
cargo test --all-features
cargo llvm-cov --all-features --workspace

# Lint
cargo clippy --all-targets --all-features -- -D warnings -W clippy::pedantic
cargo fmt --check

# Security audit
cargo audit
cargo deny check

# Release build
cargo build --release

# Run locally
cargo run --bin <appname>
```

### Typical structure

```
src/
├── main.rs              # Entry point (applications)
├── lib.rs               # Entry point (libraries)
├── error.rs             # Centralized error types (thiserror)
├── config.rs            # Configuration (config-rs or envy)
├── <module1>/
│   ├── mod.rs
│   ├── handler.rs       # HTTP handlers (axum / actix)
│   ├── service.rs       # Business logic
│   └── repository.rs    # Data access
└── shared/
    ├── middleware.rs
    └── tracing.rs       # Tracing / OpenTelemetry init
tests/
├── integration/
│   └── <module1>_test.rs
└── common/
    └── mod.rs           # Shared helpers for integration tests
benches/
└── <module1>_bench.rs
```

### Recommended dependencies

```toml
[dependencies]
# HTTP (choose one)
axum = "0.7"          # Recommended — native tokio ecosystem
# actix-web = "4"     # Alternative — very high performance

tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"          # Error handling (applications)
thiserror = "1"       # Error handling (libraries)
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["json"] }
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio"] }  # if DB

[dev-dependencies]
proptest = "1"
criterion = "0.5"
tokio-test = "0.4"
```
