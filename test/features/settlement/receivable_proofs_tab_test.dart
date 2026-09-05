import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/widgets/receivable_proofs_tab.dart';

void main() {
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
