import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_detail_entity.dart';

class BillAdjustmentsSection extends StatelessWidget {
  final BillDetailEntity bill;
  final int computedGrossSubtotal;
  final int computedTotalItemDiscount;
  final int computedNetItemsTotal;
  final int computedTotal;
  final bool isEditable;
  final Function({int? serviceCharge, int? vat, int? generalDiscount, int? total}) onUpdateAdjustments;

  const BillAdjustmentsSection({
    super.key,
    required this.bill,
    required this.computedGrossSubtotal,
    required this.computedTotalItemDiscount,
    required this.computedNetItemsTotal,
    required this.computedTotal,
    this.isEditable = true,
    required this.onUpdateAdjustments,
  });

  void _openAdjustmentsDialog(BuildContext context) {
    if (!isEditable) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditAdjustmentsModal(
        bill: bill,
        computedGrossSubtotal: computedGrossSubtotal,
        computedTotalItemDiscount: computedTotalItemDiscount,
        computedNetItemsTotal: computedNetItemsTotal,
        onSave: onUpdateAdjustments,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final displayTotal = bill.total;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      HugeIcons.strokeRoundedReceiptDollar,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thuế, Phí & Khuyến mãi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                  ],
                ),
                if (isEditable)
                  TextButton.icon(
                    onPressed: () => _openAdjustmentsDialog(context),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(HugeIcons.strokeRoundedEdit02, size: 15),
                    label: Text(
                      'Chỉnh sửa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Detailed Breakdown Rows (same format across all items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildRow(
                  'Phí dịch vụ:',
                  bill.serviceCharge > 0
                      ? '+ ${CurrencyFormatter.formatVND(bill.serviceCharge.toDouble())}'
                      : '0 đ',
                  textMain,
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildRow(
                  'Thuế VAT:',
                  bill.vat > 0 ? '+ ${CurrencyFormatter.formatVND(bill.vat.toDouble())}' : '0 đ',
                  textMain,
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildRow(
                  'Giảm giá khác:',
                  bill.generalDiscount > 0
                      ? '- ${CurrencyFormatter.formatVND(bill.generalDiscount.toDouble())}'
                      : '0 đ',
                  bill.generalDiscount > 0 ? const Color(0xFF059669) : textMain,
                  textMuted,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _buildRow(
                  'Tổng cộng:',
                  CurrencyFormatter.formatVND(displayTotal.toDouble()),
                  textMain,
                  textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: labelColor),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditAdjustmentsModal extends StatefulWidget {
  final BillDetailEntity bill;
  final int computedGrossSubtotal;
  final int computedTotalItemDiscount;
  final int computedNetItemsTotal;
  final Function({int? serviceCharge, int? vat, int? generalDiscount, int? total}) onSave;

  const _EditAdjustmentsModal({
    required this.bill,
    required this.computedGrossSubtotal,
    required this.computedTotalItemDiscount,
    required this.computedNetItemsTotal,
    required this.onSave,
  });

  @override
  State<_EditAdjustmentsModal> createState() => _EditAdjustmentsModalState();
}

class _EditAdjustmentsModalState extends State<_EditAdjustmentsModal> {
  late TextEditingController _serviceController;
  late TextEditingController _vatController;
  late TextEditingController _discountController;
  late TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(
      text: widget.bill.serviceCharge > 0 ? widget.bill.serviceCharge.toString() : '',
    );
    _vatController = TextEditingController(
      text: widget.bill.vat > 0 ? widget.bill.vat.toString() : '',
    );
    _discountController = TextEditingController(
      text: widget.bill.generalDiscount > 0 ? widget.bill.generalDiscount.toString() : '',
    );
    _totalController = TextEditingController(
      text: widget.bill.total > 0 ? widget.bill.total.toString() : '',
    );
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _vatController.dispose();
    _discountController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  int get _serviceCharge => int.tryParse(_serviceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _vat => int.tryParse(_vatController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _generalDiscount => int.tryParse(_discountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _total => int.tryParse(_totalController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

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
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
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
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chỉnh sửa Thuế & Phụ phí',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 20),
                  color: textMuted,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. Phí dịch vụ
            Text(
              'Phí dịch vụ (VND)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _serviceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'đ',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Thuế VAT
            Text(
              'Thuế VAT (VND)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _vatController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'đ',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Giảm giá khác
            Text(
              'Giảm giá khác (VND)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'đ',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Tổng cộng
            Text(
              'Tổng cộng (VND)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'đ',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(
                    serviceCharge: _serviceCharge,
                    vat: _vat,
                    generalDiscount: _generalDiscount,
                    total: _total,
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Lưu & Áp dụng',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
