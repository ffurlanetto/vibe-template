# Preset B3 — Frontend (Vue 3 / Angular / React)

> Copy-paste the matching block into the **B3** section of CLAUDE.md.

---

## Vue 3 + Vuetify 3 (or other UI lib)

### Code conventions

- Composition API required: `<script setup lang="ts">` on all components
- State management: Pinia only — no Vuex, no deep props drilling
- No TypeScript `any` — explicit types or strict inference
- Composables (`use*.ts`) for all reusable logic
- One component = one responsibility — split if > 200 lines
- Components do not make HTTP requests directly — go through a store or composable

### Tests

- Framework: Vitest + Vue Test Utils + Testing Library
- Minimum coverage: 80% on composables and stores
- Naming pattern: `[component/composable]_[scenario]_[result]`

### Commands (B4)

```bash
npm install
npm run test:unit          # Vitest
npm run lint               # ESLint
npm run type-check         # tsc --noEmit
npm run build              # Vite build
npm run dev                # Dev server
```

---

## Angular 17+

### Code conventions

- Standalone components only (no NgModules unless necessary)
- Signals for reactive local state
- RxJS only for complex async streams (not for UI state)
- `inject()` for dependency injection (not constructor DI)
- Smart / dumb components: pages are smart, UI components are dumb
- No TypeScript `any` — `strict: true` in tsconfig

### Tests

- Framework: Jest + Angular Testing Library
- Minimal `TestBed` — prefer pure unit tests for services
- Naming pattern: `[Subject]_[Scenario]_[Result]`

### Commands (B4)

```bash
npm install
npm run test               # Jest
npm run lint               # ESLint + Angular ESLint
npm run build              # ng build --configuration production
npm run start              # ng serve
```

---

## React 18+

### Code conventions

- Functional components only
- No TypeScript `any` — `strict: true` in tsconfig
- Global state: Zustand (lightweight) or React Query (server state)
- `use*` hooks for reusable logic
- Avoid unnecessary `useEffect` — prefer derivations
- One component = one responsibility — split if > 150 lines
- No HTTP requests directly in components — use React Query or a dedicated hook

### Tests

- Framework: Vitest + React Testing Library
- Test behavior (what the user sees), not implementation
- Naming pattern: `[component/hook]_[scenario]_[result]`

### Commands (B4)

```bash
npm install
npm run test               # Vitest
npm run lint               # ESLint
npm run type-check         # tsc --noEmit
npm run build              # Vite / Next build
npm run dev                # Dev server
```
