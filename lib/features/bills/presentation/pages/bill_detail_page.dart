import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../providers/bill_detail_notifier.dart';
import '../widgets/bill_adjustments_section.dart';
import '../widgets/bill_breakdown_bottom_sheet.dart';
import '../widgets/bill_item_card.dart';
import '../widgets/bill_sticky_bottom_bar.dart';
import '../widgets/edit_item_dialog.dart';
import '../widgets/image_viewer_dialog.dart';
import '../widgets/ocr_candidate_review_modal.dart';
import '../widgets/select_even_split_members_modal.dart';

class BillDetailPage extends ConsumerStatefulWidget {
  final BillDetailEntity initialBill;
  final bool autoStartOcr;

  const BillDetailPage({
    super.key,
    required this.initialBill,
    this.autoStartOcr = false,
  });

  @override
  ConsumerState<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends ConsumerState<BillDetailPage> {
  late BillDetailEntity _initialBill;

  @override
  void initState() {
    super.initState();
    _initialBill = widget.initialBill;

    // Tự động kích hoạt OCR hoặc tải thông tin hoá đơn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user != null) {
        ref.read(billDetailNotifierProvider(_initialBill).notifier).setCurrentUserId(user.id);
      }

      if (widget.autoStartOcr && _initialBill.photos.isNotEmpty) {
        _openOcrReviewModal();
        ref.read(billDetailNotifierProvider(_initialBill).notifier).runOcrProcess(
              groupId: _initialBill.groupId,
              photos: _initialBill.photos,
              merchantName: _initialBill.merchantName,
            );
      } else if (_initialBill.groupId.isNotEmpty) {
        ref.read(billDetailNotifierProvider(_initialBill).notifier).loadBillDetail(
              billId: _initialBill.id,
              groupId: _initialBill.groupId,
            );
      }
    });
  }

  void _openOcrReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(billDetailNotifierProvider(_initialBill));
          final notifier = ref.read(billDetailNotifierProvider(_initialBill).notifier);

          return OcrCandidateReviewModal(
            isScanning: state.isOcrScanning,
            scanStep: state.ocrScanStep,
            candidate: state.ocrCandidate,
            errorMessage: state.ocrErrorMessage,
            photos: _initialBill.photos,
            onApply: () {
              notifier.applyOcrCandidate();
              Navigator.of(ctx).pop();
            },
            onDismiss: () {
              notifier.dismissOcrCandidate();
              Navigator.of(ctx).pop();
            },
            onRetry: () {
              notifier.runOcrProcess(
                groupId: _initialBill.groupId,
                photos: _initialBill.photos,
                merchantName: _initialBill.merchantName,
              );
            },
          );
        },
      ),
    );
  }

  void _showEditMerchantDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tên quán / Địa điểm',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nhập tên quán...',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF94A3B8)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Huỷ',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty) {
                      ref
                          .read(billDetailNotifierProvider(_initialBill).notifier)
                          .setMerchantName(newName);
                    }
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Lưu',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBankUpdateConfirmDialog(BuildContext context, BillDetailNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(HugeIcons.strokeRoundedCreditCardValidation, size: 20, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cập nhật tài khoản ngân hàng',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Hệ thống sẽ lưu bản nháp hoá đơn hiện tại và chuyển bạn đến trang Cài đặt tài khoản ngân hàng để cập nhật.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Huỷ',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await notifier.saveDraft();
                    if (context.mounted) {
                      await context.push(AppRoutes.bankSettings);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Lưu nháp & Chuyển',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUnassignedDetailDialog(BuildContext context, List<BillItemEntity> unassignedItems) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(HugeIcons.strokeRoundedUserMultiple, size: 20, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Món ăn chưa được chia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoá đơn hiện có ${unassignedItems.length} món chưa được gán cho bất kỳ thành viên nào trong nhóm:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final item in unassignedItems) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 5, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  CurrencyFormatter.formatVND(item.finalPrice.toDouble()),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Để đảm bảo công nợ được phân bổ chính xác cho mọi người, vui lòng gán người tham gia cho tất cả các món ăn trước khi chốt.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Đã hiểu',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMismatchDetailDialog(
    BuildContext context, {
    required int computedNetItemsTotal,
    required int serviceCharge,
    required int vat,
    required int generalDiscount,
    required int computedTotal,
    required int billTotal,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diff = computedTotal - billTotal;
    final diffText = diff > 0
        ? '+${CurrencyFormatter.formatVND(diff.toDouble())}'
        : '-${CurrencyFormatter.formatVND(diff.abs().toDouble())}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(HugeIcons.strokeRoundedReceiptDollar, size: 20, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chênh lệch tổng tiền',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng tiền tính toán từ các món và thuế phí đang không khớp với số tiền Tổng cộng ghi trên hoá đơn:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMismatchRow('Tiền món (Subtotal):', CurrencyFormatter.formatVND(computedNetItemsTotal.toDouble()), isDark: isDark),
                  const SizedBox(height: 4),
                  _buildMismatchRow('Phí dịch vụ:', serviceCharge > 0 ? '+ ${CurrencyFormatter.formatVND(serviceCharge.toDouble())}' : '0 đ', isDark: isDark),
                  const SizedBox(height: 4),
                  _buildMismatchRow('Thuế VAT:', vat > 0 ? '+ ${CurrencyFormatter.formatVND(vat.toDouble())}' : '0 đ', isDark: isDark),
                  const SizedBox(height: 4),
                  _buildMismatchRow('Giảm giá khác:', generalDiscount > 0 ? '- ${CurrencyFormatter.formatVND(generalDiscount.toDouble())}' : '0 đ', isDark: isDark),
                  const Divider(height: 12),
                  _buildMismatchRow('= Tổng tính toán:', CurrencyFormatter.formatVND(computedTotal.toDouble()), isBold: true, isDark: isDark),
                  const SizedBox(height: 4),
                  _buildMismatchRow('Tổng cộng trên bill:', CurrencyFormatter.formatVND(billTotal.toDouble()), isBold: true, isDark: isDark),
                  const Divider(height: 12),
                  _buildMismatchRow('Mức chênh lệch:', diffText, isBold: true, valueColor: const Color(0xFFDC2626), isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vui lòng điều chỉnh lại đơn giá các món hoặc bấm Chỉnh sửa trong mục Thuế, Phí & Khuyến mãi để số liệu được cân bằng.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Đã hiểu',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMismatchRow(String label, String value, {bool isBold = false, Color? valueColor, required bool isDark}) {
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? textMain : textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? textMain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.asData?.value;
    final hasBankAccount = currentUser == null || (currentUser.bankAccountNumber != null && currentUser.bankAccountNumber!.trim().isNotEmpty);

    final state = ref.watch(billDetailNotifierProvider(_initialBill));
    final notifier = ref.read(billDetailNotifierProvider(_initialBill).notifier);
    final bill = state.bill;

    final hasNoItems = state.bill.items.isEmpty;
    final hasUnassignedItems = !hasNoItems && state.unassignedCount > 0;
    final isTotalMismatch = !hasNoItems && state.computedTotal != state.bill.total;

    // Show toast feedback for success / error messages
    ref.listen(billDetailNotifierProvider(_initialBill), (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        showErrorSnackBar(context, next.errorMessage!);
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showSuccessSnackBar(context, next.successMessage!);
      }
    });

    final isNewUnsavedBill = bill.id.isEmpty || bill.id.startsWith('draft-');
    final currentUserId = currentUser?.id ?? '';
    final isCaptain = currentUserId.isEmpty || bill.members.isEmpty || bill.members.any((m) => m.userId == currentUserId && m.role == 'captain');
    final isCreditor = currentUserId.isEmpty || isNewUnsavedBill || bill.creditorMemberId.isEmpty || bill.members.any((m) => m.userId == currentUserId && m.memberId == bill.creditorMemberId);

    final isReadOnlyStatus = bill.status == 'finalized' || bill.status == 'voided';

    /// Quyền chỉnh sửa toàn bộ hoá đơn (sửa món, đổi giá, gán người, đổi cách chia):
    /// Cho phép Trưởng nhóm và Người tạo bill khi hóa đơn chưa chốt/hủy.
    final canEdit = !isReadOnlyStatus && (isCaptain || isCreditor || isNewUnsavedBill || bill.members.isEmpty);

    final formattedDate = bill.billDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(bill.billDate!)
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final isEvenSplit = bill.splitMethod == 'even';
    final totalGroupMemberCount = bill.members.length;
    final evenSelectedCount = state.activeEvenSplitMemberIds.length;
    final evenPerPersonAmount = state.evenPerPersonAmount;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: textMain),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  bill.merchantName?.isNotEmpty == true ? bill.merchantName! : 'Hoá đơn chi tiêu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showEditMerchantDialog(context, bill.merchantName ?? ''),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      HugeIcons.strokeRoundedEdit02,
                      size: 15,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // Xóa nháp chỉ dành cho hoá đơn đã lưu mà còn ở trạng thái draft:
            // đã chốt thì phải dùng "Huỷ hoá đơn" để giữ lại lịch sử, còn hoá
            // đơn chưa lưu thì thoát ra là xong.
            if (bill.status == 'draft' && !isNewUnsavedBill && canEdit)
              IconButton(
                onPressed: state.isDeleting
                    ? null
                    : () => _confirmDeleteDraft(context, notifier, bill),
                icon: state.isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        HugeIcons.strokeRoundedDelete02,
                        size: 20,
                        color: Color(0xFFEF4444),
                      ),
                tooltip: 'Xóa hoá đơn nháp',
              ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _buildStatusBadge(bill.status, isDark: isDark),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  // Left side: Payer Info & Date Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              HugeIcons.strokeRoundedUserCheck01,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Người trả: ${bill.creditorDisplayName}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              HugeIcons.strokeRoundedCalendar03,
                              size: 13,
                              color: textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side: Receipt Photos Thumbnail (tap to view/rotate)
                  if (bill.photos.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => ImageViewerDialog.show(context, photos: bill.photos),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                bill.photos.first.bytes,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (bill.photos.length > 1)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${bill.photos.length}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Line Items Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              HugeIcons.strokeRoundedRestaurant01,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Danh sách món ăn (${bill.items.length})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textMain,
                              ),
                            ),
                          ],
                        ),
                        if (canEdit)
                          TextButton.icon(
                            onPressed: () {
                              EditItemDialog.show(
                                context,
                                members: bill.members,
                                isEvenSplit: isEvenSplit,
                                onSave: (newItem) => notifier.addItem(newItem),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(HugeIcons.strokeRoundedPlusSign, size: 16),
                            label: Text(
                              'Thêm món',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // 2. Concise Even Split Sub-Row with Link to select participants (Only show when user has edit permission)
                    if (canEdit) ...[
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.75,
                            alignment: Alignment.centerLeft,
                            child: Switch.adaptive(
                              value: isEvenSplit,
                              activeTrackColor: AppColors.primary,
                              onChanged: canEdit
                                  ? (val) {
                                      notifier.setSplitMode(val ? 'even' : 'item_ratio');
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: isEvenSplit
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Chia đều: ${CurrencyFormatter.formatVND(evenPerPersonAmount.toDouble())}/người',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '·',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF059669),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: canEdit
                                            ? () {
                                                SelectEvenSplitMembersModal.show(
                                                  context,
                                                  members: bill.members,
                                                  initialSelectedMemberIds: state.activeEvenSplitMemberIds,
                                                  creditorMemberId: bill.creditorMemberId,
                                                  onConfirm: (selectedIds) {
                                                    notifier.setEvenSplitMembers(selectedIds);
                                                  },
                                                );
                                              }
                                            : null,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$evenSelectedCount/$totalGroupMemberCount người',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                HugeIcons.strokeRoundedArrowDown01,
                                                size: 13,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Chia đều tổng hoá đơn',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: textMuted,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // 3. Line Items List (Hỗ trợ thêm, xóa, sửa cả khi bật và tắt chia đều)
                    if (bill.items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              HugeIcons.strokeRoundedInvoice03,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Chưa có món ăn nào',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                            if (canEdit) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  EditItemDialog.show(
                                    context,
                                    members: bill.members,
                                    isEvenSplit: isEvenSplit,
                                    onSave: (newItem) => notifier.addItem(newItem),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(HugeIcons.strokeRoundedPlusSign, size: 16),
                                label: const Text('Thêm món đầu tiên'),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      for (int i = 0; i < bill.items.length; i++) ...[
                        BillItemCard(
                          item: bill.items[i],
                          members: bill.members,
                          itemIndex: i,
                          isEvenSplit: isEvenSplit,
                          isEditable: canEdit,
                          canAssign: canEdit,
                          onTap: () {
                            EditItemDialog.show(
                              context,
                              item: bill.items[i],
                              members: bill.members,
                              isEvenSplit: isEvenSplit,
                              isEditable: canEdit,
                              onSave: canEdit
                                  ? (updated) => notifier.updateItem(updated)
                                  : null,
                              onDelete: canEdit
                                  ? () => notifier.deleteItem(bill.items[i].id)
                                  : null,
                            );
                          },
                          onDelete: () => notifier.deleteItem(bill.items[i].id),
                          onToggleMember: (mId) => notifier.toggleMemberAssignment(bill.items[i].id, mId),
                          onAssignAll: () => notifier.assignAllMembersToItem(bill.items[i].id),
                        ),
                      ],
                    const SizedBox(height: 16),

                    // 4. Taxes, Surcharges & Discounts Section
                    BillAdjustmentsSection(
                      bill: bill,
                      computedGrossSubtotal: state.computedGrossSubtotal,
                      computedTotalItemDiscount: state.computedTotalItemDiscount,
                      computedNetItemsTotal: state.computedNetItemsTotal,
                      computedTotal: state.computedTotal,
                      isEditable: canEdit,
                      onUpdateAdjustments: ({serviceCharge, vat, generalDiscount, total}) {
                        notifier.setAdjustments(
                          serviceCharge: serviceCharge,
                          vat: vat,
                          generalDiscount: generalDiscount,
                          total: total,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
        bottomNavigationBar: state.isLoading
            ? null
            : BillStickyBottomBar(
                bill: bill,
                breakdown: state.breakdown,
                isSaving: state.isSaving,
                isFinalizing: state.isFinalizing,
                isVoiding: state.isVoiding,
                isCalculatingBreakdown: state.isCalculatingBreakdown,
                hasBankAccount: hasBankAccount,
                hasNoItems: hasNoItems,
                hasUnassignedItems: hasUnassignedItems,
                isTotalMismatch: isTotalMismatch,
                isCaptain: isCaptain,
                isCreditor: isCreditor,
                isEditable: canEdit,
                isDirty: state.isDirty,
                onUpdateBankAccount: () => _showBankUpdateConfirmDialog(context, notifier),
                onOpenUnassignedDetail: () {
                  final unassignedItems = state.bill.items.where((i) => i.assignments.isEmpty).toList();
                  _showUnassignedDetailDialog(context, unassignedItems);
                },
                onOpenMismatchDetail: () {
                  _showMismatchDetailDialog(
                    context,
                    computedNetItemsTotal: state.computedNetItemsTotal,
                    serviceCharge: state.bill.serviceCharge,
                    vat: state.bill.vat,
                    generalDiscount: state.bill.generalDiscount,
                    computedTotal: state.computedTotal,
                    billTotal: state.bill.total,
                  );
                },
                onSaveDraft: () => notifier.saveDraft(),
                onReview: () => notifier.reviewBillOnly(),
                onVoid: () => _showVoidBillDialog(context, notifier),
                onOpenBreakdown: () async {
                  final officialBreakdown = await notifier.fetchOfficialBreakdown();
                  if (context.mounted) {
                    final latestState = ref.read(billDetailNotifierProvider(_initialBill));
                    await BillBreakdownBottomSheet.show(
                      context,
                      breakdown: officialBreakdown.isNotEmpty ? officialBreakdown : latestState.breakdown,
                      totalAmount: latestState.bill.total,
                    );
                  }
                },
              onFinalize: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Xác nhận chốt hoá đơn?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: Text(
                      'Hoá đơn sau khi chốt sổ sẽ tự động tạo công nợ cho các thành viên trong nhóm và không thể chỉnh sửa.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFF4B5563),
                        height: 1.45,
                      ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    actions: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                foregroundColor: const Color(0xFF4B5563),
                              ),
                              child: Text(
                                'Huỷ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Chốt hoá đơn',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final success = await notifier.finalizeBill();
                  if (success && context.mounted) {
                    showSuccessSnackBar(context, 'Chốt hoá đơn thành công!');
                  }
                }
              },
            ),
      );
  }

  /// Xác nhận trước khi xóa: thao tác này không hoàn tác được và cũng xóa luôn
  /// ảnh hóa đơn đã tải lên.
  Future<void> _confirmDeleteDraft(
    BuildContext context,
    BillDetailNotifier notifier,
    BillDetailEntity bill,
  ) async {
    final billName = bill.merchantName?.isNotEmpty == true
        ? bill.merchantName!
        : 'hoá đơn nháp này';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Xóa hoá đơn nháp?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Text(
          'Toàn bộ nội dung và ảnh của "$billName" sẽ bị xóa vĩnh viễn. '
          'Thao tác này không thể hoàn tác.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa hoá đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await notifier.deleteDraftBill();
    if (!deleted || !context.mounted) return;

    showSuccessSnackBar(context, 'Đã xóa hoá đơn nháp');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _showVoidBillDialog(BuildContext context, BillDetailNotifier notifier) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(HugeIcons.strokeRoundedDelete02, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Huỷ hoá đơn đã chốt',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sau khi huỷ, hoá đơn này sẽ bị vô hiệu hoá và toàn bộ công nợ liên quan trong nhóm sẽ được huỷ bỏ.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lý do huỷ hoá đơn *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  maxLength: 500,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập lý do huỷ (VD: Sai số tiền, tính nhầm món...)',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập lý do huỷ';
                    }
                    if (val.trim().length < 3) {
                      return 'Lý do phải có ít nhất 3 ký tự';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                      ),
                      foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
                    ),
                    child: Text(
                      'Đóng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.of(ctx).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Xác nhận huỷ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final success = await notifier.voidBill(reason: reasonController.text.trim());
      if (success && context.mounted) {
        showSuccessSnackBar(context, 'Đã huỷ hoá đơn thành công!');
      }
    }
  }

  Widget _buildStatusBadge(String status, {required bool isDark}) {
    String label;
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case 'reviewed':
        label = 'Chờ duyệt';
        bgColor = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF);
        textColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
        borderColor = isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE);
        break;
      case 'finalized':
        label = 'Đã chốt';
        bgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5);
        textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
        borderColor = isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0);
        break;
      case 'voided':
        label = 'Đã hủy';
        bgColor = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEF2F2);
        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
        borderColor = isDark ? const Color(0xFFB91C1C) : const Color(0xFFFECACA);
        break;
      case 'draft':
      default:
        label = 'Nháp';
        bgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFFFBEB);
        textColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
        borderColor = isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
