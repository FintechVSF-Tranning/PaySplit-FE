import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/app/router/app_routes.dart';
import 'package:paysplit/app/router/group_detail_route_args.dart';
import 'package:paysplit/app/router/notification_route_resolver.dart';
import 'package:paysplit/features/groups/presentation/pages/group_detail_page.dart';

void main() {
  group('NotificationRouteResolver', () {
    test(
      'bill_bulk_finalize_completed hợp lệ -> route đến Group Detail kèm openBatchId',
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
      'bill_bulk_finalize_completed thiếu batch_id -> vẫn route đến group nhưng openBatchId null',
      () {
        final route = NotificationRouteResolver.resolve(
          type: 'bill_bulk_finalize_completed',
          payload: {'group_id': 'g-123'},
        );

        expect(route, isNotNull);
        expect(route!.path, AppRoutes.groupDetail('g-123'));
        final args = route.extra! as GroupDetailRouteArgs;
        expect(args.openBatchId, isNull);
      },
    );

    test('loại thông báo không được hỗ trợ -> trả null', () {
      final route = NotificationRouteResolver.resolve(
        type: 'unknown_type',
        payload: {'group_id': 'g-1'},
      );

      expect(route, isNull);
    });

    test('payload rỗng hoặc sai kiểu không gây crash', () {
      final route = NotificationRouteResolver.resolve(
        type: 'bill_bulk_finalize_completed',
        payload: {},
      );

      expect(route, isNull);
    });
  });
}
