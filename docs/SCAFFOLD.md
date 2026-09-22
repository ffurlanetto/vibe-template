# Scaffolding

`init.sh` produces a project that already runs, already tests itself, and whose
quality gate is green on the first commit. It does that in three layers, each
with a different owner.

| Layer | Owner | What it produces |
|-------|-------|------------------|
| 1 — framework boilerplate | the stack's **official generator** | manifest, lockfile, entry point, build config |
| 2 — architecture | **this template** | the directory layout the preset declares in B5 |
| 3 — walking skeleton | **this template** | health endpoints, one vertical slice, its tests |

Layer 1 is delegated on purpose: `uv`, `nest new`, `start.spring.io`,
`create-vite` and friends track their own framework far better than a vendored
copy ever could. Layers 2 and 3 are what the template actually knows: the
architecture it imposes and the end-to-end slice that proves the toolchain works.

---

## Tiers

**Tier A** ships layer 3: `python-fastapi`, `go`, `nestjs`, `java-spring`,
`java-spring-gradle`, `java-quarkus`, `frontend`.

**Tier B** ships layers 1 and 2: `dotnet-aspnet`, `rust`, `rails`,
`react-native`, `flutter`, `monorepo`, `sre`. You get a project that builds, the
imposed architecture, a wired `Makefile` and a green pipeline — the health
endpoints and the example slice are yours to write.

---

## The command contract

Every generated project exposes the same targets, whatever the stack:

```bash
make install test lint typecheck build dev audit check
```

The recipes come from the `CMD_*` variables in `scripts/scaffold/<stack>.sh`,
which mirror the command block the preset declares. This is why the CI pipeline
is stack-agnostic and the agent permissions are a single `Bash(make *)` rule
instead of fourteen stack blocks.

---

## Adding a stack, or promoting one to tier A

A stack module is one file, `scripts/scaffold/<stack>.sh`, defining:

```bash
STACK_TIER="A"                  # A ships a walking skeleton, B does not
STACK_LABEL="Python 3.12 / FastAPI"
STACK_REQUIRES="uv"             # binaries layer 1 needs; absent → layer 1 is skipped
STACK_DIRS="src/... tests/..."  # layer 2, from the preset's B5 section
CMD_INSTALL="..." CMD_TEST="..." CMD_LINT="..." CMD_TYPECHECK="..."
CMD_BUILD="..." CMD_DEV="..." CMD_AUDIT="..."

stack_generate() { ... }        # layer 1; return non-zero to fall back
stack_overlay()  { ... }        # layer 3; defaults to copying the skeleton
```

Helpers available inside a module: `run`, `have`, `copy_if_absent`,
`copy_tree_if_absent`, `make_dirs`, `substitute`, `skip`, `warn`, and the
variables `$DEST`, `$PROJECT`, `$PROJECT_SNAKE`, `$PROJECT_KEBAB`,
`$PROJECT_CAMEL`, `$SKELETON`, `$DRY_RUN`.

To promote a stack to tier A, add `templates/skeleton/<stack>/` containing:

- `/health/live` and `/health/ready` per `docs/specs/SPEC-001-health-endpoints.md`
- configuration read from the environment, failing fast on an invalid value
- structured JSON logging
- one vertical slice: route → service → repository behind an interface
- at least one unit test and one integration test, named `[Subject]_[Scenario]_[Result]`

Placeholders are expanded in file **contents and paths**: `@@PROJECT@@`,
`@@PROJECT_SNAKE@@`, `@@PROJECT_KEBAB@@`, `@@PROJECT_CAMEL@@`, `@@STACK@@`,
`@@DATE@@`. A file named `src/@@PROJECT_SNAKE@@/main.py` lands in the project's
real package.

Then set `STACK_TIER="A"` and add the stack to the matrix in
`.github/workflows/template-ci.yml`.

---

## Rules the scaffolder follows

- **Nothing is overwritten.** An existing file always wins; re-running `init.sh`
  on a live project only adds what is missing.
- **A generator that cannot run is not an error.** Layer 1 is skipped with a
  warning, and the committed fallback build file takes over — which is why
  `java-spring` builds behind a proxy that blocks `start.spring.io`.
- **Generator placeholders may be replaced.** A `Hello from ...` stub or an
  untouched `app.module.ts` is boilerplate, not your code.
- **`--dry-run` writes nothing** and lists every action.
