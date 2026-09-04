import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/network/push_notification_handler.dart';
import 'core/realtime/realtime_ports.dart';
import 'di/injection.dart';
import 'features/auth/presentation/providers/auth_controller.dart';

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// Shared entry point for every flavor. Each `main_*.dart` calls this with
/// its own [EnvConfig] so app bootstrapping (DI, bindings) lives in exactly
/// one place instead of being copy-pasted per flavor.
Future<void> bootstrap({
  required Flavor flavor,
  required String apiBaseUrl,
  required String appName,

  /// Lựa chọn rollout của từng flavor: `auto`, `user` hoặc `legacy`. Bắt buộc
  /// khai báo, để mỗi flavor nói rõ mình đang ở nấc nào thay vì thừa hưởng im
  /// lặng một mặc định.
  required String realtimeMode,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && flavor != Flavor.production) {
    HttpOverrides.global = _DevHttpOverrides();
  }

  // Khởi tạo Firebase SDK (bọc try-catch an toàn cho môi trường test/web)
  try {
    await Firebase.initializeApp();
    await PushNotificationHandler.initBackgroundHandler();
  } catch (e) {
    debugPrint('Firebase.initializeApp warning: $e');
  }

  EnvConfig.init(
    flavor: flavor,
    apiBaseUrl: apiBaseUrl,
    appName: appName,
    realtimeMode: realtimeMode,
  );

  configureDependencies();

  runApp(
    ProviderScope(
      overrides: [
        // Nối cổng phiên của `core/realtime` vào feature auth ở đúng composition
        // root. Nhờ vậy tầng realtime không phải import tầng presentation của
        // một feature, mà vẫn dừng/khởi động stream theo trạng thái đăng nhập.
        realtimeSignedInProvider.overrideWith(
          (ref) => ref.watch(authControllerProvider).valueOrNull != null,
        ),
      ],
      child: const App(),
    ),
  );
}
