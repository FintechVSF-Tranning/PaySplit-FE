import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/home/presentation/widgets/actionable_debts_section.dart';
import 'package:paysplit/features/settlement/data/mock/mock_settlement_data.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/widgets/proof_review_sheet.dart';

void main() {
  testWidgets(
    'pending debt opens receipt instead of QR, rejected debt can pay again',
    (tester) async {
      final debt = MockSettlementData.payableDebts.first;
      var qrCalls = 0;
      DebtItemEntity? viewed;
      Future<void> render(DebtStatus status) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionableDebtsSection(
              payableDebts: [
                debt.copyWith(status: status, paymentId: 'payment-1'),
              ],
              onPayQr: (_) => qrCalls++,
              onViewSubmittedProof: (debt) => viewed = debt,
            ),
          ),
        ),
      );
      await render(DebtStatus.pendingConfirmation);
      expect(find.text('Chờ xác nhận'), findsOneWidget);
      expect(find.text('Trả QR'), findsNothing);
      await tester.tap(find.text('Xem bằng chứng'));
      expect(viewed?.paymentId, 'payment-1');
      expect(qrCalls, 0);
      await render(DebtStatus.awaiting);
      expect(find.text('Chờ xác nhận'), findsNothing);
      await tester.tap(find.text('Trả QR'));
      expect(qrCalls, 1);
    },
  );

  testWidgets('debtor receipt never offers approval or rejection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProofReviewSheet(
            proof: MockSettlementData.pendingProof,
            readOnly: true,
          ),
        ),
      ),
    );
    expect(find.text('Chi tiết thanh toán'), findsOneWidget);
    expect(
      find.textContaining('Chờ xác nhận từ người nhận tiền'),
      findsOneWidget,
    );
    expect(find.text('Xác nhận đã nhận tiền'), findsNothing);
    expect(find.text('Chưa nhận được tiền (Từ chối)'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.textContaining('Bạn chỉ có thể xác nhận'), findsNothing);
  });
}
