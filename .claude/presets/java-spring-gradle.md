# Preset B3 — Java / Spring Boot / Gradle

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Strict layered architecture: `@RestController` → `@Service` → `@Repository`
- DTOs required for all API inputs/outputs (no JPA entities exposed directly)
- Java records for immutable DTOs (Java 16+)
- `@Validated` on controllers, Bean Validation annotations on DTOs
- `Optional<T>` for nullable returns — never return `null` directly
- No logic in controllers — always delegate to the service layer
- Transactions declared at the service level (`@Transactional`), never in repositories
- Configuration via `@ConfigurationProperties` records — never `@Value` on fields

### Tests

- Framework: JUnit 5 + Mockito + AssertJ
- Minimum coverage: 80% per package (JaCoCo via Gradle)
- `@SpringBootTest` only for integration tests (expensive)
- Use `@WebMvcTest`, `@DataJpaTest` for slices
- Naming pattern: `[Subject]_[Scenario]_[Result]`

### Lint & Quality

- Checkstyle (Google Java Style) via Gradle plugin
- SpotBugs + FindSecBugs
- `./gradlew check` runs all quality gates
- Zero warnings treated as errors in CI

### Commands (B4)

```bash
# Install / resolve dependencies
./gradlew dependencies

# Test
./gradlew test

# Lint
./gradlew checkstyleMain spotbugsMain

# Type check / compile
./gradlew compileJava

# Build (skip tests)
./gradlew build -x test

# Full build (tests + quality gates)
./gradlew build

# Run locally
./gradlew bootRun --args='--spring.profiles.active=local'
```

### Typical structure

```
src/
├── main/java/com/<company>/<project>/
│   ├── <module>/
│   │   ├── api/            # Controllers, request/response DTOs
│   │   ├── application/    # Services, use cases
│   │   ├── domain/         # Entities, value objects, repository interfaces
│   │   └── infrastructure/ # JPA implementations, HTTP clients
│   └── shared/             # Cross-cutting utilities
└── test/java/com/<company>/<project>/
    └── <mirror of main>
```

### build.gradle.kts baseline

```kotlin
plugins {
    java
    id("org.springframework.boot") version "3.3.0"
    id("io.spring.dependency-management") version "1.1.5"
    id("checkstyle")
    id("com.github.spotbugs") version "6.0.0"
    id("jacoco")
}

group = "com.<company>"
version = "0.0.1-SNAPSHOT"

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

repositories {
    mavenCentral()
}

dependencies {
    // Web
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-validation")

    // Data
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    runtimeOnly("org.postgresql:postgresql")

    // Observability
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("io.micrometer:micrometer-registry-prometheus")
    implementation("io.micrometer:micrometer-tracing-bridge-otel")
    implementation("io.opentelemetry.instrumentation:opentelemetry-spring-boot-starter")

    // Security
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-oauth2-resource-server")

    // Dev tools
    developmentOnly("org.springframework.boot:spring-boot-devtools")
    annotationProcessor("org.springframework.boot:spring-boot-configuration-processor")

    // Test
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.assertj:assertj-core")
}

tasks.test {
    useJUnitPlatform()
    finalizedBy(tasks.jacocoTestReport)
}

jacoco {
    toolVersion = "0.8.12"
}

tasks.jacocoTestReport {
    dependsOn(tasks.test)
    reports { xml.required = true }
}

tasks.jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = "0.80".toBigDecimal()
            }
        }
    }
}

checkstyle {
    toolVersion = "10.17.0"
    configFile = file("config/checkstyle/checkstyle.xml")
}

spotbugs {
    effort = com.github.spotbugs.snom.Effort.MAX
    reportLevel = com.github.spotbugs.snom.Confidence.LOW
}

tasks.check {
    dependsOn(tasks.jacocoTestCoverageVerification)
}
```

### application.yml baseline

```yaml
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USER}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false

  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${OAUTH2_ISSUER_URI}

management:
  endpoints:
    web:
      exposure:
        include: health,prometheus,info
  endpoint:
    health:
      probes:
        enabled: true
  metrics:
    tags:
      application: ${spring.application.name}

logging:
  structured:
    format:
      console: ecs   # JSON (ECS format) — requires Spring Boot 3.4+

---
spring:
  config:
    activate:
      on-profile: local
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: true
logging:
  structured:
    format:
      console: ""    # Plain text in local dev
```
