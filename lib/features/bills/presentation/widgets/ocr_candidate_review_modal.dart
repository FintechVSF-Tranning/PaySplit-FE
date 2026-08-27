import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';

class OcrCandidateReviewModal extends StatefulWidget {
  final bool isScanning;
  final String? scanStep;
  final BillDetailEntity? candidate;
  final String? errorMessage;
  final List<CapturedBillPhoto> photos;
  final VoidCallback onApply;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const OcrCandidateReviewModal({
    super.key,
    required this.isScanning,
    this.scanStep,
    this.candidate,
    this.errorMessage,
    required this.photos,
    required this.onApply,
    required this.onDismiss,
    required this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isScanning,
    String? scanStep,
    BillDetailEntity? candidate,
    String? errorMessage,
    required List<CapturedBillPhoto> photos,
    required VoidCallback onApply,
    required VoidCallback onDismiss,
    required VoidCallback onRetry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !isScanning,
      enableDrag: !isScanning,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OcrCandidateReviewModal(
        isScanning: isScanning,
        scanStep: scanStep,
        candidate: candidate,
        errorMessage: errorMessage,
        photos: photos,
        onApply: onApply,
        onDismiss: onDismiss,
        onRetry: onRetry,
      ),
    );
  }

  @override
  State<OcrCandidateReviewModal> createState() => _OcrCandidateReviewModalState();
}

class _OcrCandidateReviewModalState extends State<OcrCandidateReviewModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 16
            : 24,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Body based on OCR State
              if (widget.isScanning)
                _buildScanningState(context, isDark, textMain, textMuted)
              else if (widget.errorMessage != null)
                _buildErrorState(context, isDark, textMain, textMuted)
              else if (widget.candidate != null)
                _buildSuccessCandidateState(context, isDark, textMain, textMuted, border)
              else
                _buildScanningState(context, isDark, textMain, textMuted),
            ],
          ),
        ),
      ),
    );
  }

  /// ⏳ Trạng thái đang tải chỉ hiển thị Skeleton Shimmer thuần tuý, không có chữ
  Widget _buildScanningState(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textMuted,
  ) {
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final skeletonBase = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final shimmerColor = skeletonBase.withValues(alpha: _glowAnimation.value + 0.3);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Skeleton
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 90,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 45,
                      height: 10,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 18,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Items List Skeleton
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  _buildSkeletonItemRow(shimmerColor, 120, 65),
                  Divider(color: border, height: 16),
                  _buildSkeletonItemRow(shimmerColor, 150, 75),
                  Divider(color: border, height: 16),
                  _buildSkeletonItemRow(shimmerColor, 105, 55),
                  Divider(color: border, height: 16),
                  _buildSkeletonItemRow(shimmerColor, 135, 70),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Pill Chips Skeleton
            Row(
              children: [
                Container(
                  width: 75,
                  height: 22,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 65,
                  height: 22,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 85,
                  height: 22,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Action Buttons (Skeleton Apply + Manual Entry)
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),

            AppButton(
              label: 'Bỏ qua & Tự nhập tay',
              variant: AppButtonVariant.outline,
              icon: const Icon(HugeIcons.strokeRoundedEdit02, size: 17),
              onPressed: widget.onDismiss,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkeletonItemRow(Color color, double nameWidth, double priceWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: nameWidth,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 26,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: priceWidth,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Trạng thái bóc tách thành công (Xem trước candidate và áp dụng)
  Widget _buildSuccessCandidateState(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textMuted,
    Color border,
  ) {
    final candidate = widget.candidate!;
    final items = candidate.items;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã nhận diện ${items.length} món ăn!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quán: ${candidate.merchantName?.isNotEmpty == true ? candidate.merchantName : "Hoá đơn chi tiêu"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TỔNG CỘNG',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textMuted,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatVND(candidate.total.toDouble()),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Scrollable List of Parsed Items
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Không tìm thấy dòng món nào trong ảnh',
                      style: GoogleFonts.plusJakartaSans(color: textMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(color: border, height: 1),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final hasDiscount = item.discountAmount > 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: border),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'KM: -${CurrencyFormatter.formatVND(item.discountAmount.toDouble())}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.formatVND(item.finalPrice.toDouble()),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                              if (hasDiscount)
                                Text(
                                  CurrencyFormatter.formatVND(item.lineTotal.toDouble()),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    color: textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),

        // Summary chips for adjustments if any
        if (candidate.serviceCharge > 0 || candidate.vat > 0 || candidate.generalDiscount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (candidate.serviceCharge > 0)
                  _buildPillTag(
                    'Phí DV: +${CurrencyFormatter.formatVND(candidate.serviceCharge.toDouble())}',
                    const Color(0xFF0F766E),
                    const Color(0xFFF0FDFA),
                  ),
                if (candidate.vat > 0)
                  _buildPillTag(
                    'VAT: +${CurrencyFormatter.formatVND(candidate.vat.toDouble())}',
                    const Color(0xFF2563EB),
                    const Color(0xFFEFF6FF),
                  ),
                if (candidate.generalDiscount > 0)
                  _buildPillTag(
                    'Voucher: -${CurrencyFormatter.formatVND(candidate.generalDiscount.toDouble())}',
                    const Color(0xFF059669),
                    const Color(0xFFECFDF5),
                  ),
              ],
            ),
          ),

        // Action Buttons
        AppButton(
          label: 'Áp dụng vào hoá đơn (${items.length} món)',
          variant: AppButtonVariant.gradient,
          icon: const Icon(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            size: 18,
            color: Colors.white,
          ),
          onPressed: widget.onApply,
        ),
        const SizedBox(height: 8),

        AppButton(
          label: 'Không áp dụng, tự nhập tay',
          variant: AppButtonVariant.outline,
          icon: const Icon(HugeIcons.strokeRoundedEdit02, size: 17),
          onPressed: widget.onDismiss,
        ),
      ],
    );
  }

  Widget _buildPillTag(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  /// ❌ Trạng thái lỗi bóc tách
  Widget _buildErrorState(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textMuted,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFEF2F2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            HugeIcons.strokeRoundedAlertCircle,
            color: Color(0xFFDC2626),
            size: 36,
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Không thể tự động nhận diện hoá đơn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
        const SizedBox(height: 6),

        Text(
          widget.errorMessage ??
              'Ảnh chụp hoá đơn có thể bị mờ, lóa hoặc kết nối mạng không ổn định.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        AppButton(
          label: 'Thử quét lại',
          icon: const Icon(HugeIcons.strokeRoundedReload, size: 18, color: Colors.white),
          onPressed: widget.onRetry,
        ),
        const SizedBox(height: 8),

        AppButton(
          label: 'Bỏ qua & Tự nhập tay',
          variant: AppButtonVariant.outline,
          onPressed: widget.onDismiss,
        ),
      ],
    );
  }
}
