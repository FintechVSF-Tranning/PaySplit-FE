import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/app/theme/app_theme.dart';
import 'package:paysplit/features/bills/domain/entities/bill_detail_entity.dart';
import 'package:paysplit/features/bills/presentation/widgets/amount_unit_switch.dart';
import 'package:paysplit/features/bills/presentation/widgets/bill_adjustments_section.dart';
import 'package:paysplit/features/bills/presentation/widgets/reconciliation_warning_bar.dart';

void main() {
  final bill = BillDetailEntity(
    id: 'bill-1',
    groupId: 'group-1',
    groupName: 'Nhóm',
    creditorMemberId: 'member-1',
    creditorName: 'Nam',
    status: 'draft',
    subtotal: 700000,
    serviceCharge: 50000,
    vat: 50000,
    totalItemDiscount: 50000,
    generalDiscount: 50000,
    total: 750000,
    items: const [
      BillItemEntity(
        id: 'item-1',
        name: 'Lẩu gà',
        lineTotal: 700000,
        discountAmount: 50000,
        finalPrice: 650000,
        assignments: [BillItemAssignmentEntity(memberId: 'member-1')],
      ),
    ],
  );

  Future<void> pumpAdjustments(
    WidgetTester tester, {
    bool isEditable = true,
    ThemeData? theme,
    BillAdjustmentUpdate? onUpdate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BillAdjustmentsSection(
              bill: bill,
              computedGrossSubtotal: 700000,
              computedTotalItemDiscount: 50000,
              computedNetItemsTotal: 650000,
              computedTotal: 700000,
              isEditable: isEditable,
              onUpdateAdjustments:
                  onUpdate ?? ({serviceCharge, vat, generalDiscount}) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the full calculated money sequence', (tester) async {
    await pumpAdjustments(tester);

    expect(find.text('Tổng tiền món gốc'), findsOneWidget);
    expect(find.text('Khuyến mãi món'), findsOneWidget);
    expect(find.text('Tiền món thực tế'), findsOneWidget);
    expect(find.text('Phí dịch vụ'), findsOneWidget);
    expect(find.text('Thuế VAT'), findsOneWidget);
    expect(find.text('Voucher chung'), findsOneWidget);
    expect(find.text('Tổng thanh toán'), findsOneWidget);
    expect(find.byKey(const Key('computed-total-value')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').startsWith('Tổng cộng thanh toán,'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('modal has no total input and updates its preview from chips', (
    tester,
  ) async {
    int? savedService;
    int? savedVat;
    int? savedDiscount;

    await pumpAdjustments(
      tester,
      onUpdate: ({serviceCharge, vat, generalDiscount}) {
        savedService = serviceCharge;
        savedVat = vat;
        savedDiscount = generalDiscount;
      },
    );

    await tester.ensureVisible(
      find.byKey(const Key('edit-adjustments-button')),
    );
    await tester.tap(find.byKey(const Key('edit-adjustments-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-adjustments-modal')), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.byType(AmountUnitSwitch), findsNWidgets(3));
    expect(find.byType(SegmentedButton<AmountInputUnit>), findsNothing);
    expect(find.text('Tổng cộng (VND)'), findsNothing);
    expect(find.byKey(const Key('item-discount-read-only')), findsOneWidget);

    await tester.tap(find.text('10%').first);
    await tester.pump();

    final serviceTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('service-charge-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(serviceTextField.controller?.text, '10');
    expect(
      find.descendant(
        of: find.byKey(const Key('adjustments-live-preview')),
        matching: find.textContaining('715.000'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('save-adjustments')));
    await tester.tap(find.byKey(const Key('save-adjustments')));
    await tester.pumpAndSettle();

    expect(savedService, 65000);
    expect(savedVat, 50000);
    expect(savedDiscount, 50000);
  });

  testWidgets('formats typed VND and saves the raw VND amount', (tester) async {
    int? savedService;
    await pumpAdjustments(
      tester,
      onUpdate: ({serviceCharge, vat, generalDiscount}) {
        savedService = serviceCharge;
      },
    );

    await tester.tap(find.byKey(const Key('edit-adjustments-button')));
    await tester.pumpAndSettle();
    final serviceInput = find.descendant(
      of: find.byKey(const Key('service-charge-field')),
      matching: find.byType(TextField),
    );
    await tester.enterText(serviceInput, '1234567');
    await tester.pump();

    expect(
      tester.widget<TextField>(serviceInput).controller?.text,
      '1.234.567',
    );

    await tester.ensureVisible(find.byKey(const Key('save-adjustments')));
    await tester.tap(find.byKey(const Key('save-adjustments')));
    await tester.pumpAndSettle();
    expect(savedService, 1234567);
  });

  testWidgets('converts typed decimal percent to VND before saving', (
    tester,
  ) async {
    int? savedService;
    await pumpAdjustments(
      tester,
      onUpdate: ({serviceCharge, vat, generalDiscount}) {
        savedService = serviceCharge;
      },
    );

    await tester.tap(find.byKey(const Key('edit-adjustments-button')));
    await tester.pumpAndSettle();
    final serviceField = find.byKey(const Key('service-charge-field'));
    await tester.tap(
      find.descendant(of: serviceField, matching: find.text('%')),
    );
    await tester.pump();
    final serviceInput = find.descendant(
      of: serviceField,
      matching: find.byType(TextField),
    );
    await tester.enterText(serviceInput, '8.5');
    await tester.pump();

    expect(tester.widget<TextField>(serviceInput).controller?.text, '8,5');
    await tester.ensureVisible(find.byKey(const Key('save-adjustments')));
    await tester.tap(find.byKey(const Key('save-adjustments')));
    await tester.pumpAndSettle();
    expect(savedService, 55250);
  });

  testWidgets('keeps exact VND value when switching input modes', (
    tester,
  ) async {
    await pumpAdjustments(tester);
    await tester.tap(find.byKey(const Key('edit-adjustments-button')));
    await tester.pumpAndSettle();
    final serviceField = find.byKey(const Key('service-charge-field'));

    await tester.tap(
      find.descendant(of: serviceField, matching: find.text('%')),
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: serviceField, matching: find.text('VND')),
    );
    await tester.pump();

    final serviceInput = tester.widget<TextField>(
      find.descendant(of: serviceField, matching: find.byType(TextField)),
    );
    expect(serviceInput.controller?.text, '50.000');
  });

  testWidgets('converts VAT and voucher percentages to VND', (tester) async {
    int? savedVat;
    int? savedDiscount;
    await pumpAdjustments(
      tester,
      onUpdate: ({serviceCharge, vat, generalDiscount}) {
        savedVat = vat;
        savedDiscount = generalDiscount;
      },
    );
    await tester.tap(find.byKey(const Key('edit-adjustments-button')));
    await tester.pumpAndSettle();

    for (final entry in const [
      ('vat-field', '8'),
      ('general-discount-field', '10'),
    ]) {
      final field = find.byKey(Key(entry.$1));
      final percentToggle = find.descendant(
        of: field,
        matching: find.text('%'),
      );
      await tester.ensureVisible(percentToggle);
      await tester.pumpAndSettle();
      await tester.tap(percentToggle);
      await tester.pump();
      final input = find.descendant(
        of: field,
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(input);
      await tester.enterText(input, entry.$2);
      await tester.pump();
    }

    await tester.ensureVisible(find.byKey(const Key('save-adjustments')));
    await tester.tap(find.byKey(const Key('save-adjustments')));
    await tester.pumpAndSettle();
    expect(savedVat, 52000);
    expect(savedDiscount, 65000);
  });

  testWidgets('cancel leaves adjustments unchanged', (tester) async {
    var saveCount = 0;
    await pumpAdjustments(
      tester,
      onUpdate: ({serviceCharge, vat, generalDiscount}) => saveCount++,
    );

    await tester.tap(find.byKey(const Key('edit-adjustments-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('cancel-adjustments')));
    await tester.tap(find.byKey(const Key('cancel-adjustments')));
    await tester.pumpAndSettle();

    expect(saveCount, 0);
  });

  testWidgets('read only bill cannot open the adjustments modal', (
    tester,
  ) async {
    await pumpAdjustments(tester, isEditable: false);

    expect(find.byKey(const Key('edit-adjustments-button')), findsNothing);
    await tester.tap(find.byKey(const Key('bill-adjustments-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-adjustments-modal')), findsNothing);
  });

  group('reconciliation warning', () {
    Future<void> pumpWarning(
      WidgetTester tester, {
      required int computedTotal,
      required int reportedTotal,
      required List<BillItemEntity> unassignedItems,
      bool isEditable = true,
      VoidCallback? onBalance,
      VoidCallback? onSurcharge,
      VoidCallback? onVoucher,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ReconciliationWarningBar(
                computedTotal: computedTotal,
                reportedTotal: reportedTotal,
                deltaTotal: computedTotal - reportedTotal,
                unassignedItems: unassignedItems,
                isEditable: isEditable,
                onBalanceTotal: onBalance ?? () {},
                onAddSurcharge: onSurcharge ?? () {},
                onAddVoucher: onVoucher ?? () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows matched state', (tester) async {
      await pumpWarning(
        tester,
        computedTotal: 700000,
        reportedTotal: 700000,
        unassignedItems: const [],
      );

      expect(find.text('Đối soát hóa đơn'), findsOneWidget);
      expect(find.textContaining('khớp hoàn toàn'), findsOneWidget);
    });

    testWidgets('shortage action adds surcharge', (tester) async {
      var tapped = false;
      await pumpWarning(
        tester,
        computedTotal: 650000,
        reportedTotal: 700000,
        unassignedItems: const [],
        onSurcharge: () => tapped = true,
      );

      expect(find.textContaining('THIẾU'), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('add-surcharge-action')));
      expect(tapped, isTrue);
    });

    testWidgets('excess action adds voucher', (tester) async {
      var tapped = false;
      await pumpWarning(
        tester,
        computedTotal: 750000,
        reportedTotal: 700000,
        unassignedItems: const [],
        onVoucher: () => tapped = true,
      );

      expect(find.textContaining('DƯ'), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('add-voucher-action')));
      expect(tapped, isTrue);
    });

    testWidgets('combines total mismatch and unassigned item warning', (
      tester,
    ) async {
      await pumpWarning(
        tester,
        computedTotal: 650000,
        reportedTotal: 700000,
        unassignedItems: bill.items,
      );

      expect(find.textContaining('THIẾU'), findsNWidgets(2));
      expect(find.textContaining('Lẩu gà'), findsOneWidget);
      expect(find.textContaining('chưa phân bổ cho ai'), findsOneWidget);
    });

    testWidgets('read only warning hides reconciliation actions', (
      tester,
    ) async {
      await pumpWarning(
        tester,
        computedTotal: 650000,
        reportedTotal: 700000,
        unassignedItems: const [],
        isEditable: false,
      );

      expect(find.byKey(const Key('add-surcharge-action')), findsNothing);
      expect(
        find.byKey(const Key('balance-reported-total-action')),
        findsNothing,
      );
    });
  });

  testWidgets('supports dark theme at large text scale', (tester) async {
    tester.view.physicalSize = const Size(640, 1400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BillAdjustmentsSection(
              bill: bill,
              computedGrossSubtotal: 700000,
              computedTotalItemDiscount: 50000,
              computedNetItemsTotal: 650000,
              computedTotal: 700000,
              onUpdateAdjustments: ({serviceCharge, vat, generalDiscount}) {},
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('edit-adjustments-button')),
    );
    await tester.tap(find.byKey(const Key('edit-adjustments-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-adjustments-modal')), findsOneWidget);
    final serviceField = find.byKey(const Key('service-charge-field'));
    final serviceLabel = find.descendant(
      of: serviceField,
      matching: find.text('Phí dịch vụ'),
    );
    final firstChip = find.descendant(
      of: serviceField,
      matching: find.widgetWithText(OutlinedButton, '0đ'),
    );
    expect(
      tester.getTopLeft(firstChip).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(serviceLabel).dy),
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('keeps quick actions beside labels at ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width * 2, 1400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpAdjustments(tester);
      await tester.tap(find.byKey(const Key('edit-adjustments-button')));
      await tester.pumpAndSettle();

      for (final entry in const [
        ('service-charge-field', 'Phí dịch vụ', '0đ'),
        ('vat-field', 'Thuế VAT', '0%'),
        ('general-discount-field', 'Voucher chung', '0đ'),
      ]) {
        final field = find.byKey(Key(entry.$1));
        final label = find.descendant(of: field, matching: find.text(entry.$2));
        final firstChip = find.descendant(
          of: field,
          matching: find.widgetWithText(OutlinedButton, entry.$3),
        );
        expect(
          (tester.getCenter(label).dy - tester.getCenter(firstChip).dy).abs(),
          lessThan(1),
        );
      }

      expect(find.textContaining('(VND)'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
