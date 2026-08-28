import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/app/router/app_routes.dart';
import 'package:paysplit/app/router/group_detail_route_args.dart';
import 'package:paysplit/app/router/notification_route_resolver.dart';
import 'package:paysplit/features/groups/presentation/pages/group_detail_page.dart';
import 'package:paysplit/features/settlement/presentation/providers/settlement_controller.dart';

void main() {
  group('NotificationRouteResolver', () {
    test(
      'bill_bulk_finalize_completed hợp lệ -> route đến Group Detail kèm openBatchId và Tab bills',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'bill_bulk_finalize_completed',
          payload: {'group_id': 'g-123', 'batch_id': 'batch-456'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.groupDetail('g-123'));
        expect(route.extra, isA<GroupDetailRouteArgs>());
        final args = route.extra! as GroupDetailRouteArgs;
        expect(args.openBatchId, 'batch-456');
        expect(args.initialTab, GroupHubTab.bills);
      },
    );

    test('bill_bulk_finalize_completed thiếu group_id -> trả null an toàn', () {
      final route = NotificationRouteResolver.resolve(
        type: 'bill_bulk_finalize_completed',
        payload: {'batch_id': 'batch-456'},
      );

      expect(route, isNull);
    });

    test(
      'payment_submitted có group_id -> route đến Group Detail với Tab debts',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'payment_submitted',
          payload: {'group_id': 'g-123', 'payment_id': 'p-1'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.groupDetail('g-123'));
        expect(route.extra, isA<GroupDetailRouteArgs>());
        final args = route.extra! as GroupDetailRouteArgs;
        expect(args.initialTab, GroupHubTab.debts);
      },
    );

    test(
      'payment_submitted không có group_id -> route đến Settlement Tab receivable',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'payment_submitted',
          payload: {'payment_id': 'p-1'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.settlement);
        expect(route.extra, SettlementTab.receivable);
      },
    );

    test(
      'payment_confirmed có group_id -> route đến Group Detail với Tab debts',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'payment_confirmed',
          payload: {'group_id': 'g-123'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.groupDetail('g-123'));
        final args = route.extra! as GroupDetailRouteArgs;
        expect(args.initialTab, GroupHubTab.debts);
      },
    );

    test(
      'payment_rejected có group_id -> route đến Group Detail với Tab debts',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'payment_rejected',
          payload: {'group_id': 'g-123'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.groupDetail('g-123'));
        final args = route.extra! as GroupDetailRouteArgs;
        expect(args.initialTab, GroupHubTab.debts);
      },
    );

    test(
      'debt_reminded không có group_id -> route đến Settlement Tab payable',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'debt_reminded',
          payload: {'debt_id': 'd-1'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.settlement);
        expect(route.extra, SettlementTab.payable);
      },
    );

    test(
      'bill_finalized có bill_id -> route đến Bill Detail kèm extra map',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'bill_finalized',
          payload: {'bill_id': 'b-123', 'group_id': 'g-456'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.billDetail);
        expect(route.extra, isA<Map<String, dynamic>>());
        final map = route.extra! as Map<String, dynamic>;
        expect(map['billId'], 'b-123');
        expect(map['groupId'], 'g-456');
      },
    );

    test(
      'group_invitation có group_id -> route đến Group Detail với Tab bills',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'group_invitation',
          payload: {'group_id': 'g-789'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.groupDetail('g-789'));
        final args = route.extra! as GroupDetailRouteArgs;
        expect(args.initialTab, GroupHubTab.bills);
      },
    );

    test(
      'FCM payload: new_bill có bill_id và group_id -> route đến Bill Detail',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'new_bill',
          payload: {
            'type': 'new_bill',
            'group_id': 'g-fcm-1',
            'bill_id': 'b-fcm-1',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.billDetail);
        final map = route.extra! as Map<String, dynamic>;
        expect(map['billId'], 'b-fcm-1');
        expect(map['groupId'], 'g-fcm-1');
      },
    );

    test(
      'FCM payload: payment_reminder có group_id và bill_id -> route đến Group Detail tab debts',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'payment_reminder',
          payload: {
            'type': 'payment_reminder',
            'group_id': 'g-fcm-2',
            'bill_id': 'b-fcm-2',
            'amount': '150000',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.groupDetail('g-fcm-2'));
        expect(route.extra, isA<GroupDetailRouteArgs>());
        final args = route.extra! as GroupDetailRouteArgs;
        expect(args.initialTab, GroupHubTab.debts);
      },
    );

    test(
      'FCM payload: bill_updated có bill_id -> route đến Bill Detail',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'bill_updated',
          payload: {
            'type': 'bill_updated',
            'group_id': 'g-fcm-3',
            'bill_id': 'b-fcm-3',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.billDetail);
        final map = route.extra! as Map<String, dynamic>;
        expect(map['billId'], 'b-fcm-3');
        expect(map['groupId'], 'g-fcm-3');
      },
    );

    test('loại thông báo không được hỗ trợ và không có ID nhận diện -> trả null', () {
      final route = NotificationRouteResolver.resolve(
        type: 'unknown_type',
        payload: {'foo': 'bar'},
      );

      expect(route, isNull);
    });

    test('payload rỗng không gây crash và trả null', () {
      final route = NotificationRouteResolver.resolve(
        type: 'bill_bulk_finalize_completed',
        payload: {},
      );

      expect(route, isNull);
    });
  });
}

