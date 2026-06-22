# Preset B3 — Java / Quarkus / Gradle

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- CDI injection with `@ApplicationScoped`, `@RequestScoped`, `@Singleton` — no manual instantiation
- REST endpoints via RESTEasy Reactive (`@Path`, `@GET`, `@POST`…) — not the classic RESTEasy
- Return `Uni<T>` / `Multi<T>` (Mutiny) for reactive endpoints; `T` directly for blocking endpoints
- No business logic in resource classes — delegate to `@ApplicationScoped` services
- Data access via **Panache** (`PanacheEntity` or `PanacheRepository`) — not raw EntityManager
- DTOs for all API inputs/outputs (never expose entities directly)
- Records for immutable DTOs (Java 16+)
- `@ConfigProperty` for configuration — never `System.getenv()` directly
- `application.properties` for config — profiles via `%dev.`, `%test.`, `%prod.` prefixes

### Tests

- Framework: JUnit 5 + RestAssured + AssertJ
- `@QuarkusTest` for integration tests (starts full Quarkus instance)
- `@QuarkusUnitTest` for lightweight unit tests without full CDI context
- **Dev Services**: Quarkus auto-starts PostgreSQL / Redis / Kafka via Testcontainers in test — no manual setup
- `@TestHTTPEndpoint` to scope RestAssured to a specific resource
- Minimum coverage: 80% (JaCoCo via Gradle)
- Naming pattern: `[Subject]_[Scenario]_[Result]`

### Lint & Quality

- Checkstyle (Google Java Style) via Gradle plugin
- SpotBugs + FindSecBugs
- `./gradlew check` runs all quality gates
- Zero warnings treated as errors in CI

### Commands (B4)

```bash
# Install
./gradlew dependencies

# Test
./gradlew test

# Test (native mode — slower, for CI only)
./gradlew testNative

# Lint
./gradlew checkstyleMain spotbugsMain

# Build (JVM — fast)
./gradlew build

# Build (native image — requires GraalVM)
./gradlew build -Dquarkus.package.type=native

# Run locally (dev mode with live reload)
./gradlew quarkusDev
```

### Typical structure

```
src/
├── main/
│   ├── java/com/<company>/<project>/
│   │   ├── <module>/
│   │   │   ├── <Resource>.java         # REST resource (@Path)
│   │   │   ├── <Service>.java          # Business logic (@ApplicationScoped)
│   │   │   ├── <Repository>.java       # Panache repository
│   │   │   ├── <Entity>.java           # JPA entity (extends PanacheEntity)
│   │   │   └── dto/
│   │   │       ├── <Create>Request.java
│   │   │       └── <Entity>Response.java
│   │   └── shared/
│   │       ├── exception/              # ExceptionMappers
│   │       └── health/                 # Custom health checks
│   └── resources/
│       ├── application.properties      # Main config (dev + prod profiles)
│       └── import.sql                  # Dev fixtures (loaded in dev mode)
└── test/
    └── java/com/<company>/<project>/
        └── <module>/
            ├── <Resource>Test.java      # @QuarkusTest — full stack
            └── <Service>Test.java       # @QuarkusUnitTest — isolated
```

### build.gradle.kts baseline

```kotlin
plugins {
    java
    id("io.quarkus") version "3.17.0"
    id("checkstyle")
    id("com.github.spotbugs") version "6.0.0"
    id("jacoco")
}

repositories {
    mavenCentral()
}

val quarkusPlatformVersion = "3.17.0"

dependencies {
    implementation(enforcedPlatform("io.quarkus.platform:quarkus-bom:$quarkusPlatformVersion"))

    // Core
    implementation("io.quarkus:quarkus-rest")
    implementation("io.quarkus:quarkus-rest-jackson")
    implementation("io.quarkus:quarkus-hibernate-orm-panache")
    implementation("io.quarkus:quarkus-jdbc-postgresql")

    // Observability
    implementation("io.quarkus:quarkus-smallrye-health")
    implementation("io.quarkus:quarkus-micrometer-registry-prometheus")
    implementation("io.quarkus:quarkus-opentelemetry")

    // Auth
    implementation("io.quarkus:quarkus-oidc")           // OIDC / JWT
    // implementation("io.quarkus:quarkus-smallrye-jwt")  // Self-signed JWT

    // Test
    testImplementation("io.quarkus:quarkus-junit5")
    testImplementation("io.rest-assured:rest-assured")
    testImplementation("org.assertj:assertj-core:3.26.3")
}

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

tasks.test {
    systemProperty("java.util.logging.manager", "org.jboss.logmanager.LogManager")
}

jacoco {
    toolVersion = "0.8.12"
}

tasks.jacocoTestReport {
    reports { xml.required = true }
}
```

### application.properties baseline

```properties
# ── Database ──────────────────────────────────────────────────────────
quarkus.datasource.db-kind=postgresql
quarkus.datasource.username=${DB_USER}
quarkus.datasource.password=${DB_PASSWORD}
quarkus.datasource.jdbc.url=${DB_URL}
quarkus.hibernate-orm.database.generation=validate

# Dev profile — Dev Services auto-starts PostgreSQL (no config needed)
%dev.quarkus.hibernate-orm.database.generation=drop-and-create
%dev.quarkus.hibernate-orm.sql-load-script=import.sql

# ── HTTP ──────────────────────────────────────────────────────────────
quarkus.http.port=8080
quarkus.http.cors=true
quarkus.http.cors.origins=${CORS_ORIGINS:http://localhost:3000}

# ── Observability ─────────────────────────────────────────────────────
quarkus.log.console.json=true
%dev.quarkus.log.console.json=false
quarkus.otel.exporter.otlp.endpoint=${OTEL_ENDPOINT:http://localhost:4317}
```
