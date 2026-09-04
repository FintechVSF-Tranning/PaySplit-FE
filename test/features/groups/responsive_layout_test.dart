import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/groups/domain/entities/group_entity.dart';
import 'package:paysplit/features/groups/presentation/widgets/group_list_card.dart';
import 'package:paysplit/features/home/presentation/widgets/actionable_debts_section.dart';
import 'package:paysplit/features/home/presentation/widgets/net_balance_hero_card.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Size size = const Size(375, 667)}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Responsive Layout Tests on Small Screen Sizes', () {
    testWidgets('GroupListCard renders cleanly on iPhone SE (375x667) without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final group = GroupEntity(
        id: 'grp-test-1',
        name: 'Ăn trưa 27/8 tại nhà hàng hải sản',
        memberCount: 3,
        myBalance: -58912,
        isCaptain: true,
        pendingBillCount: 1,
        billSubmissionLocked: true,
        closedAtText: '27/08/2026',
        lastActivity: 'Đã tạm khóa nhận hóa đơn mới cho nhóm',
        lastActivityAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GroupListCard(group: group),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('3 thành viên'), findsOneWidget);
      expect(find.textContaining('1 bill mở'), findsOneWidget);
      expect(find.text('Tạm khóa'), findsOneWidget);
      expect(find.text('Bạn cần trả'), findsOneWidget);
    });

    testWidgets('GroupListCard renders on compact Android width (360x800) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final group = GroupEntity(
        id: 'grp-test-2',
        name: 'Du lịch Đà Lạt mùa hè 2026',
        memberCount: 8,
        myBalance: 12500000,
        isCaptain: false,
        pendingBillCount: 3,
        lastActivity: 'Đã tạo mã QR thanh toán',
        lastActivityAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GroupListCard(group: group),
          ),
          size: const Size(360, 800),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('8 thành viên'), findsOneWidget);
      expect(find.textContaining('3 bill mở'), findsOneWidget);
      expect(find.text('Bạn được nhận'), findsOneWidget);
    });

    testWidgets('GroupListCard renders on narrow 320px width without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final group = GroupEntity(
        id: 'grp-test-3',
        name: 'Nhóm rất dài với tên cực kỳ chi tiết',
        memberCount: 15,
        myBalance: -150000,
        isCaptain: true,
        pendingBillCount: 2,
        billSubmissionLocked: true,
        closedAtText: '27/08/2026',
        lastActivity: 'Đã chốt hóa đơn (tổng 250.000 đ)',
        lastActivityAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GroupListCard(group: group),
          ),
          size: const Size(320, 568),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('15 thành viên'), findsOneWidget);
      expect(find.textContaining('2 bill mở'), findsOneWidget);
    });

    testWidgets('NetBalanceHeroCard renders cleanly on iPhone SE (375x667) without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: NetBalanceHeroCard(
              netAmount: '+15.850.000 đ',
              receivableAmount: '+20.250.000 đ',
              payableAmount: '-4.400.000 đ',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TỔNG SỐ DƯ CÔNG NỢ'), findsOneWidget);
      expect(find.text('Bạn được nhận lại'), findsOneWidget);
    });

    testWidgets('ActionableDebtsSection renders cleanly on iPhone SE (375x667)', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ActionableDebtsSection(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Khoản nợ cần xử lý'), findsOneWidget);
    });
  });
}
