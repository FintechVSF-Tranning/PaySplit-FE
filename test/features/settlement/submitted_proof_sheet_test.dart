import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/settlement/data/mock/mock_settlement_data.dart';
import 'package:paysplit/features/settlement/data/mock/mock_settlement_repository.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/providers/settlement_controller.dart';
import 'package:paysplit/features/settlement/presentation/widgets/proof_review_sheet.dart';
import 'package:paysplit/features/settlement/presentation/widgets/submitted_proof_sheet.dart';

void main() {
  testWidgets('loads submitted receipt and retries after a network failure', (
    tester,
  ) async {
    final repository = _ReceiptRepository();
    final debt = MockSettlementData.payableDebts.first.copyWith(
      status: DebtStatus.pendingConfirmation,
      paymentId: MockSettlementData.pendingProof.paymentId,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settlementRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(body: SubmittedProofSheet(debt: debt)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Không tải được bằng chứng. Vui lòng thử lại.'),
      findsOneWidget,
    );
    repository.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    final sheet = tester.widget<ProofReviewSheet>(
      find.byType(ProofReviewSheet),
    );
    expect(sheet.readOnly, isTrue);
    expect(sheet.proof.paymentId, debt.paymentId);
    expect(sheet.proof.groupId, debt.groupId);
    expect(find.text('Xác nhận đã nhận tiền'), findsNothing);
    expect(find.text('Chưa nhận được tiền (Từ chối)'), findsNothing);
  });
}

class _ReceiptRepository extends MockSettlementRepository {
  bool fail = true;

  @override
  Future<SettlementDataEntity> loadSettlement() async {
    if (fail) throw StateError('offline');
    final data = await super.loadSettlement();
    return SettlementDataEntity(
      overview: data.overview,
      payableDebts: data.payableDebts,
      receivableDebts: data.receivableDebts,
      groupedDebts: data.groupedDebts,
      pendingProofs: const [],
      submittedProofs: [MockSettlementData.pendingProof],
      settledHistory: data.settledHistory,
      bills: data.bills,
    );
  }
}
