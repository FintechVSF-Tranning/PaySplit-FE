import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/widgets/receivable_proofs_tab.dart';

DebtItemEntity _awaitingDebt({
  required int reminderCount,
  DateTime? lastRemindedAt,
}) => DebtItemEntity(
  id: 'debt-1',
  groupId: 'group',
  groupName: 'Bà Nà Hill',
  billId: 'bill-1',
  billTitle: 'Bữa tối',
  debtorId: 'debtor-1',
  debtorName: 'Hoàng Nam',
  debtorAvatar: 'HN',
  creditorId: 'me',
  creditorName: 'Tôi',
  creditorAvatar: 'T',
  amount: 250000,
  status: DebtStatus.awaiting,
  createdAt: DateTime(2026, 9, 5),
  reminderCount: reminderCount,
  lastRemindedAt: lastRemindedAt,
);

Future<void> _pumpTab(WidgetTester tester, DebtItemEntity debt) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReceivableProofsTab(
            pendingProofs: const [],
            receivableDebts: [debt],
            onOpenProofReview: (_) {},
            remindedCooldowns: const {},
            onConfirmProof: (_) {},
            onRejectProof: (_) {},
            onRemindDebt: (_, _) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hết lượt nhắc thì nút không mời bấm nữa', (tester) async {
    // BE chặn theo cả trần số lần nhắc lẫn khoảng 24h. Chỉ nhìn thời gian thì
    // sau lần thứ ba, qua 24h nút lại sáng xanh nhưng bấm là ăn RATE_LIMITED.
    await _pumpTab(tester, _awaitingDebt(reminderCount: maxReminderCount));

    expect(find.text('Hết lượt nhắc'), findsOneWidget);
    expect(find.text('Nhắc nợ'), findsNothing);
  });

  testWidgets('còn lượt và hết cooldown thì vẫn nhắc được', (tester) async {
    await _pumpTab(tester, _awaitingDebt(reminderCount: maxReminderCount - 1));

    expect(find.text('Nhắc nợ'), findsOneWidget);
    expect(find.text('Hết lượt nhắc'), findsNothing);
  });

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('long recipient bank fits at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final proof = ProofDetailEntity(
        id: 'proof',
        groupId: 'group',
        groupName: 'Bà Nà Hill',
        paymentId: 'payment',
        debtorName: 'Hoàng Nam',
        debtorAvatar: 'HN',
        creditorName: 'Người nhận',
        amount: 4505000,
        submittedAt: DateTime(2026, 9, 5),
        targetBank: 'Ngân hàng TMCP Ngoại Thương Việt Nam',
        targetAccount: '123456789',
        referenceCode: 'PAYYG7HW75YR',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ReceivableProofsTab(
                  pendingProofs: [proof],
                  receivableDebts: const [],
                  onOpenProofReview: (_) {},
                  remindedCooldowns: const {},
                  onConfirmProof: (_) {},
                  onRejectProof: (_) {},
                  onRemindDebt: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(proof.targetBank), findsOneWidget);
      expect(find.text(proof.referenceCode), findsOneWidget);
    });
  }
}
