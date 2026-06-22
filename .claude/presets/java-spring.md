# Preset B3 — Java / Spring Boot

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Strict layered architecture: `@Controller` → `@Service` → `@Repository`
- DTOs required for all API inputs/outputs (no JPA entities exposed directly)
- Java records for immutable DTOs (Java 16+)
- `@Validated` on controllers, Bean Validation annotations on DTOs
- `Optional<T>` for nullable returns — never return `null` directly
- No logic in controllers — always delegate to the service layer
- Transactions declared at the service level (`@Transactional`), never in repositories

### Tests

- Framework: JUnit 5 + Mockito + AssertJ
- Minimum coverage: 80% per package (Jacoco)
- `@SpringBootTest` only for integration tests (expensive)
- Use `@WebMvcTest`, `@DataJpaTest` for slices
- Naming pattern: `[Subject]_[Scenario]_[Result]`

### Lint & Quality

- Checkstyle (Google Java Style or Sun)
- SpotBugs + FindSecBugs
- PMD for cyclomatic complexity
- Zero warnings treated as errors in CI

### Commands (B4)

```bash
# Install
mvn install -DskipTests

# Test
mvn test

# Lint
mvn checkstyle:check spotbugs:check

# Build
mvn package

# Run locally
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### Typical structure

```
src/
├── main/java/com/<company>/<project>/
│   ├── <module>/
│   │   ├── api/          # Controllers, request/response DTOs
│   │   ├── application/  # Services, use cases
│   │   ├── domain/       # Entities, value objects, repository interfaces
│   │   └── infrastructure/ # JPA implementations, HTTP clients
│   └── shared/           # Cross-cutting utilities
└── test/java/com/<company>/<project>/
    └── <mirror of main>
```
