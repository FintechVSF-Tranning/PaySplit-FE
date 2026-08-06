import 'bootstrap.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  await bootstrap(
    flavor: Flavor.staging,
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://staging-api.paysplit.app/v1',
    ),
    appName: 'PaySplit Staging',
  );
}
