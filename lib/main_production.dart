import 'bootstrap.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  await bootstrap(
    flavor: Flavor.production,
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://paysplitbe.vercel.app/api/v1',
    ),
    appName: const String.fromEnvironment('APP_NAME', defaultValue: 'PaySplit'),
    realtimeMode: const String.fromEnvironment(
      'REALTIME_MODE',
      defaultValue: 'auto',
    ),
  );
}
