import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/home/domain/entities/home_group_item_entity.dart';
import 'package:paysplit/features/home/presentation/pages/home_page.dart';
import 'package:paysplit/features/home/presentation/providers/home_groups_provider.dart';
import 'package:paysplit/features/home/presentation/widgets/actionable_debts_section.dart';
import 'package:paysplit/features/home/presentation/widgets/my_groups_carousel.dart';
import 'package:paysplit/features/home/presentation/widgets/net_balance_hero_card.dart';
import 'package:paysplit/features/home/presentation/widgets/recent_activity_timeline.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('HomePage renders all 5 main sections and header', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeGroupsProvider.overrideWith(
              (ref) => Future.value([
                const HomeGroupItemEntity(
                  id: '1',
                  name: 'Phòng Dev Cty',
                  currency: 'VND',
                  callerRole: 'captain',
                  activeMemberCount: 5,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('Xin chào,'), findsOneWidget);
      expect(find.text('Bạn'), findsOneWidget);

      // 2. Net Balance Hero Card
      expect(find.byType(NetBalanceHeroCard), findsOneWidget);
      expect(find.text('TỔNG SỐ DƯ CÔNG NỢ'), findsOneWidget);
      expect(find.text('+850.000 đ'), findsOneWidget);
      expect(find.text('Bạn được nhận lại'), findsOneWidget);
      expect(find.text('Trả VietQR'), findsOneWidget);
      expect(find.text('Quét bill'), findsOneWidget);
      expect(find.text('Tạo nhóm'), findsWidgets);

      // 3. Actionable Debts Section
      expect(find.byType(ActionableDebtsSection), findsOneWidget);
      expect(find.text('Khoản nợ cần xử lý'), findsOneWidget);
      expect(find.text('Cần trả (2)'), findsOneWidget);
      expect(find.text('Cần thu (3)'), findsOneWidget);

      // 4. Groups Carousel
      expect(find.byType(MyGroupsCarousel), findsOneWidget);
      expect(find.text('Nhóm của tôi'), findsOneWidget);
      expect(find.text('Phòng Dev Cty'), findsOneWidget);

      // 5. Recent Activity Timeline
      expect(find.byType(RecentActivityTimeline), findsOneWidget);
      expect(find.text('Hoạt động gần đây'), findsOneWidget);
    });

    testWidgets('Tapping Cần thu tab switches debt cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeGroupsProvider.overrideWith(
              (ref) => Future.value([
                const HomeGroupItemEntity(
                  id: '1',
                  name: 'Phòng Dev Cty',
                  currency: 'VND',
                  callerRole: 'captain',
                  activeMemberCount: 5,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minh Trần'), findsOneWidget);

      // Tap on "Cần thu (3)" tab
      await tester.tap(find.text('Cần thu (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Trần Lâm'), findsOneWidget);
      expect(find.text('Duyệt proof'), findsOneWidget);
    });
  });
}
