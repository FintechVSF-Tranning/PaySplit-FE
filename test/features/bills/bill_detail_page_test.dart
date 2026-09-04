import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/di/injection.dart';
import 'package:paysplit/features/bills/domain/entities/bill_detail_entity.dart';
import 'package:paysplit/features/bills/domain/entities/captured_bill_photo.dart';
import 'package:paysplit/features/bills/domain/repositories/bill_repository.dart';
import 'package:paysplit/features/bills/presentation/pages/bill_detail_page.dart';
import 'package:paysplit/features/bills/presentation/providers/bill_detail_notifier.dart';
import 'package:paysplit/features/bills/presentation/widgets/bill_adjustments_section.dart';
import 'package:paysplit/features/bills/presentation/widgets/bill_item_card.dart';
import 'package:paysplit/features/bills/presentation/widgets/bill_sticky_bottom_bar.dart';
import 'package:paysplit/features/bills/presentation/widgets/reconciliation_warning_bar.dart';

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late MockBillRepository mockRepository;

  final sampleMembers = [
    const BillMemberEntity(
      memberId: 'm-1',
      userId: 'u-1',
      displayName: 'Tin',
      role: 'captain',
    ),
    const BillMemberEntity(memberId: 'm-2', userId: 'u-2', displayName: 'Nam'),
    const BillMemberEntity(memberId: 'm-3', userId: 'u-3', displayName: 'Linh'),
  ];

  final sampleBreakdown = [
    const BillShareBreakdownEntity(
      memberId: 'm-1',
      userId: 'u-1',
      displayName: 'Tin',
      itemsSubtotal: 150000,
      serviceShare: 11538,
      vatShare: 11538,
      generalDiscountShare: 11538,
      finalAmount: 161539,
      isCreditor: true,
    ),
    const BillShareBreakdownEntity(
      memberId: 'm-2',
      userId: 'u-2',
      displayName: 'Nam',
      itemsSubtotal: 325000,
      serviceShare: 25000,
      vatShare: 25000,
      generalDiscountShare: 25000,
      finalAmount: 350000,
    ),
    const BillShareBreakdownEntity(
      memberId: 'm-3',
      userId: 'u-3',
      displayName: 'Linh',
      itemsSubtotal: 175000,
      serviceShare: 13461,
      vatShare: 13461,
      generalDiscountShare: 13461,
      finalAmount: 188461,
    ),
  ];

  final sampleBill = BillDetailEntity(
    id: 'bill-123',
    groupId: 'group-1',
    groupName: 'Phòng Dev Cty',
    creditorMemberId: 'm-1',
    creditorName: 'Tin',
    status: 'draft',
    merchantName: 'Lẩu gà lá é Tao Ngộ',
    subtotal: 700000,
    serviceCharge: 50000,
    vat: 50000,
    totalItemDiscount: 50000,
    generalDiscount: 50000,
    total: 700000,
    members: sampleMembers,
    breakdown: sampleBreakdown,
    items: [
      const BillItemEntity(
        id: 'item-1',
        name: 'Lẩu gà lớn',
        unitPrice: 350000,
        lineTotal: 350000,
        discountAmount: 50000,
        finalPrice: 300000,
        assignments: [
          BillItemAssignmentEntity(
            memberId: 'm-1',
            displayName: 'Tin',
            weight: 0.5,
          ),
          BillItemAssignmentEntity(
            memberId: 'm-2',
            displayName: 'Nam',
            weight: 0.5,
          ),
        ],
      ),
      const BillItemEntity(
        id: 'item-2',
        name: 'Bò nhúng dấm',
        unitPrice: 350000,
        lineTotal: 350000,
        finalPrice: 350000,
        assignments: [
          BillItemAssignmentEntity(
            memberId: 'm-2',
            displayName: 'Nam',
            weight: 0.5,
          ),
          BillItemAssignmentEntity(
            memberId: 'm-3',
            displayName: 'Linh',
            weight: 0.5,
          ),
        ],
      ),
    ],
  );

  setUpAll(() {
    mockRepository = MockBillRepository();
    if (getIt.isRegistered<BillRepository>()) {
      getIt.unregister<BillRepository>();
    }
    getIt.registerSingleton<BillRepository>(mockRepository);
  });

  group('BillDetailNotifier Unit Tests', () {
    test('computes live math and allocation breakdown correctly', () {
      final notifier = BillDetailNotifier(mockRepository, sampleBill);

      final state = notifier.state;
      expect(state.computedGrossSubtotal, 700000);
      expect(state.computedTotalItemDiscount, 50000);
      expect(state.computedNetItemsTotal, 650000);
      expect(state.computedTotal, 700000); // 650k + 50k + 50k - 50k = 700k
      expect(state.deltaTotal, 0); // 100% matched!
      expect(state.breakdown.length, 3);
    });

    test('toggles member assignment and updates weight', () {
      final notifier = BillDetailNotifier(mockRepository, sampleBill);

      // Add 'm-3' (Linh) to item-1
      notifier.toggleMemberAssignment('item-1', 'm-3');

      final updatedItem1 = notifier.state.bill.items.firstWhere(
        (i) => i.id == 'item-1',
      );
      expect(updatedItem1.assignments.length, 3);
      expect(updatedItem1.assignments.any((a) => a.memberId == 'm-3'), isTrue);

      // Remove 'm-3' from item-1
      notifier.toggleMemberAssignment('item-1', 'm-3');
      final revertedItem1 = notifier.state.bill.items.firstWhere(
        (i) => i.id == 'item-1',
      );
      expect(revertedItem1.assignments.length, 2);
      expect(
        revertedItem1.assignments.any((a) => a.memberId == 'm-3'),
        isFalse,
      );
    });

    test(
      'switches split mode to even with custom members and preserves unified assignments when switching back to item_ratio',
      () {
        final notifier = BillDetailNotifier(mockRepository, sampleBill);

        // Verify initial itemRatio assignments
        expect(notifier.state.bill.splitMethod, 'item_ratio');
        expect(notifier.state.bill.items[0].assignments.length, 2);
        expect(notifier.state.bill.items[1].assignments.length, 2);

        // Switch to even mode (all 3 members)
        notifier.setSplitMode('even');
        expect(notifier.state.bill.splitMethod, 'even');
        for (final item in notifier.state.bill.items) {
          expect(item.assignments.length, 3);
        }
        expect(
          notifier.state.evenPerPersonAmount,
          233333,
        ); // 700k / 3 = 233,333 đ

        // Select only 2 members ('m-1' and 'm-2') for even split
        notifier.setEvenSplitMembers({'m-1', 'm-2'});
        expect(notifier.state.activeEvenSplitMemberIds.length, 2);
        for (final item in notifier.state.bill.items) {
          expect(item.assignments.length, 2);
          expect(item.assignments.any((a) => a.memberId == 'm-3'), isFalse);
        }
        expect(
          notifier.state.evenPerPersonAmount,
          350000,
        ); // 700k / 2 = 350,000 đ

        // Switch back to item_ratio mode: preserves unified dataset
        notifier.setSplitMode('item_ratio');
        expect(notifier.state.bill.splitMethod, 'item_ratio');
        for (final item in notifier.state.bill.items) {
          expect(item.assignments.length, 2);
          expect(item.assignments.any((a) => a.memberId == 'm-3'), isFalse);
        }
      },
    );

    test(
      'updating quantity to 2 on one item modifies only that item without corrupting others',
      () {
        final notifier = BillDetailNotifier(mockRepository, sampleBill);

        final originalItem2Name = notifier.state.bill.items[1].name;
        final originalItem2Price = notifier.state.bill.items[1].lineTotal;

        // Update item 1: quantity to 2, unitPrice 350,000 -> lineTotal 700,000, finalPrice 650,000
        final updatedItem1 = notifier.state.bill.items[0].copyWith(
          quantity: '2',
          unitPrice: 350000,
          lineTotal: 700000,
          discountAmount: 50000,
          finalPrice: 650000,
        );

        notifier.updateItem(updatedItem1);

        // Verify item 1 was updated
        expect(notifier.state.bill.items[0].quantity, '2');
        expect(notifier.state.bill.items[0].lineTotal, 700000);
        expect(notifier.state.bill.items[0].finalPrice, 650000);

        // Verify item 2 was NOT corrupted or changed
        expect(notifier.state.bill.items[1].id, 'item-2');
        expect(notifier.state.bill.items[1].name, originalItem2Name);
        expect(notifier.state.bill.items[1].lineTotal, originalItem2Price);
        expect(notifier.state.bill.items[1].quantity, '1');
      },
    );

    test(
      'updates item, taxes, and detects delta mismatch with independent reported total',
      () {
        final notifier = BillDetailNotifier(mockRepository, sampleBill);

        notifier.setAdjustments(serviceCharge: 100000, vat: 80000);
        expect(notifier.state.bill.serviceCharge, 100000);
        expect(notifier.state.bill.vat, 80000);

        // Reported total remains unchanged (700,000) while computedTotal is 780,000
        expect(notifier.state.bill.total, 700000);
        expect(notifier.state.computedTotal, 780000);
        expect(notifier.state.deltaTotal, 80000); // Excess delta detected!

        // User manually reconciles by balancing total
        notifier.balanceTotalToComputed();
        expect(notifier.state.bill.total, 780000);
        expect(notifier.state.deltaTotal, 0);
      },
    );

    test('resolves a shortage by adding it to service charge', () {
      final notifier = BillDetailNotifier(
        mockRepository,
        sampleBill.copyWith(total: 750000),
      );

      expect(notifier.state.deltaTotal, -50000);

      notifier.addMissingAmountToServiceCharge(notifier.state.deltaTotal.abs());

      expect(notifier.state.bill.items.length, sampleBill.items.length);
      expect(notifier.state.bill.serviceCharge, 100000);
      expect(notifier.state.computedTotal, 750000);
      expect(notifier.state.deltaTotal, 0);
      expect(notifier.state.isDirty, isTrue);
    });

    test('resolves an excess by adding it to the shared voucher', () {
      final notifier = BillDetailNotifier(
        mockRepository,
        sampleBill.copyWith(total: 650000),
      );

      expect(notifier.state.deltaTotal, 50000);

      notifier.addExcessAmountToVoucher(notifier.state.deltaTotal);

      expect(notifier.state.bill.generalDiscount, 100000);
      expect(notifier.state.computedTotal, 650000);
      expect(notifier.state.deltaTotal, 0);
      expect(notifier.state.isDirty, isTrue);
    });

    test('clamps adjustments so the computed total cannot be negative', () {
      final notifier = BillDetailNotifier(mockRepository, sampleBill);

      notifier.setAdjustments(
        serviceCharge: -1,
        vat: -1,
        generalDiscount: 999999999,
      );

      expect(notifier.state.bill.serviceCharge, 0);
      expect(notifier.state.bill.vat, 0);
      expect(notifier.state.bill.generalDiscount, 650000);
      expect(notifier.state.computedTotal, 0);
    });

    test(
      'adding a new item recalculates computed total and shows mismatch against reported total',
      () {
        final notifier = BillDetailNotifier(mockRepository, sampleBill);

        final newItem = const BillItemEntity(
          id: 'item-new',
          name: 'Rau thêm',
          unitPrice: 50000,
          lineTotal: 50000,
          finalPrice: 50000,
          assignments: [
            BillItemAssignmentEntity(memberId: 'm-1', displayName: 'Tin'),
          ],
        );

        notifier.addItem(newItem);

        expect(notifier.state.bill.items.length, 3);
        expect(notifier.state.computedGrossSubtotal, 750000);
        expect(notifier.state.computedNetItemsTotal, 700000);
        expect(notifier.state.computedTotal, 750000); // 700k + 50k + 50k - 50k
        expect(
          notifier.state.bill.total,
          700000,
        ); // Reported total is preserved!
        expect(notifier.state.deltaTotal, 50000); // Mismatch detected!
      },
    );

    test(
      'deleting an item recalculates totals and shows mismatch against reported total',
      () {
        final notifier = BillDetailNotifier(mockRepository, sampleBill);

        // Delete item-1 (lineTotal: 350k, discount: 50k, finalPrice: 300k)
        notifier.deleteItem('item-1');

        expect(notifier.state.bill.items.length, 1);
        expect(notifier.state.computedGrossSubtotal, 350000);
        expect(notifier.state.computedTotalItemDiscount, 0);
        expect(notifier.state.computedNetItemsTotal, 350000);
        expect(notifier.state.computedTotal, 400000); // 350k + 50k + 50k - 50k
        expect(
          notifier.state.bill.total,
          700000,
        ); // Reported total is preserved!
        expect(
          notifier.state.deltaTotal,
          -300000,
        ); // Missing 300k compared to reported total!
      },
    );

    test(
      'calculateBreakdown and fetchOfficialBreakdown calls calculate API and updates state breakdown',
      () async {
        when(
          () => mockRepository.calculateBreakdown(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async => Right(sampleBreakdown));

        final notifier = BillDetailNotifier(mockRepository, sampleBill);
        final breakdown = await notifier.fetchOfficialBreakdown();

        expect(breakdown.length, 3);
        expect(breakdown[0].memberId, 'm-1');
        expect(breakdown[0].finalAmount, 161539);
      },
    );

    test(
      'runOcrProcess success sets ocrCandidate and applyOcrCandidate updates bill',
      () async {
        final candidateBill = BillDetailEntity(
          id: 'bill-ocr-1',
          groupId: 'group-1',
          groupName: 'Phòng Dev Cty',
          creditorMemberId: 'm-1',
          creditorName: 'Tin',
          status: 'draft',
          merchantName: 'Pizza 4P',
          subtotal: 500000,
          serviceCharge: 25000,
          vat: 50000,
          totalItemDiscount: 0,
          generalDiscount: 0,
          total: 575000,
          items: [
            const BillItemEntity(
              id: 'ocr-item-1',
              name: '4 Cheese Pizza',
              unitPrice: 280000,
              lineTotal: 280000,
              finalPrice: 280000,
            ),
            const BillItemEntity(
              id: 'ocr-item-2',
              name: 'Crab Pasta',
              unitPrice: 220000,
              lineTotal: 220000,
              finalPrice: 220000,
            ),
          ],
        );

        when(
          () => mockRepository.getGroupMembers(groupId: any(named: 'groupId')),
        ).thenAnswer((_) async => Right(sampleMembers));
        when(
          () => mockRepository.createBillWithPhotos(
            groupId: any(named: 'groupId'),
            merchantName: any(named: 'merchantName'),
            photos: any(named: 'photos'),
          ),
        ).thenAnswer((_) async => Right(candidateBill));

        when(
          () => mockRepository.updateDraftBill(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async => Right(candidateBill));

        final emptyBill = BillDetailEntity(
          id: 'draft-empty',
          groupId: 'group-1',
          groupName: 'Phòng Dev Cty',
          creditorMemberId: 'm-1',
          creditorName: 'Tin',
          status: 'draft',
          merchantName: 'Hoá đơn mới',
          subtotal: 0,
          serviceCharge: 0,
          vat: 0,
          totalItemDiscount: 0,
          generalDiscount: 0,
          total: 0,
        );

        final notifier = BillDetailNotifier(mockRepository, emptyBill);
        expect(notifier.state.bill.items.isEmpty, isTrue);

        await notifier.runOcrProcess(groupId: 'group-1', photos: const []);
        // With empty photos, returns early
        expect(notifier.state.ocrCandidate, isNull);

        // Now with photo
        await notifier.runOcrProcess(
          groupId: 'group-1',
          photos: [
            CapturedBillPhoto(
              id: 'p-1',
              file: XFile(''),
              bytes: Uint8List.fromList([1, 2, 3]),
              name: 'photo.jpg',
              sizeBytes: 1024,
              capturedAt: DateTime.now(),
            ),
          ],
        );
        expect(notifier.state.ocrCandidate, isNotNull);
        expect(notifier.state.ocrCandidate!.merchantName, 'Pizza 4P');
        expect(notifier.state.ocrCandidate!.items.length, 2);

        // Apply Candidate
        await notifier.applyOcrCandidate();
        expect(notifier.state.bill.merchantName, 'Pizza 4P');
        expect(notifier.state.bill.items.length, 2);
        expect(notifier.state.ocrCandidate, isNull);
      },
    );

    test(
      'loadBillDetail with empty billId loads members and auto-resolves creditor without calling getBillDetail',
      () async {
        when(
          () => mockRepository.getGroupMembers(groupId: any(named: 'groupId')),
        ).thenAnswer((_) async => Right(sampleMembers));

        final emptyBill = BillDetailEntity(
          id: '',
          groupId: 'group-1',
          groupName: 'Phòng Dev Cty',
          creditorMemberId: '',
          creditorName: '',
          status: 'draft',
          merchantName: 'Hoá đơn mới',
          subtotal: 0,
          serviceCharge: 0,
          vat: 0,
          totalItemDiscount: 0,
          generalDiscount: 0,
          total: 0,
        );

        final notifier = BillDetailNotifier(mockRepository, emptyBill);
        notifier.setCurrentUserId('u-1');

        await notifier.loadBillDetail(billId: '', groupId: 'group-1');

        expect(notifier.state.bill.members.length, 3);
        expect(notifier.state.bill.creditorMemberId, 'm-1');
        expect(notifier.state.bill.creditorName, 'Tin');
        verifyNever(
          () => mockRepository.getBillDetail(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
          ),
        );
      },
    );

    test(
      'finalizeBill generates Idempotency-Key and returns success',
      () async {
        final notifier = BillDetailNotifier(mockRepository, sampleBill);

        when(
          () => mockRepository.reviewBill(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            version: any(named: 'version'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(sampleBill.copyWith(status: 'reviewed', version: 2)),
        );

        when(
          () => mockRepository.finalizeBill(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            version: 2,
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final result = await notifier.finalizeBill();

        expect(result.isSuccess, isTrue);
        expect(result.isVersionConflict, isFalse);
        expect(notifier.state.bill.status, 'finalized');
        verify(
          () => mockRepository.finalizeBill(
            billId: sampleBill.id,
            groupId: sampleBill.groupId,
            version: 2,
            idempotencyKey: any(
              named: 'idempotencyKey',
              that: isA<String>().having(
                (k) => k.isNotEmpty,
                'non-empty',
                true,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'finalizeBill detects 409 VERSION_CONFLICT and returns isVersionConflict == true',
      () async {
        final notifier = BillDetailNotifier(mockRepository, sampleBill);

        when(
          () => mockRepository.reviewBill(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            version: any(named: 'version'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(sampleBill.copyWith(status: 'reviewed', version: 2)),
        );

        when(
          () => mockRepository.finalizeBill(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            version: 2,
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            ServerFailure(
              'Hóa đơn vừa được cập nhật ở thiết bị khác.',
              code: 'VERSION_CONFLICT',
              statusCode: 409,
            ),
          ),
        );

        final result = await notifier.finalizeBill();

        expect(result.isSuccess, isFalse);
        expect(result.isVersionConflict, isTrue);
        expect(notifier.state.errorMessage, isNull);
      },
    );
  });

  group('BillDetailPage Widget Tests', () {
    testWidgets('renders all main bill components properly', (tester) async {
      when(
        () => mockRepository.getGroupMembers(groupId: any(named: 'groupId')),
      ).thenAnswer((_) async => Right(sampleMembers));
      when(
        () => mockRepository.getBillDetail(
          billId: any(named: 'billId'),
          groupId: any(named: 'groupId'),
        ),
      ).thenAnswer((_) async => Right(sampleBill));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: BillDetailPage(initialBill: sampleBill)),
        ),
      );
      await tester.pumpAndSettle();

      // Check topbar header info
      expect(find.text('Lẩu gà lá é Tao Ngộ'), findsOneWidget);
      expect(find.textContaining('Người trả:'), findsOneWidget);

      // Check split mode toggle
      expect(find.text('Chia đều tổng hoá đơn'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Check item cards
      expect(find.byType(BillItemCard), findsNWidgets(2));
      expect(find.text('Lẩu gà lớn'), findsOneWidget);
      expect(find.text('Bò nhúng dấm'), findsOneWidget);

      // Check adjustments section
      expect(find.byType(BillAdjustmentsSection), findsOneWidget);
      expect(find.byType(ReconciliationWarningBar), findsOneWidget);

      // Check sticky bottom bar
      expect(find.byType(BillStickyBottomBar), findsOneWidget);
      expect(find.text('Chốt hoá đơn'), findsOneWidget);
      expect(find.text('Lưu nháp'), findsOneWidget);
    });

    testWidgets(
      'shows version conflict dialog when finalize gets 409 and reloads bill',
      (tester) async {
        when(
          () => mockRepository.getGroupMembers(groupId: any(named: 'groupId')),
        ).thenAnswer((_) async => Right(sampleMembers));
        when(
          () => mockRepository.getBillDetail(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
          ),
        ).thenAnswer((_) async => Right(sampleBill));
        when(
          () => mockRepository.reviewBill(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            version: any(named: 'version'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(sampleBill.copyWith(status: 'reviewed', version: 2)),
        );
        when(
          () => mockRepository.finalizeBill(
            billId: any(named: 'billId'),
            groupId: any(named: 'groupId'),
            version: any(named: 'version'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            ServerFailure(
              'Version conflict',
              code: 'VERSION_CONFLICT',
              statusCode: 409,
            ),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(home: BillDetailPage(initialBill: sampleBill)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Chốt hoá đơn button
        await tester.tap(find.text('Chốt hoá đơn'));
        await tester.pumpAndSettle();

        // Tap confirmation in bottom sheet (second Chốt hoá đơn button)
        await tester.tap(find.text('Chốt hoá đơn').last);
        await tester.pumpAndSettle();

        // Expect version conflict dialog to appear with exact required text
        expect(find.text('Dữ liệu đã thay đổi'), findsOneWidget);
        expect(
          find.text(
            'Hóa đơn đã được cập nhật bởi thành viên khác, bạn có muốn tải lại dữ liệu mới nhất?',
          ),
          findsOneWidget,
        );
        expect(find.text('Tải lại dữ liệu'), findsOneWidget);

        // Tap Tải lại dữ liệu
        await tester.tap(find.text('Tải lại dữ liệu'));
        await tester.pumpAndSettle();

        // Verify getBillDetail was called to reload
        verify(
          () => mockRepository.getBillDetail(
            billId: sampleBill.id,
            groupId: sampleBill.groupId,
          ),
        ).called(greaterThanOrEqualTo(1));
      },
    );
  });
}
