enum Flavor { development, staging, production }

/// App-wide environment configuration, chosen by the `main_*.dart` entry
/// point (see [Flavor]) and overridable via `--dart-define`.
class EnvConfig {
  EnvConfig._();

  static late Flavor flavor;
  static late String apiBaseUrl;
  static late String appName;
  static String realtimeMode = 'auto';

  static void init({
    required Flavor flavor,
    required String apiBaseUrl,
    required String appName,
    String realtimeMode = 'auto',
  }) {
    EnvConfig.flavor = flavor;
    EnvConfig.apiBaseUrl = apiBaseUrl;
    EnvConfig.appName = appName;
    EnvConfig.realtimeMode = realtimeMode;
  }

  static bool get isProduction => flavor == Flavor.production;
  static bool get isDevelopment => flavor == Flavor.development;
}
