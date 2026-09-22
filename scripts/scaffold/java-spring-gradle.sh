# shellcheck shell=bash
# Stack module: sourced by scripts/scaffold.sh, which consumes every variable below.
# shellcheck disable=SC2034
STACK_TIER="A"
STACK_LABEL="Java 21 / Spring Boot 3 / Gradle"
STACK_REQUIRES="curl"
STACK_DIRS="src/main/java/com/example/@@PROJECT_SNAKE@@/api src/main/java/com/example/@@PROJECT_SNAKE@@/domain src/main/java/com/example/@@PROJECT_SNAKE@@/infrastructure src/main/resources src/test/java/com/example/@@PROJECT_SNAKE@@"
CMD_INSTALL="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE dependencies --no-daemon -q"
CMD_TEST="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE test --no-daemon"
CMD_LINT="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE check -x test --no-daemon"
CMD_TYPECHECK="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE compileJava --no-daemon"
CMD_BUILD="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE build -x test --no-daemon"
CMD_DEV="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE bootRun --no-daemon"
CMD_AUDIT="GRADLE=\$\$([ -x ./gradlew ] && echo ./gradlew || echo gradle); \$\$GRADLE dependencyCheckAnalyze --no-daemon || echo 'dependency-check plugin not configured'"

STACK_DIRS="${STACK_DIRS//@@PROJECT_SNAKE@@/$PROJECT_SNAKE}"

stack_generate() {
  [[ -f "$DEST/build.gradle.kts" ]] && { skip "build.gradle.kts already present"; return 0; }
  $DRY_RUN && { skip "would fetch a project from start.spring.io"; return 0; }
  curl -fsSL "https://start.spring.io/starter.tgz\
?type=gradle-project-kotlin&language=java&bootVersion=3.3.5&javaVersion=21\
&groupId=com.example&artifactId=${PROJECT_KEBAB}&name=${PROJECT_KEBAB}\
&packageName=com.example.${PROJECT_SNAKE}\
&dependencies=web,actuator,validation" \
    | tar -xz -C "$DEST" >/dev/null 2>&1 || return 1
}

# Spring Boot application code is identical whatever the build tool: reuse the
# Maven skeleton and let the generator own the build file.
stack_overlay() {
  # Spring Boot application code is identical whatever the build tool.
  copy_tree_if_absent "$TEMPLATE_DIR/templates/skeleton/java-spring/src" "$DEST/src"
  # ...only the build files differ, and they are the fallback for a generator
  # that could not be reached.
  copy_tree_if_absent "$SKELETON" "$DEST"
}
