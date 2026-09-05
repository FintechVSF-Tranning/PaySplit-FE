import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/settlement_entities.dart';
import '../providers/settlement_controller.dart';
import 'proof_review_sheet.dart';

/// Reload on open so the receipt uses a fresh signed image URL.
class SubmittedProofSheet extends ConsumerStatefulWidget {
  const SubmittedProofSheet({required this.debt, super.key});

  final DebtItemEntity debt;

  static Future<void> show(BuildContext context, DebtItemEntity debt) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SubmittedProofSheet(debt: debt),
      );

  @override
  ConsumerState<SubmittedProofSheet> createState() =>
      _SubmittedProofSheetState();
}

class _SubmittedProofSheetState extends ConsumerState<SubmittedProofSheet> {
  late Future<ProofDetailEntity?> _proof;

  @override
  void initState() {
    super.initState();
    // Defer provider mutation until the modal has finished building.
    _proof = Future(_load);
  }

  Future<ProofDetailEntity?> _load() async {
    await ref
        .read(settlementControllerProvider.notifier)
        .loadData(rethrowOnError: true);
    if (!mounted) return null;
    final state = ref.read(settlementControllerProvider);
    return [
          ...state.submittedProofs,
          ...state.settledHistory.map((item) => item.proof),
        ]
        .where(
          (proof) =>
              proof.groupId == widget.debt.groupId &&
              proof.paymentId == widget.debt.paymentId,
        )
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ProofDetailEntity?>(
    future: _proof,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return ProofReviewSheet(proof: snapshot.data!, readOnly: true);
      }
      return Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.connectionState != ConnectionState.done)
                  const CircularProgressIndicator()
                else ...[
                  Text(
                    snapshot.hasError
                        ? 'Không tải được bằng chứng. Vui lòng thử lại.'
                        : 'Thanh toán đã thay đổi trạng thái hoặc không còn bằng chứng để xem.',
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _proof = Future(_load);
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
