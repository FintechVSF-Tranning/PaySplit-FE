import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/app/theme/app_theme.dart';
import 'package:paysplit/features/bills/domain/entities/bill_detail_entity.dart';
import 'package:paysplit/features/bills/presentation/widgets/amount_unit_switch.dart';
import 'package:paysplit/features/bills/presentation/widgets/edit_item_dialog.dart';

void main() {
  const item = BillItemEntity(
    id: 'item-1',
    name: 'Giày Lacoste',
    quantity: '2',
    unitPrice: 770000,
    lineTotal: 1540000,
    finalPrice: 1540000,
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    ValueChanged<BillItemEntity>? onSave,
  }) async {
    tester.view.physicalSize = const Size(780, 1500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EditItemDialog(
            item: item,
            members: const [],
            isEvenSplit: true,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  testWidgets('formats unit price and VND discount with dots', (tester) async {
    await pumpDialog(tester);

    final price = tester.widget<TextField>(
      find.byKey(const Key('item-price-field')),
    );
    expect(price.controller?.text, '770.000');
    expect(find.byType(AmountUnitSwitch), findsOneWidget);
    expect(find.byType(SegmentedButton<AmountInputUnit>), findsNothing);

    final discount = find.byKey(const Key('item-discount-field'));
    await tester.enterText(discount, '123456');
    await tester.pump();
    expect(tester.widget<TextField>(discount).controller?.text, '123.456');
  });

  testWidgets('converts item percent to total VND discount when saving', (
    tester,
  ) async {
    BillItemEntity? savedItem;
    await pumpDialog(tester, onSave: (value) => savedItem = value);

    final toggle = find.byKey(const Key('item-discount-unit-toggle'));
    await tester.tap(find.descendant(of: toggle, matching: find.text('%')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('item-discount-field')), '10');
    await tester.pump();

    expect(find.textContaining('1.386.000'), findsOneWidget);
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(savedItem?.unitPrice, 770000);
    expect(savedItem?.lineTotal, 1540000);
    expect(savedItem?.discountAmount, 154000);
    expect(savedItem?.finalPrice, 1386000);
  });

  testWidgets('keeps item discount VND when switching modes', (tester) async {
    await pumpDialog(tester);
    final discount = find.byKey(const Key('item-discount-field'));
    await tester.enterText(discount, '77000');
    await tester.pump();

    final toggle = find.byKey(const Key('item-discount-unit-toggle'));
    await tester.tap(find.descendant(of: toggle, matching: find.text('%')));
    await tester.pump();
    expect(tester.widget<TextField>(discount).controller?.text, '10');

    await tester.tap(find.descendant(of: toggle, matching: find.text('VND')));
    await tester.pump();
    expect(tester.widget<TextField>(discount).controller?.text, '77.000');
  });
}
