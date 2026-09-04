import 'bootstrap.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  await bootstrap(
    flavor: Flavor.development,
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080/api/v1',
    ),
    appName: const String.fromEnvironment(
      'APP_NAME',
      defaultValue: 'PaySplit Dev',
    ),
    realtimeMode: const String.fromEnvironment(
      'REALTIME_MODE',
      defaultValue: 'auto',
    ),
  );
}
