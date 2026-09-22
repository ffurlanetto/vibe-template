# shellcheck shell=bash
STACK_TIER="A"
STACK_LABEL="Node.js 22 / NestJS"
STACK_REQUIRES="npm"
STACK_DIRS="src/health src/example src/common/config test"
# npm 10.9.x can fail on the Nest CLI's vitest peer set (arborist #loadPeerSet);
# the legacy resolver is the documented escape hatch, not a silent default.
CMD_INSTALL="npm ci || npm install || npm install --legacy-peer-deps"
CMD_TEST="npm run test
npm run test:e2e"
CMD_LINT="npm run lint"
CMD_TYPECHECK="npx tsc --noEmit"
CMD_BUILD="npm run build"
CMD_DEV="npm run start:dev"
CMD_AUDIT="npm audit --audit-level=high"

stack_generate() {
  [[ -f "$DEST/package.json" ]] && { skip "package.json already present"; return 0; }
  $DRY_RUN && { skip "would run nest new"; return 0; }
  # `new .` would name the project after the directory; name it explicitly.
  ( cd "$DEST" && npx --yes @nestjs/cli@latest new "$PROJECT_KEBAB" --directory . \
      --package-manager npm --skip-git --skip-install >/dev/null 2>&1 ) || return 1
}

stack_overlay() {
  copy_tree_if_absent "$SKELETON" "$DEST"
  $DRY_RUN && return 0

  # The generator owns src/app.module.ts and src/main.ts. Register the skeleton
  # modules and the global validation pipe in them — boilerplate, not project code.
  python3 - "$DEST" <<'PY'
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])

module = root / "src" / "app.module.ts"
if module.exists():
    text = module.read_text(encoding="utf-8")
    if "HealthModule" not in text:
        text = ("import { ExampleModule } from './example/example.module';\n"
                "import { HealthModule } from './health/health.module';\n") + text
        text = re.sub(r"imports:\s*\[([^\]]*)\]",
                      lambda m: "imports: [HealthModule, ExampleModule%s]" % (
                          ", " + m.group(1).strip() if m.group(1).strip() else ""),
                      text, count=1)
        if "imports:" not in text:
            text = text.replace("@Module({", "@Module({\n  imports: [HealthModule, ExampleModule],", 1)
        module.write_text(text, encoding="utf-8")

main = root / "src" / "main.ts"
if main.exists():
    text = main.read_text(encoding="utf-8")
    if "ValidationPipe" not in text:
        # Reject unknown and invalid fields at the boundary (AGENTS.md A5).
        text = text.replace("import { NestFactory }",
                            "import { ValidationPipe } from '@nestjs/common';\nimport { NestFactory }", 1)
        text = re.sub(r"(const app = await NestFactory\.create\([^\n]*\);\n)",
                      r"\1  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }));\n",
                      text, count=1)
        main.write_text(text, encoding="utf-8")
PY

  # Declare the extra dependencies without installing: a partial install on top
  # of `nest new --skip-install` leaves npm's tree inconsistent. `make install`
  # resolves everything in one pass. Versions pinned (AGENTS.md A13).
  ( cd "$DEST" \
    && npm pkg set dependencies.class-validator="^0.14.1" >/dev/null 2>&1 \
    && npm pkg set dependencies.class-transformer="^0.5.1" >/dev/null 2>&1 \
    && npm pkg set devDependencies.supertest="^7.0.0" >/dev/null 2>&1 \
    && npm pkg set devDependencies.@types/supertest="^6.0.2" >/dev/null 2>&1 ) || \
    warn "could not declare class-validator/supertest in package.json"
}
