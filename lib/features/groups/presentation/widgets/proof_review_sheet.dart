import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/group_debt_entity.dart';
import 'sheet_shell.dart';

/// Kết quả chủ nợ chọn khi duyệt minh chứng thanh toán.
sealed class ProofReviewResult {
  const ProofReviewResult();
}

class ProofApproved extends ProofReviewResult {
  const ProofApproved();
}

class ProofRejected extends ProofReviewResult {
  const ProofRejected(this.reason);

  final String reason;
}

/// Sheet đối soát minh chứng chuyển khoản do người nợ nộp lên.
class ProofReviewSheet extends StatefulWidget {
  const ProofReviewSheet({super.key, required this.debt});

  final GroupDebtEntity debt;

  static Future<ProofReviewResult?> show(BuildContext context, GroupDebtEntity debt) {
    return showModalBottomSheet<ProofReviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofReviewSheet(debt: debt),
    );
  }

  @override
  State<ProofReviewSheet> createState() => _ProofReviewSheetState();
}

class _ProofReviewSheetState extends State<ProofReviewSheet> {
  final _reasonController = TextEditingController();
  bool _isRejecting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop(const ProofApproved());
  }

  void _confirmReject() {
    final reason = _reasonController.text.trim();
    Navigator.of(
      context,
    ).pop(ProofRejected(reason.isEmpty ? 'Chưa thấy tiền về tài khoản' : reason));
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;

    return SheetShell(
      title: 'Duyệt minh chứng',
      subtitle: '${debt.counterpartName} vừa nộp minh chứng thanh toán.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _Row(label: 'Người chuyển', value: debt.counterpartName),
                  const SizedBox(height: 10),
                  _Row(label: 'Số tiền', value: CurrencyFormatter.vnd(debt.amount), isMono: true),
                  const SizedBox(height: 10),
                  const _Row(label: 'Thời gian', value: '10:30, hôm nay'),
                  const SizedBox(height: 10),
                  const _Row(label: 'Mã giao dịch', value: 'FT26082412345', isMono: true),
                  const SizedBox(height: 10),
                  const _Row(label: 'Lời nhắn', value: 'Cảm ơn mọi người'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Ảnh biên lai — placeholder cho tới khi có upload thật.
            Container(
              height: 168,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(HugeIcons.strokeRoundedImage02, size: 30, color: AppColors.textSubtle),
                  const SizedBox(height: 8),
                  Text(
                    'Ảnh biên lai ngân hàng\n(chạm để phóng to)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (_isRejecting) ...[
              Text(
                'Lý do từ chối',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.dangerBorder, width: 1.4),
                ),
                child: TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    hintText: 'Ví dụ: chưa thấy tiền về tài khoản',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Quay lại',
                      variant: AppButtonVariant.outline,
                      onPressed: () => setState(() => _isRejecting = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Gửi từ chối',
                      variant: AppButtonVariant.danger,
                      onPressed: _confirmReject,
                    ),
                  ),
                ],
              ),
            ] else ...[
              AppButton(
                label: 'Xác nhận đã nhận tiền',
                variant: AppButtonVariant.gradient,
                icon: const Icon(
                  HugeIcons.strokeRoundedCheckmarkCircle02,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: _approve,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Chưa nhận được tiền',
                variant: AppButtonVariant.outline,
                icon: const Icon(
                  HugeIcons.strokeRoundedCancel01,
                  size: 18,
                  color: AppColors.danger,
                ),
                onPressed: () => setState(() => _isRejecting = true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isMono = false});

  final String label;
  final String value;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isMono
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  )
                : GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
          ),
        ),
      ],
    );
  }
}
