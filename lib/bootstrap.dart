import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/network/push_notification_handler.dart';
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

  // Khởi tạo Firebase SDK (bọc try-catch an toàn cho môi trường test/web)
  try {
    await Firebase.initializeApp();
    await PushNotificationHandler.initBackgroundHandler();
  } catch (e) {
    debugPrint('Firebase.initializeApp warning: $e');
  }

  EnvConfig.init(flavor: flavor, apiBaseUrl: apiBaseUrl, appName: appName);

  configureDependencies();

  runApp(const ProviderScope(child: App()));
}

