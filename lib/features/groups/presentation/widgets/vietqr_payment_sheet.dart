import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/group_debt_entity.dart';
import 'mock_qr_code.dart';
import 'sheet_shell.dart';

/// Dynamic VietQR Sheet: trả một khoản nợ trong nhóm bằng QR NAPAS 247.
///
/// Thông tin ngân hàng đang là mock; khi nối API thật, lấy từ hồ sơ ngân hàng
/// của chủ nợ và dùng ảnh QR do backend sinh (`GET /payments/{id}/qr`).
/// Trả về `true` khi người dùng đã nộp ảnh biên lai.
class VietQrPaymentSheet extends StatelessWidget {
  const VietQrPaymentSheet({super.key, required this.debt, required this.groupName});

  final GroupDebtEntity debt;
  final String groupName;

  static Future<bool?> show(
    BuildContext context, {
    required GroupDebtEntity debt,
    required String groupName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VietQrPaymentSheet(debt: debt, groupName: groupName),
    );
  }

  static const _bankName = 'Vietcombank';
  static const _accountNumber = '0071000812345';
  static const _accountHolder = 'TRAN LAM';

  String get _transferNote => debt.transferRef.isNotEmpty ? debt.transferRef : 'PAYSPLIT TRA NO';

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Thanh toán qua VietQR',
      subtitle: 'Quét mã bằng app ngân hàng, số tiền và nội dung đã được điền sẵn.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    'Bạn trả ${debt.counterpartName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.vnd(debt.amount),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MockQrCode(
                    data: 'VIETQR|$_accountNumber|${debt.amount}|$_transferNote',
                    size: 208,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Ngân hàng', value: _bankName),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Chủ tài khoản', value: _accountHolder),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Số tài khoản', value: _accountNumber, isMono: true),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Nội dung CK', value: _transferNote, isMono: true),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Nhóm', value: groupName),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Sao chép STK',
                    variant: AppButtonVariant.outline,
                    icon: const Icon(HugeIcons.strokeRoundedCopy01, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(text: _accountNumber));
                      await HapticFeedback.lightImpact();
                      if (!context.mounted) return;
                      showSuccessSnackBar(context, 'Đã sao chép số tài khoản');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Lưu ảnh QR',
                    variant: AppButtonVariant.outline,
                    icon: const Icon(HugeIcons.strokeRoundedQrCode, size: 18),
                    onPressed: () => showComingSoonSnackBar(context, 'Lưu ảnh QR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Mở app ngân hàng',
              variant: AppButtonVariant.ghost,
              onPressed: () => showComingSoonSnackBar(context, 'Mở app ngân hàng'),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Tải ảnh biên lai đã chuyển',
              variant: AppButtonVariant.gradient,
              icon: const Icon(HugeIcons.strokeRoundedCamera01, size: 18, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.isMono = false});

  final String label;
  final String value;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
