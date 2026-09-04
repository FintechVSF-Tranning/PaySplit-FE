# Repository Guidelines

## Project Structure & Module Organization

PaySplit is a Flutter application organized with Clean Architecture and feature-first modules. Application code lives in `lib/`: shared infrastructure is under `core/`, app-wide routing and themes are under `app/`, dependency injection is configured in `di/`, and business features live in `features/<feature>/`. Each feature should separate `data/`, `domain/`, and `presentation/`; keep the domain layer independent of Flutter, Dio, and JSON concerns. Environment entry points are `lib/main_development.dart`, `lib/main_staging.dart`, and `lib/main_production.dart`. Tests mirror application concerns under `test/`. Static images and icons belong in `assets/images/` and `assets/icons/`; platform configuration is in `android/` and `ios/`.

## Build, Test, and Development Commands

- `flutter pub get` installs dependencies.
- `dart run build_runner build --delete-conflicting-outputs` regenerates Freezed, JSON, Retrofit, Riverpod, and Injectable output. Generated files are ignored by Git.
- `flutter run` starts the development flavor.
- `flutter run -t lib/main_staging.dart` starts staging. Add `--dart-define=API_BASE_URL=<url>` to override the API endpoint.
- `flutter analyze` runs the configured static analysis.
- `flutter test` runs all unit and widget tests; use `flutter test test/features/auth/login_usecase_test.dart` for one file.
- `dart format .` formats Dart source and tests.

## Coding Style & Naming Conventions

Use two-space Dart indentation and the rules in `analysis_options.yaml`, including single quotes, relative imports, explicit return types, and safely handled unawaited futures. Format before submitting. Name files in `snake_case.dart`, types in `UpperCamelCase`, and members in `lowerCamelCase`. Follow existing suffixes such as `UserEntity`, `BillModel`, `LoginUseCase`, and `AuthRepositoryImpl`. Keep API models in `data/`; expose entities and repository interfaces from `domain/`.

## Testing Guidelines

Use `flutter_test` for unit/widget tests and `mocktail` for collaborators. Name files `*_test.dart` and write behavior-focused test descriptions. Add domain tests for success and failure paths, and widget tests for important rendered states and interactions. No numeric coverage threshold is configured; new behavior should still include targeted regression tests.

## Commit & Pull Request Guidelines

Recent history primarily follows Conventional Commits (`feat:`, `docs:`, `chore:`). Keep subjects imperative, concise, and scoped to one change. Pull requests should explain the motivation and implementation, list verification commands, link relevant issues, and include screenshots or recordings for UI changes. Note API-contract, flavor, or code-generation impacts explicitly, and do not commit secrets or generated files.
