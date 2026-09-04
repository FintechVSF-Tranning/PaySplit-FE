import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/bills/domain/entities/bill_detail_entity.dart';
import 'package:paysplit/features/bills/presentation/widgets/bill_breakdown_bottom_sheet.dart';

void main() {
  group('BillBreakdownBottomSheet Widget Tests', () {
    testWidgets('Renders breakdown members and displays Người trả trước badge cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const breakdown = [
        BillShareBreakdownEntity(
          memberId: 'm-1',
          userId: 'u-1',
          displayName: 'User 1',
          itemsSubtotal: 0,
          serviceShare: 0,
          vatShare: 0,
          generalDiscountShare: 0,
          finalAmount: 0,
          isCreditor: true,
        ),
        BillShareBreakdownEntity(
          memberId: 'm-3',
          userId: 'u-3',
          displayName: 'User 3',
          itemsSubtotal: 35000,
          serviceShare: 0,
          vatShare: 0,
          generalDiscountShare: 0,
          finalAmount: 35000,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BillBreakdownBottomSheet(
              breakdown: breakdown,
              totalAmount: 35000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bảng phân bổ chi phí (2 người)'), findsOneWidget);
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('User 3'), findsOneWidget);
      expect(find.text('Người trả trước'), findsOneWidget);
      expect(find.textContaining('35.000'), findsWidgets);
    });
  });
}
