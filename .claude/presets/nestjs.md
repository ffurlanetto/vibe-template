# Preset B3 — Node.js / NestJS

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Strict NestJS modular architecture: each domain = one module (`@Module`)
- Dependency injection via `@Injectable()` — never manual instantiation
- Thin controllers: delegate immediately to the service, no business logic
- Services = pure business logic — no direct access to the HTTP request
- Repositories via TypeORM / Prisma — no raw SQL (except documented performance queries)
- DTOs validated with `class-validator` + `class-transformer` on all inputs
- `Pipes` for transformation and validation, `Guards` for authentication, `Interceptors` for cross-cutting concerns
- No TypeScript `any` — `strict: true` in tsconfig
- Environment variables via `@nestjs/config` with Joi / Zod validation schema
- Logging via NestJS `Logger` (wrapped) or `pino` — never `console.log`

### Tests

- Framework: Jest + Supertest (HTTP integration)
- Unit tests: `@nestjs/testing` with `Test.createTestingModule()`
- Integration tests: real database via Docker Compose
- Minimum coverage: 80% (`jest --coverage`)
- Mocks: `jest.fn()` at system boundaries — no mocking of business logic
- Naming pattern: `[Subject]_[Scenario]_[Result]`

### Lint & Quality

- ESLint with `@typescript-eslint/recommended` — zero warnings
- Prettier for formatting
- `tsc --noEmit` — zero type errors
- `nest build` must pass without warnings

### Commands (B4)

```bash
# Install
npm install

# Test
npm run test                          # Jest unit tests
npm run test:e2e                      # E2E / integration tests
npm run test:cov                      # Coverage

# Lint
npm run lint                          # ESLint + Prettier
npm run format:check                  # Prettier check

# Type check
npx tsc --noEmit

# Build
npm run build                         # nest build

# Run locally
npm run start:dev                     # Watch mode
```

### Typical structure

```
src/
├── main.ts                           # NestJS bootstrap
├── app.module.ts                     # Root module
├── config/
│   ├── configuration.ts              # Typed configuration schema
│   └── validation.schema.ts          # Joi / Zod validation
├── <module>/
│   ├── <module>.module.ts
│   ├── <module>.controller.ts        # HTTP routes
│   ├── <module>.service.ts           # Business logic
│   ├── <module>.repository.ts        # Data access
│   ├── dto/
│   │   ├── create-<entity>.dto.ts
│   │   └── update-<entity>.dto.ts
│   └── entities/
│       └── <entity>.entity.ts        # TypeORM / Prisma entity
├── shared/
│   ├── guards/                       # Auth guards (JWT, roles)
│   ├── interceptors/                 # Logging, response transform
│   ├── filters/                      # Exception filters
│   └── pipes/                        # Validation pipes
test/
├── <module>/
│   ├── <module>.controller.spec.ts
│   └── <module>.service.spec.ts
└── app.e2e-spec.ts
```

### Recommended dependencies

```bash
# Core
npm install @nestjs/common @nestjs/core @nestjs/platform-express reflect-metadata rxjs

# Config
npm install @nestjs/config joi

# Auth
npm install @nestjs/jwt @nestjs/passport passport passport-jwt bcryptjs
npm install -D @types/passport-jwt @types/bcryptjs

# Validation
npm install class-validator class-transformer

# DB (choose one)
npm install @nestjs/typeorm typeorm pg          # TypeORM + PostgreSQL
# npm install @prisma/client && npx prisma init # Prisma (alternative)

# Logging
npm install nestjs-pino pino-http pino-pretty

# Dev
npm install -D @nestjs/testing @types/supertest supertest jest ts-jest
```
