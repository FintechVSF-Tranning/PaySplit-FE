// Default `flutter run` entry point — mirrors the development flavor. Use
// `main_staging.dart` / `main_production.dart` directly (via `-t`) to
// target a different flavor.
import 'bootstrap.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  await bootstrap(
    flavor: Flavor.development,
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://dev-api.paysplit.app/v1',
    ),
    appName: 'PaySplit Dev',
  );
}
