# shellcheck shell=bash
# Stack module: sourced by scripts/scaffold.sh, which consumes every variable below.
# shellcheck disable=SC2034
STACK_TIER="A"
STACK_LABEL="Java 21 / Spring Boot 3 / Maven"
STACK_REQUIRES="curl"
STACK_DIRS="src/main/java/com/example/@@PROJECT_SNAKE@@/api src/main/java/com/example/@@PROJECT_SNAKE@@/domain src/main/java/com/example/@@PROJECT_SNAKE@@/infrastructure src/main/resources src/test/java/com/example/@@PROJECT_SNAKE@@"
CMD_INSTALL="MVN=\$\$([ -x ./mvnw ] && echo ./mvnw || echo mvn); \$\$MVN -B -q dependency:go-offline"
CMD_TEST="MVN=\$\$([ -x ./mvnw ] && echo ./mvnw || echo mvn); \$\$MVN -B test"
CMD_LINT="MVN=\$\$([ -x ./mvnw ] && echo ./mvnw || echo mvn); \$\$MVN -B -q checkstyle:check || echo 'checkstyle not configured — see B3'"
CMD_TYPECHECK="MVN=\$\$([ -x ./mvnw ] && echo ./mvnw || echo mvn); \$\$MVN -B -q compile"
CMD_BUILD="MVN=\$\$([ -x ./mvnw ] && echo ./mvnw || echo mvn); \$\$MVN -B -q package -DskipTests"
CMD_DEV="MVN=\$\$([ -x ./mvnw ] && echo ./mvnw || echo mvn); \$\$MVN -B spring-boot:run"
CMD_AUDIT="MVN=\$\$([ -x ./mvnw ] && echo ./mvnw || echo mvn); \$\$MVN -B org.owasp:dependency-check-maven:check || echo 'dependency-check plugin not configured'"

STACK_DIRS="${STACK_DIRS//@@PROJECT_SNAKE@@/$PROJECT_SNAKE}"

stack_generate() {
  [[ -f "$DEST/pom.xml" ]] && { skip "pom.xml already present"; return 0; }
  $DRY_RUN && { skip "would fetch a project from start.spring.io"; return 0; }
  curl -fsSL "https://start.spring.io/starter.tgz\
?type=maven-project&language=java&bootVersion=3.3.5&javaVersion=21\
&groupId=com.example&artifactId=${PROJECT_KEBAB}&name=${PROJECT_KEBAB}\
&packageName=com.example.${PROJECT_SNAKE}\
&dependencies=web,actuator,validation" \
    | tar -xz -C "$GEN_DIR" >/dev/null 2>&1 || return 1
}
