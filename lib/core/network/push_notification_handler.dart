import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/router/notification_route_resolver.dart';
import '../../app/theme/app_colors.dart';
import 'fcm_token_manager.dart';

/// Top-level background message handler for FCM.
/// Must be annotated with `@pragma('vm:entry-point')` so Flutter engine
/// can invoke it in an isolated background Dart VM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'FCM Background message: id=${message.messageId}, type=${message.data['type']}',
  );
}

/// Handles incoming push notifications across all application states:
/// 1. Foreground: Displays in-app banner/SnackBar without disturbing user.
/// 2. Background (click from system tray): Resolves route and navigates.
/// 3. Terminated (cold start from push): Checks initial message and routes.
class PushNotificationHandler {
  PushNotificationHandler._();

  static final PushNotificationHandler instance = PushNotificationHandler._();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  bool _isListening = false;

  /// Đăng ký handler chạy ngầm với Firebase. Cần gọi trước `runApp`.
  static Future<void> initBackgroundHandler() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('initBackgroundHandler warning: $e');
    }
  }

  /// Khởi tạo các listener lắng nghe tin nhắn khi app đang chạy (Foreground & OpenedApp).
  Future<void> setupListeners() async {
    if (_isListening) return;
    _isListening = true;

    try {
      // Đảm bảo FCM token được khởi tạo
      await FCMTokenManager.instance.initialize();

      // 1. Lắng nghe tin nhắn khi App đang ở Foreground
      await _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        _handleForegroundMessage(message);
      });

      // 2. Lắng nghe sự kiện User bấm vào Notification từ thanh thông báo (App ở Background)
      await _messageOpenedAppSubscription?.cancel();
      _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) {
            _handleNotificationClick(message);
          });

      // 3. Kiểm tra nếu App được mở từ trạng thái Terminated do user bấm notification
      await checkInitialMessage();
    } catch (e) {
      debugPrint('PushNotificationHandler.setupListeners error: $e');
    }
  }

  /// Kiểm tra tin nhắn khởi động ban đầu (khi app bị kill và user bấm push để mở)
  Future<void> checkInitialMessage() async {
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state via FCM');
        // Chờ router sẵn sàng một chút rồi điều hướng
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationClick(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('checkInitialMessage error: $e');
    }
  }

  /// Xử lý tin nhắn đến khi app đang mở (Foreground)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM Foreground message received: type=${message.data['type'] ?? 'unknown'}',
    );

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final title = message.notification?.title ?? 'Thông báo mới';
    final body = message.notification?.body ?? '';

    // Hiển thị Material SnackBar in-app tinh tế
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Xem',
          textColor: AppColors.primary,
          onPressed: () => _handleNotificationClick(message),
        ),
      ),
    );
  }

  /// Điều hướng người dùng khi bấm vào thông báo
  void _handleNotificationClick(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    final payload = message.data;

    debugPrint('Resolving route for push notification: type=$type');

    final resolved = NotificationRouteResolver.resolve(
      type: type,
      payload: payload,
    );

    if (resolved != null) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        debugPrint('Navigating from push notification');
        context.go(resolved.path, extra: resolved.extra);
      }
    }
  }

  /// Hủy đăng ký listener
  void dispose() {
    _foregroundSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
    _isListening = false;
  }
}
