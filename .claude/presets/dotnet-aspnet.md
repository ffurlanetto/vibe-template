# Preset B3 — .NET / ASP.NET Core

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Architecture: Clean Architecture (Domain → Application → Infrastructure → Presentation)
- DTOs via `record` types (C# 9+) — immutable by default
- `Result<T>` pattern for operations that may fail (no exceptions for business flow)
- Nullable reference types enabled (`#nullable enable` or in `csproj`)
- No `null` returned — use `Option<T>` or `Result<T>`
- Dependency Injection via constructor — never service locator
- MediatR handlers for commands and queries (CQRS)

### Tests

- Framework: xUnit + Moq (or NSubstitute) + FluentAssertions
- Minimum coverage: 80% (Coverlet)
- `WebApplicationFactory<T>` for integration tests
- Naming pattern: `[Subject]_[Scenario]_[Result]`
- Builders / mothers for test data creation

### Lint & Quality

- Roslyn Analyzers (`Microsoft.CodeAnalysis.NetAnalyzers`)
- StyleCop.Analyzers for style
- `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` in CI
- SonarAnalyzer.CSharp if SonarQube is available

### Commands (B4)

```bash
# Install
dotnet restore

# Test
dotnet test --collect:"XPlat Code Coverage"

# Lint / Build with warnings-as-errors
dotnet build --configuration Release /p:TreatWarningsAsErrors=true

# Format
dotnet format --verify-no-changes

# Run locally
dotnet run --project src/<Project>.Api --launch-profile Development
```

### Typical structure

```
src/
├── <Project>.Domain/          # Entities, value objects, interfaces
├── <Project>.Application/     # Use cases, commands, queries, DTOs
├── <Project>.Infrastructure/  # EF Core, HTTP clients, implementations
└── <Project>.Api/             # Controllers, middleware, DI configuration
tests/
├── <Project>.UnitTests/
├── <Project>.IntegrationTests/
└── <Project>.ArchitectureTests/  # ArchUnitNET — enforce layer dependencies
```
