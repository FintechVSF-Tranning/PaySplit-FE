import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:paysplit/app/theme/app_theme.dart';
import 'package:paysplit/features/settlement/data/mock/mock_settlement_repository.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/pages/settlement_page.dart';
import 'package:paysplit/features/settlement/presentation/providers/settlement_controller.dart';
import 'package:paysplit/features/settlement/presentation/widgets/all_bills_tab.dart';
import 'package:paysplit/features/settlement/presentation/widgets/dynamic_vietqr_sheet.dart';
import 'package:paysplit/features/settlement/presentation/widgets/payable_debts_tab.dart';
import 'package:paysplit/features/settlement/presentation/widgets/proof_review_sheet.dart';
import 'package:paysplit/features/settlement/presentation/widgets/receivable_proofs_tab.dart';
import 'package:paysplit/features/settlement/presentation/widgets/reject_proof_dialog.dart';
import 'package:paysplit/features/settlement/presentation/widgets/select_debt_batch_sheet.dart';
import 'package:paysplit/features/settlement/presentation/widgets/settled_history_tab.dart';
import 'package:paysplit/features/settlement/presentation/widgets/settlement_hero_summary_card.dart';

void main() {
  Widget testApp({
    SettlementTab initialTab = SettlementTab.payable,
    ThemeData? theme,
  }) {
    return ProviderScope(
      overrides: [
        settlementRepositoryProvider.overrideWithValue(
          MockSettlementRepository(),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SettlementPage(initialTab: initialTab),
        ),
      ),
    );
  }

  group('SettlementPage Widget Tests', () {
    testWidgets(
      'SettlementPage renders top header, summary card, tab selector and initial tab',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(testApp(theme: AppTheme.light));
        await tester.pumpAndSettle();

        // 1. Top Header Bar
        expect(find.text('Công nợ & Hóa đơn'), findsOneWidget);
        expect(
          find.text('Tổng hợp công nợ đa nhóm & đối soát minh chứng'),
          findsOneWidget,
        );

        // 2. Settlement Hero Summary Card
        expect(find.byType(SettlementHeroSummaryCard), findsOneWidget);
        expect(find.text('TỔNG HỢP CÔNG NỢ TOÀN HỆ THỐNG'), findsOneWidget);
        expect(find.text('Bạn cần trả (3)'), findsOneWidget);
        expect(find.textContaining('400.000'), findsWidgets);
        expect(find.text('Bạn cần thu (3)'), findsOneWidget);
        expect(find.textContaining('1.250.000'), findsWidgets);
        expect(find.text('1 proof chờ duyệt'), findsOneWidget);
        expect(find.text('Trả nợ'), findsWidgets);

        // 3. Tab Buttons
        expect(find.text('Cần trả (3)'), findsOneWidget);
        expect(find.text('Cần thu (3)'), findsOneWidget);
        expect(find.text('Hóa đơn (3)'), findsOneWidget);
        expect(find.text('Lịch sử (3)'), findsOneWidget);

        // 4. Default Tab: PayableDebtsTab
        expect(find.byType(PayableDebtsTab), findsOneWidget);
        expect(find.text('Minh Tran'), findsWidgets);
        expect(find.text('Đức Huy'), findsOneWidget);
        expect(find.text('Trả QR'), findsWidgets);
      },
    );

    testWidgets(
      'Tapping tabs switches between Payable, Receivable, Bills, and History',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(testApp());
        await tester.pumpAndSettle();

        // Tap on "Cần thu (3)"
        await tester.tap(find.text('Cần thu (3)'));
        await tester.pumpAndSettle();

        expect(find.byType(ReceivableProofsTab), findsOneWidget);
        expect(find.text('Trần Lâm'), findsOneWidget);
        expect(find.text('Chờ duyệt'), findsOneWidget);
        expect(find.text('Xem & xác nhận'), findsOneWidget);
        expect(find.text('✕ Từ chối'), findsOneWidget);
        expect(find.text('Nhắc nợ'), findsWidgets);

        // Tap on "Hóa đơn (3)"
        await tester.tap(find.text('Hóa đơn (3)'));
        await tester.pumpAndSettle();

        expect(find.byType(AllBillsTab), findsOneWidget);
        expect(find.text('Lẩu gà lá é Tao Ngộ'), findsOneWidget);
        expect(find.text('Cà phê planning Sprint 12'), findsOneWidget);
        expect(find.text('Vé xe Limousine Đà Lạt'), findsOneWidget);
        expect(find.text('Người trả trước: Nam Phạm'), findsOneWidget);
        expect(find.text('3/5 người đã trả'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('bill-progress-bill-3')),
          findsOneWidget,
        );

        // Tap on "Lịch sử (3)"
        await tester.tap(find.text('Lịch sử (3)'));
        await tester.pumpAndSettle();

        expect(find.byType(SettledHistoryTab), findsOneWidget);
        expect(find.text('Linh Dan đã trả bạn'), findsOneWidget);
        expect(find.text('Bạn đã trả Đức Huy'), findsOneWidget);
        expect(find.text('Tuấn Kiệt đã trả bạn'), findsOneWidget);
        expect(find.text('Đã đối soát'), findsWidgets);
      },
    );

    testWidgets(
      'Tapping Trả nợ opens SelectDebtBatchSheet modal with Single-Creditor grouping',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(testApp());
        await tester.pumpAndSettle();

        // Tap on "Trả nợ" button on the hero card
        await tester.tap(find.text('Trả nợ').first);
        await tester.pumpAndSettle();

        expect(find.byType(SelectDebtBatchSheet), findsOneWidget);
        expect(find.text('Chọn khoản nợ & Trả gộp'), findsOneWidget);
        expect(
          find.textContaining('Quy tắc VietQR', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Phòng Dev Cty'), findsWidgets);
        expect(find.text('Du lịch Đà Lạt 2026'), findsWidgets);
      },
    );

    testWidgets(
      'Selecting a debt batch opens VietQR without framework errors',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(testApp(theme: AppTheme.light));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Trả nợ').first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Trả nợ').first);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(SelectDebtBatchSheet), findsNothing);
        expect(find.byType(DynamicVietQrSheet), findsOneWidget);
        expect(find.text('Thanh toán qua VietQR'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Trả QR on debt opens DynamicVietQrSheet modal with details',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(testApp());
        await tester.pumpAndSettle();

        // Tap on first "Trả QR"
        await tester.tap(find.text('Trả QR').first);
        await tester.pumpAndSettle();

        expect(find.byType(DynamicVietQrSheet), findsOneWidget);
        expect(find.text('Thanh toán qua VietQR'), findsOneWidget);
        expect(
          find.text('Quét mã bằng ứng dụng Ngân hàng bất kỳ'),
          findsOneWidget,
        );
        expect(find.textContaining('120.000'), findsWidgets);
        expect(find.text('Tải ảnh biên lai đã chuyển'), findsOneWidget);
      },
    );

    testWidgets('Tapping Digibank slip preview opens ProofReviewSheet modal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(testApp(initialTab: SettlementTab.receivable));
      await tester.pumpAndSettle();

      expect(find.text('Xem ảnh biên lai đã gửi ↗'), findsOneWidget);
      await tester.tap(find.text('Xem ảnh biên lai đã gửi ↗'));
      await tester.pumpAndSettle();

      expect(find.byType(ProofReviewSheet), findsOneWidget);
      expect(find.byKey(const Key('proof-image')), findsOneWidget);
      expect(find.text('Duyệt bằng chứng chuyển tiền'), findsOneWidget);
      expect(
        find.text('Biên lai do người trả gửi, chưa được PaySplit xác minh.'),
        findsOneWidget,
      );
      expect(find.text('PAY8X9K2M1A'), findsWidgets);
      expect(find.text('Xác nhận đã nhận tiền'), findsWidgets);
    });

    testWidgets('Tapping Từ chối opens RejectProofDialog modal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(testApp(initialTab: SettlementTab.receivable));
      await tester.pumpAndSettle();

      await tester.tap(find.text('✕ Từ chối'));
      await tester.pumpAndSettle();

      expect(find.byType(RejectProofDialog), findsOneWidget);
      expect(find.text('Từ chối xác nhận tiền'), findsOneWidget);
      expect(find.text('Gửi từ chối'), findsOneWidget);
    });

    testWidgets(
      'applies payable when reentering after another tab was active',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        final container = ProviderContainer(
          overrides: [
            settlementRepositoryProvider.overrideWithValue(
              MockSettlementRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          settlementControllerProvider.notifier,
        );
        await controller.loadData();
        controller.setTab(SettlementTab.history);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: SettlementPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PayableDebtsTab), findsOneWidget);
        expect(
          container.read(settlementControllerProvider).currentTab,
          SettlementTab.payable,
        );
      },
    );

    testWidgets(
      'shows every pending proof and routes each proof independently',
      (tester) async {
        final openedPayments = <String>[];
        final proofs = [
          _proofFixture(paymentId: 'payment-one', debtorName: 'Nguyễn An'),
          _proofFixture(paymentId: 'payment-two', debtorName: 'Trần Bình'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReceivableProofsTab(
                  pendingProofs: proofs,
                  receivableDebts: const [],
                  remindedCooldowns: const {},
                  onOpenProofReview: (proof) {
                    openedPayments.add(proof.paymentId);
                  },
                  onConfirmProof: (_) {},
                  onRejectProof: (_) {},
                  onRemindDebt: null,
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('pending-proof-payment-one')),
          findsOne,
        );
        expect(
          find.byKey(const ValueKey('pending-proof-payment-two')),
          findsOne,
        );
        expect(find.text('Xem ảnh biên lai đã gửi ↗'), findsNWidgets(2));

        await tester.tap(find.text('Xem ảnh biên lai đã gửi ↗').first);
        await tester.pump();
        await tester.tap(find.text('Xem ảnh biên lai đã gửi ↗').last);
        await tester.pump();

        expect(openedPayments, ['payment-one', 'payment-two']);
      },
    );

    testWidgets(
      'pending confirmation debt is shown only as a proof without reminder',
      (tester) async {
        final proof = _proofFixture(
          paymentId: 'payment-pending',
          debtorName: 'Nguyễn An',
        );
        final debt = DebtItemEntity(
          id: 'debt-pending',
          groupId: proof.groupId,
          groupName: proof.groupName,
          billId: 'bill-pending',
          billTitle: 'Bữa tối',
          debtorId: 'member-debtor',
          debtorName: proof.debtorName,
          debtorAvatar: proof.debtorAvatar,
          creditorId: 'member-creditor',
          creditorName: proof.creditorName,
          creditorAvatar: 'NA',
          amount: proof.amount,
          status: DebtStatus.pendingConfirmation,
          createdAt: proof.submittedAt,
          paymentId: proof.paymentId,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReceivableProofsTab(
                  pendingProofs: [proof],
                  receivableDebts: [debt],
                  remindedCooldowns: const {},
                  onOpenProofReview: (_) {},
                  onConfirmProof: (_) {},
                  onRejectProof: (_) {},
                  onRemindDebt: (_, _) {},
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('pending-proof-payment-pending')),
          findsOneWidget,
        );
        expect(find.text('Nhắc nợ'), findsNothing);
      },
    );

    testWidgets('Header search button opens inline search and filters bills tab', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(testApp());
      await tester.pumpAndSettle();

      // Switch to bills tab
      await tester.tap(find.text('Hóa đơn (3)'));
      await tester.pumpAndSettle();

      expect(find.byType(AllBillsTab), findsOneWidget);
      expect(find.text('Lẩu gà lá é Tao Ngộ'), findsOneWidget);
      expect(find.text('Vé xe Limousine Đà Lạt'), findsOneWidget);

      // Open header search
      await tester.tap(find.byTooltip('Tìm kiếm công nợ, hóa đơn'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Lẩu gà');
      await tester.pumpAndSettle();

      // Only matching bill should remain
      expect(find.text('Lẩu gà lá é Tao Ngộ'), findsOneWidget);
      expect(find.text('Vé xe Limousine Đà Lạt'), findsNothing);

      // Back button in search header clears search
      await tester.tap(find.byIcon(HugeIcons.strokeRoundedArrowLeft01));
      await tester.pumpAndSettle();

      // All bills should be restored
      expect(find.text('Lẩu gà lá é Tao Ngộ'), findsOneWidget);
      expect(find.text('Vé xe Limousine Đà Lạt'), findsOneWidget);
    });

    testWidgets(
      'ReceivableProofsTab displays concise cooldown (22h, 1p) on button and warns on tap',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final debts = [
          DebtItemEntity(
            id: 'debt-rec-cooldown-22h',
            groupId: 'group-dev',
            groupName: 'Phòng Dev',
            billId: 'bill-1',
            billTitle: 'Lẩu gà',
            debtorId: 'member-an',
            debtorName: 'Nguyễn An',
            debtorAvatar: 'NA',
            creditorId: 'member-me',
            creditorName: 'Tôi',
            creditorAvatar: 'T',
            amount: 150000,
            status: DebtStatus.awaiting,
            createdAt: DateTime.now(),
          ),
          DebtItemEntity(
            id: 'debt-rec-cooldown-1p',
            groupId: 'group-dev',
            groupName: 'Phòng Dev',
            billId: 'bill-2',
            billTitle: 'Cà phê',
            debtorId: 'member-binh',
            debtorName: 'Trần Bình',
            debtorAvatar: 'TB',
            creditorId: 'member-me',
            creditorName: 'Tôi',
            creditorAvatar: 'T',
            amount: 50000,
            status: DebtStatus.awaiting,
            createdAt: DateTime.now(),
          ),
        ];

        String? remindedId;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReceivableProofsTab(
                  pendingProofs: const [],
                  receivableDebts: debts,
                  remindedCooldowns: const {
                    'debt-rec-cooldown-22h': 22 * 3600,
                    'debt-rec-cooldown-1p': 60,
                  },
                  onOpenProofReview: (_) {},
                  onConfirmProof: (_) {},
                  onRejectProof: (_) {},
                  onRemindDebt: (id, _) {
                    remindedId = id;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Buttons show concise cooldown format: 22h and 1p
        expect(find.text('22h'), findsOneWidget);
        expect(find.text('1p'), findsOneWidget);
        expect(find.text('Nhắc nợ'), findsNothing);

        // 2. Buttons in cooldown are disabled and display time quietly
        await tester.tap(find.text('22h'));
        await tester.pump();
        expect(remindedId, isNull);
      },
    );
  });
}

ProofDetailEntity _proofFixture({
  required String paymentId,
  required String debtorName,
}) {
  return ProofDetailEntity(
    id: 'proof-$paymentId',
    groupId: 'group-one',
    groupName: 'Nhóm một',
    paymentId: paymentId,
    debtorName: debtorName,
    debtorAvatar: debtorName.substring(0, 1),
    creditorName: 'Nam',
    amount: 120000,
    submittedAt: DateTime.utc(2026, 8, 25),
    targetBank: 'Vietcombank',
    targetAccount: '0123456789',
    referenceCode: paymentId.toUpperCase(),
    proofImageUrl: 'https://example.test/$paymentId.png',
  );
}
