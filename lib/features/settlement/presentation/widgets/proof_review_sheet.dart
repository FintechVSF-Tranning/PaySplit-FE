import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../domain/entities/settlement_entities.dart';

class ProofReviewSheet extends StatefulWidget {
  const ProofReviewSheet({
    required this.proof,
    this.onConfirm,
    this.readOnly = false,
    this.onReject,
    super.key,
  });

  final ProofDetailEntity proof;
  final bool readOnly;
  final Future<void> Function()? onConfirm;
  final VoidCallback? onReject;

  @override
  State<ProofReviewSheet> createState() => _ProofReviewSheetState();
}

class _ProofReviewSheetState extends State<ProofReviewSheet> {
  bool _imageLoaded = false;
  bool _imageFailed = false;
  bool _isConfirming = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    if (_isConfirming || !_imageLoaded || widget.onConfirm == null) return;
    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });
    try {
      await widget.onConfirm!();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể xác nhận thanh toán. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _markImageLoaded() {
    if (_imageLoaded || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _imageLoaded = true);
    });
  }

  void _markImageFailed() {
    if (_imageFailed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _imageFailed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final proof = widget.proof;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppColors.darkTextMain : AppColors.textMain;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final proofUrl = proof.proofImageUrl;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    (proof.isSettled || widget.readOnly)
                        ? 'Chi tiết thanh toán'
                        : 'Duyệt bằng chứng chuyển tiền',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isConfirming
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: proof.isSettled
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                proof.isSettled
                    ? 'Giao dịch đã được đối soát và ghi nhận số dư.'
                    : widget.readOnly
                    ? 'Chờ xác nhận từ người nhận tiền. Bạn đã gửi bằng chứng thanh toán.'
                    : 'Biên lai do người trả gửi, chưa được PaySplit xác minh.',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: proof.isSettled
                      ? const Color(0xFF047857)
                      : const Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: proofUrl != null
                  ? () {
                      FullScreenImageViewer.show(
                        context,
                        imageUrl: proofUrl,
                        title: 'Bằng chứng chuyển tiền',
                        subtitle:
                            '${proof.debtorName} • ${CurrencyFormatter.vnd(proof.amount)}',
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSubtle
                        : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: proofUrl == null
                            ? _proofError('Biên lai không có ảnh để kiểm tra')
                            : Image.network(
                                proofUrl,
                                key: const Key('proof-image'),
                                fit: BoxFit.contain,
                                semanticLabel: 'Ảnh biên lai chuyển tiền',
                                frameBuilder:
                                    (context, child, frame, syncLoaded) {
                                      if (syncLoaded || frame != null) {
                                        _markImageLoaded();
                                      }
                                      return child;
                                    },
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  _markImageFailed();
                                  return _proofError(
                                    'Không tải được ảnh biên lai. Hãy thử mở lại để lấy liên kết mới.',
                                  );
                                },
                              ),
                      ),
                      if (proofUrl != null)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  HugeIcons.strokeRoundedMaximize02,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Chạm để phóng to',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _row(
              'Số tiền',
              CurrencyFormatter.vnd(proof.amount),
              textMain,
              textMuted,
            ),
            _row('Ngân hàng nhận', proof.targetBank, textMain, textMuted),
            _row('Tài khoản nhận', proof.targetAccount, textMain, textMuted),
            _row('Nội dung chuyển', proof.referenceCode, textMain, textMuted),
            _row(
              'Thời điểm gửi',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(proof.submittedAt.toLocal()),
              textMain,
              textMuted,
            ),
            if (proof.note != null)
              _row('Lời nhắn', proof.note!, textMain, textMuted),
            if (_imageFailed && !proof.isSettled && !widget.readOnly) ...[
              const SizedBox(height: 8),
              const Text(
                'Bạn chỉ có thể xác nhận sau khi xem được ảnh biên lai.',
                style: TextStyle(color: AppColors.danger),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                key: const Key('proof-confirm-error'),
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 18),
            if (!proof.isSettled && !widget.readOnly) ...[
              AppButton(
                label: 'Xác nhận đã nhận tiền',
                icon: const Icon(
                  HugeIcons.strokeRoundedCheckmarkCircle02,
                  size: 18,
                  color: Colors.white,
                ),
                isLoading: _isConfirming,
                onPressed: _imageLoaded && !_isConfirming ? _confirm : null,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Chưa nhận được tiền (Từ chối)',
                variant: AppButtonVariant.danger,
                onPressed: _isConfirming
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onReject?.call();
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _proofError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _row(String label, String value, Color textMain, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textMain,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
