# Preset B3 — React Native (Expo or CLI)

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Functional components only — no class components
- No TypeScript `any` — `strict: true` in tsconfig
- Navigation: `React Navigation v6+` — no custom navigation
- Global state: Zustand (lightweight client state) + React Query / TanStack Query (server state)
- `use*` hooks for all reusable logic — a component contains no business logic
- One component = one responsibility — split if > 150 lines
- Styles: `StyleSheet.create()` — no inline styles (except justified dynamic cases)
- No HTTP requests directly in components — use React Query or a dedicated hook
- `expo-secure-store` or `react-native-keychain` for tokens — never AsyncStorage for sensitive data
- Logging: `console.log` forbidden in production — use a crash reporting service (Sentry)

### Tests

- Framework: Jest + React Native Testing Library
- Test user-visible behavior — not implementation details
- Minimum coverage: 70% on hooks and utilities (pure UI components are often less critical)
- Mocks: `@react-native-async-storage/async-storage/jest/setup` and native mocks provided by Expo / RN
- Naming pattern: `[component/hook]_[scenario]_[result]`
- E2E tests: Detox (if required) — target critical flows only

### Lint & Quality

- ESLint with `@react-native/eslint-config` or `expo/eslint-config-expo`
- Prettier for formatting
- `tsc --noEmit` — zero type errors
- `expo-doctor` (Expo) or `npx react-native doctor` for environment issues

### Commands (B4)

```bash
# Install
npm install  # or: yarn install / pnpm install

# Test
npm run test                          # Jest
npm run test:coverage                 # Coverage

# Lint
npm run lint                          # ESLint
npx tsc --noEmit                      # Type check

# Dev
npx expo start                        # Expo
# npx react-native start              # React Native CLI

# Build (Expo)
npx expo build:ios
npx expo build:android
# or EAS Build:
npx eas build --platform all
```

### Typical structure

```
src/
├── app/                              # Expo Router (file-based routing) or
├── navigation/                       # React Navigation (stack/tab/drawer)
│   └── RootNavigator.tsx
├── screens/
│   └── <Feature>/
│       ├── <Feature>Screen.tsx       # Page component (navigation + layout)
│       └── components/              # Screen-specific components
├── components/                       # Shared UI components
│   └── <Component>/
│       ├── index.tsx
│       └── <Component>.test.tsx
├── hooks/
│   ├── use<Feature>.ts              # Reusable logic
│   └── use<Feature>.test.ts
├── stores/                           # Zustand stores
│   └── <feature>.store.ts
├── api/                              # API layer (React Query + fetch/axios)
│   ├── client.ts                    # Axios / fetch base URL config
│   └── <resource>.api.ts
├── types/                            # Shared TypeScript types
└── utils/                            # Pure utilities
tests/
└── __mocks__/                        # Native mocks
```

### Mobile-specific considerations

- **Deep linking**: configure `linking` in React Navigation from day one
- **Keyboard handling**: `KeyboardAvoidingView` on all forms
- **Accessibility**: `accessibilityLabel` on all interactive elements
- **Performance**: `useMemo` / `useCallback` at `FlatList` boundaries
- **Offline**: define offline behavior at design time (React Query + cache)
- **Permissions**: request permissions at point of use, never at startup
