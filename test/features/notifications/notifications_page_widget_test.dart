import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/notifications/domain/entities/notification_entity.dart';
import 'package:paysplit/features/notifications/presentation/pages/notifications_page.dart';
import 'package:paysplit/features/notifications/presentation/providers/notifications_notifier.dart';

class _FakeNotificationsNotifier extends NotificationsNotifier {
  _FakeNotificationsNotifier(List<NotificationEntity> items) {
    state = NotificationsState(
      items: items,
      unreadCount: items.where((n) => !n.isRead).length,
      totalItems: items.length,
      hasMore: false,
    );
  }

  int refreshCalls = 0;

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> markAllAsRead() async {
    final updated = state.items
        .map((n) => n.copyWith(readAt: DateTime.now()))
        .toList();
    state = state.copyWith(items: updated, unreadCount: 0);
  }
}

void main() {
  group('NotificationsPage Widget Tests', () {
    testWidgets('không tải lại trang đầu ngay sau lần tải của provider', (
      tester,
    ) async {
      final notifier = _FakeNotificationsNotifier([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [notificationsProvider.overrideWith((ref) => notifier)],
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pump();

      expect(notifier.refreshCalls, 0);
    });

    testWidgets('Renders header, filter tabs, and notification list properly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockItems = [
        NotificationEntity(
          id: 'n1',
          userId: 'u1',
          type: 'debt_reminder',
          title: 'Nhắc nợ',
          body: 'Tin đã nhắc bạn thanh toán 150.000 đ',
          payload: const {'bill_id': 'b1'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        NotificationEntity(
          id: 'n2',
          userId: 'u1',
          type: 'bill_finalized',
          title: 'Hóa đơn đã chốt',
          body: 'Hóa đơn Lẩu gà lá é đã chốt',
          payload: const {'bill_id': 'b2'},
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          readAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith(
              (ref) => _FakeNotificationsNotifier(mockItems),
            ),
          ],
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Header & Tabs
      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Tất cả (2)'), findsOneWidget);
      expect(find.text('Chưa đọc (1)'), findsOneWidget);
      expect(find.text('Đọc tất cả'), findsOneWidget);

      // Notification Items
      expect(find.text('Nhắc nợ'), findsOneWidget);
      expect(find.text('Tin đã nhắc bạn thanh toán 150.000 đ'), findsOneWidget);
      expect(find.text('Hóa đơn đã chốt'), findsOneWidget);

      // Tap on "Đọc tất cả"
      await tester.tap(find.text('Đọc tất cả'));
      await tester.pumpAndSettle();

      // Check unread count is 0
      expect(find.text('Chưa đọc (0)'), findsOneWidget);
    });

    testWidgets('Renders empty state when no notifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith(
              (ref) => _FakeNotificationsNotifier([]),
            ),
          ],
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hộp thư thông báo trống'), findsOneWidget);
    });

    testWidgets(
      'Automatically localizes legacy English notification strings on display',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final legacyItems = [
          NotificationEntity.fromJson({
            'id': 'legacy-1',
            'user_id': 'u1',
            'type': 'payment_submitted',
            'title': 'Payment proof submitted',
            'body': 'A payment proof is waiting for your confirmation',
            'payload': {'group_id': 'g1'},
            'created_at': DateTime.now().toIso8601String(),
          }),
          NotificationEntity.fromJson({
            'id': 'legacy-2',
            'user_id': 'u1',
            'type': 'payment_created',
            'title': 'PaySplit update',
            'body': 'payment created',
            'payload': {'group_id': 'g1'},
            'created_at': DateTime.now().toIso8601String(),
          }),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notificationsProvider.overrideWith(
                (ref) => _FakeNotificationsNotifier(legacyItems),
              ),
            ],
            child: const MaterialApp(home: NotificationsPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Payment proof submitted'), findsNothing);
        expect(find.text('Minh chứng thanh toán mới'), findsOneWidget);
        expect(
          find.text('Có minh chứng chuyển tiền mới đang chờ bạn xác nhận.'),
          findsOneWidget,
        );

        expect(find.text('PaySplit update'), findsNothing);
        expect(find.text('Yêu cầu thanh toán mới'), findsOneWidget);
        expect(
          find.text('Đã tạo mã thanh toán VietQR cho khoản nợ.'),
          findsOneWidget,
        );
      },
    );
  });
}
