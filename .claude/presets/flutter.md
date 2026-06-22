# Preset B3 — Flutter / Dart

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Architecture: **BLoC / Cubit** (flutter_bloc) or **Riverpod** — pick one, not both
- Strict separation: UI (widgets) / logic (BLoC / Cubit) / data (repositories)
- No business logic in widgets — delegate to BLoC or provider
- `const` widgets everywhere possible — improves rebuild performance
- One widget = one responsibility — split if > 100 lines in `build()`
- `dart:io` and native plugins only in the repository layer
- No `print()` in production — use the `logger` package
- Explicit types on public class members — no implicit inference on signatures

### State management (BLoC)

- `Cubit` for simple states (toggle, form), `BLoC` for complex events
- States are immutable — `copyWith()` for transitions
- Global `BlocObserver` for transition logging in dev
- Never call repositories directly from a widget — always via BLoC

### Tests

- Framework: `flutter_test` (built-in) + `mocktail` for mocks + `bloc_test`
- Minimum coverage: 80% on BLoC/Cubit and repositories
- `WidgetTester` for widget tests — test behavior, not implementation details
- Integration tests: `integration_test` package — target critical flows
- Naming pattern: `[Subject]_[Scenario]_[Result]`

### Lint & Quality

- `flutter analyze` — zero warnings
- `dart format --set-exit-if-changed .` — formatting required
- `very_good_analysis` or `flutter_lints` as base rule set
- `custom_lint` for project-specific business rules if needed

### Commands (B4)

```bash
# Install
flutter pub get

# Test
flutter test --coverage

# Lint
flutter analyze
dart format --set-exit-if-changed .

# Build
flutter build apk --release           # Android
flutter build ipa --release           # iOS

# Run locally
flutter run
```

### Typical structure

```
lib/
├── main.dart
├── app.dart                           # MaterialApp / CupertinoApp + routing
├── core/
│   ├── di/                           # Dependency injection (get_it)
│   ├── router/                       # GoRouter config
│   ├── theme/                        # ThemeData
│   └── utils/
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/          # API clients, local DB
│       │   ├── models/               # DTOs with fromJson/toJson
│       │   └── repositories/         # Implementations
│       ├── domain/
│       │   ├── entities/             # Pure entities (no fromJson)
│       │   ├── repositories/         # Interfaces
│       │   └── usecases/             # Use cases (optional)
│       └── presentation/
│           ├── bloc/                 # BLoC / Cubit + states + events
│           ├── pages/                # Screens
│           └── widgets/              # Feature-specific widgets
└── shared/
    ├── widgets/                      # Reusable UI components
    └── extensions/                   # Dart extensions
test/
└── features/
    └── <feature>/
        ├── bloc/
        └── data/
integration_test/
└── app_test.dart
```

### Recommended dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_bloc: ^8.1.0       # State management
  go_router: ^13.0.0         # Declarative navigation
  dio: ^5.4.0                # HTTP client
  freezed_annotation: ^2.4.0 # Immutability + copyWith
  json_annotation: ^4.8.0    # JSON serialization
  get_it: ^7.6.0             # Dependency injection
  logger: ^2.0.0             # Structured logging
  flutter_secure_storage: ^9.0.0  # Secrets (tokens)

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  very_good_analysis: ^6.0.0
```
