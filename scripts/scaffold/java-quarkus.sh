# shellcheck shell=bash
STACK_TIER="A"
STACK_LABEL="Java 21 / Quarkus 3 / Gradle"
STACK_REQUIRES="curl"
STACK_DIRS="src/main/java/com/example/@@PROJECT_SNAKE@@/api src/main/java/com/example/@@PROJECT_SNAKE@@/domain src/main/java/com/example/@@PROJECT_SNAKE@@/infrastructure src/main/resources src/test/java/com/example/@@PROJECT_SNAKE@@"
CMD_INSTALL="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE dependencies --no-daemon -q"
CMD_TEST="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE test --no-daemon"
CMD_LINT="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE check -x test --no-daemon"
CMD_TYPECHECK="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE compileJava --no-daemon"
CMD_BUILD="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE build -x test --no-daemon"
CMD_DEV="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE quarkusDev --no-daemon"
CMD_AUDIT="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE dependencyCheckAnalyze --no-daemon || echo 'dependency-check plugin not configured'"

STACK_DIRS="${STACK_DIRS//@@PROJECT_SNAKE@@/$PROJECT_SNAKE}"

stack_generate() {
  [[ -f "$DEST/build.gradle" || -f "$DEST/build.gradle.kts" ]] && { skip "gradle build file already present"; return 0; }
  $DRY_RUN && { skip "would fetch a project from code.quarkus.io"; return 0; }
  curl -fsSL "https://code.quarkus.io/d\
?b=GRADLE_KOTLIN_DSL&j=21&g=com.example&a=${PROJECT_KEBAB}\
&e=rest-jackson&e=smallrye-health&e=hibernate-validator&e=opentelemetry" \
    -o "$DEST/.quarkus.zip" >/dev/null 2>&1 || return 1
  ( cd "$DEST" && unzip -qo .quarkus.zip && cp -rn "${PROJECT_KEBAB}/." . 2>/dev/null; \
    rm -rf "${PROJECT_KEBAB}" .quarkus.zip ) || return 1
}
