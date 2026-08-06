import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'di/injection.dart';

/// Shared entry point for every flavor. Each `main_*.dart` calls this with
/// its own [EnvConfig] so app bootstrapping (DI, bindings) lives in exactly
/// one place instead of being copy-pasted per flavor.
Future<void> bootstrap({
  required Flavor flavor,
  required String apiBaseUrl,
  required String appName,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  EnvConfig.init(flavor: flavor, apiBaseUrl: apiBaseUrl, appName: appName);

  configureDependencies();

  runApp(const ProviderScope(child: App()));
}
