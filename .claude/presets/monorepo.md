# Preset B3 — Monorepo (Nx / Turborepo)

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

> **Choose one tool and stick with it.** This preset covers both; remove the inapplicable section.

---

## Nx (recommended for complex / enterprise monorepos)

### Code conventions

- Each app and library has a `project.json` defining its targets (`build`, `test`, `lint`)
- **Mandatory tags** on every project in `project.json`: `type:app`, `type:lib`, `scope:<domain>`
- **Boundary rules** via `@nx/enforce-module-boundaries`: an app cannot import from another app
- Public libraries export only via their `index.ts` — no internal path imports
- `nx affected` to limit CI operations to projects impacted by a change
- No relative imports between projects — use TypeScript path aliases defined in `tsconfig.base.json`
- Nx generators (`nx generate`) to create all new artifacts — never by hand

### Typical structure (Nx)

```
<monorepo>/
├── nx.json                           # Nx config (task runners, affected, cache)
├── tsconfig.base.json                # Shared path aliases
├── apps/
│   ├── <web-app>/                   # Frontend application
│   ├── <api-app>/                   # Backend application
│   └── <mobile-app>/                # Mobile application
├── libs/
│   ├── shared/
│   │   ├── ui/                      # Shared UI components (type:lib, scope:shared)
│   │   ├── utils/                   # Pure utilities
│   │   └── types/                   # Shared types
│   ├── <domain>/
│   │   ├── data-access/             # API calls, stores (type:lib, scope:<domain>)
│   │   ├── feature-<feature>/       # Smart components with logic
│   │   └── ui/                      # Domain dumb components
│   └── backend/
│       ├── <module>/                # Shared NestJS modules
│       └── database/                # Database access
└── tools/
    └── generators/                   # Custom Nx generators
```

### Commands (B4) — Nx

```bash
# Install
npm install

# Test — affected projects only
npx nx affected --target=test --base=main

# Test — specific project
npx nx test <project-name>

# Lint — affected projects only
npx nx affected --target=lint --base=main

# Build — affected projects only
npx nx affected --target=build --base=main

# Dependency graph
npx nx graph

# Run locally (specific app)
npx nx serve <app-name>
```

---

## Turborepo (recommended for frontend / npm workspace monorepos)

### Code conventions

- Each package has its own `package.json` with standardized scripts (`build`, `test`, `lint`, `dev`)
- `turbo.json` defines the pipeline: task dependencies, what is cacheable
- Internal packages prefixed with `@<org>/` (e.g. `@acme/ui`, `@acme/utils`)
- No direct imports of internal paths — use exports declared in `package.json`
- `workspace:*` in internal dependencies (pnpm) or `*` (npm/yarn workspaces)
- Versioning with `changesets` — never manual version bumps

### Typical structure (Turborepo)

```
<monorepo>/
├── turbo.json                        # Task pipeline + cache
├── package.json                      # Root workspace
├── apps/
│   ├── web/                         # Next.js / Vite app
│   │   └── package.json
│   └── api/                         # Backend app
│       └── package.json
└── packages/
    ├── ui/                           # @<org>/ui — shared components
    │   ├── src/
    │   ├── package.json
    │   └── tsconfig.json
    ├── utils/                        # @<org>/utils — pure utilities
    ├── config-typescript/            # Shared base tsconfig
    ├── config-eslint/                # Shared ESLint config
    └── config-tailwind/              # Shared Tailwind config (if applicable)
```

### Commands (B4) — Turborepo

```bash
# Install (pnpm recommended with Turborepo)
pnpm install

# Test — all packages in parallel
pnpm turbo test

# Test — specific package
pnpm turbo test --filter=<package-name>

# Lint
pnpm turbo lint

# Build (respects pipeline dependencies)
pnpm turbo build

# Build — package and its dependencies only
pnpm turbo build --filter=<app-name>...

# Dev — all apps
pnpm turbo dev
```

---

## Common standards (Nx and Turborepo)

### CI — Build optimization

- Use remote cache: **Nx Cloud** (Nx) or **Vercel Remote Cache** (Turborepo)
- In CI: only build/test projects affected by the change (`affected` / `--filter`)
- Parallelize CI jobs per project or project group

### Version management

- Semantic versioning with **Changesets** (`@changesets/cli`)
- One changelog per publishable package
- Automated release PR via GitHub Actions + Changesets bot

### Commit conventions in a monorepo

Format: `type(scope): description`
- `scope` = name of the affected package/app (e.g. `feat(ui): add Button component`)
- If multiple packages: use the highest-level scope (`feat(shared): ...`)

### Golden rule

> A monorepo is not an excuse to mix everything together.
> Each package must have a single responsibility and clear boundaries.
> If two packages always change together, they should probably be merged into one.
