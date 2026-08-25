import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/bill_detail_entity.dart';

class EditItemDialog extends StatefulWidget {
  final BillItemEntity? item; // null if adding new item
  final List<BillMemberEntity> members;
  final bool isEvenSplit;
  final Function(BillItemEntity item) onSave;
  final VoidCallback? onDelete;

  const EditItemDialog({
    super.key,
    this.item,
    required this.members,
    this.isEvenSplit = false,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    BillItemEntity? item,
    required List<BillMemberEntity> members,
    bool isEvenSplit = false,
    required Function(BillItemEntity item) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditItemDialog(
        item: item,
        members: members,
        isEvenSplit: isEvenSplit,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;

  final Set<String> _selectedMemberIds = {};
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _qtyController = TextEditingController(text: item?.quantity ?? '1');

    int initialUnitPrice = 0;
    if (item != null) {
      if (item.unitPrice > 0) {
        initialUnitPrice = item.unitPrice;
      } else {
        final q = int.tryParse(item.quantity) ?? 1;
        initialUnitPrice = q > 0 ? (item.lineTotal / q).round() : item.lineTotal;
      }
    }

    int initialUnitDiscount = 0;
    if (item != null && item.discountAmount > 0) {
      final q = int.tryParse(item.quantity) ?? 1;
      initialUnitDiscount = q > 0 ? (item.discountAmount / q).round() : item.discountAmount;
    }

    _priceController = TextEditingController(
      text: initialUnitPrice > 0
          ? initialUnitPrice.toString()
          : (item != null && item.lineTotal > 0 ? item.lineTotal.toString() : ''),
    );
    _discountController = TextEditingController(
      text: initialUnitDiscount > 0 ? initialUnitDiscount.toString() : '',
    );

    if (item != null && item.assignments.isNotEmpty) {
      _selectedMemberIds.addAll(item.assignments.map((a) => a.memberId));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  int get _parsedPrice => int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _parsedQty {
    final val = int.tryParse(_qtyController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return val > 0 ? val : 1;
  }
  int get _parsedUnitDiscount => int.tryParse(_discountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  int get _lineTotal => _parsedPrice * _parsedQty;
  int get _totalDiscount => _parsedUnitDiscount * _parsedQty;
  int get _finalPrice => (_lineTotal - _totalDiscount).clamp(0, _lineTotal);

  void _toggleAllMembers() {
    setState(() {
      if (_selectedMemberIds.length == widget.members.length) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds.clear();
        _selectedMemberIds.addAll(widget.members.map((m) => m.memberId));
      }
    });
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Vui lòng nhập tên món ăn';
      });
      return;
    }

    final assignments = widget.isEvenSplit
        ? widget.members.map((m) {
            return BillItemAssignmentEntity(
              memberId: m.memberId,
              userId: m.userId,
              displayName: m.displayName,
              avatarUrl: m.avatarUrl,
              weight: widget.members.isNotEmpty ? (1.0 / widget.members.length) : 1.0,
            );
          }).toList()
        : _selectedMemberIds.map((mId) {
            final m = widget.members.firstWhere(
              (mem) => mem.memberId == mId,
              orElse: () => BillMemberEntity(memberId: mId, userId: '', displayName: 'Thành viên'),
            );
            return BillItemAssignmentEntity(
              memberId: mId,
              userId: m.userId,
              displayName: m.displayName,
              avatarUrl: m.avatarUrl,
              weight: _selectedMemberIds.isNotEmpty ? (1.0 / _selectedMemberIds.length) : 1.0,
            );
          }).toList();

    final existingId = widget.item?.id;
    final effectiveId = (existingId != null && existingId.trim().isNotEmpty)
        ? existingId.trim()
        : 'item-${DateTime.now().microsecondsSinceEpoch}';

    final item = BillItemEntity(
      id: effectiveId,
      name: name,
      quantity: _parsedQty.toString(),
      unitPrice: _parsedPrice,
      lineTotal: _lineTotal,
      discountAmount: _totalDiscount,
      finalPrice: _finalPrice,
      assignments: assignments,
      position: widget.item?.position ?? 0,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final isEditing = widget.item != null;

    final costPerSelected = _selectedMemberIds.isNotEmpty ? (_finalPrice ~/ _selectedMemberIds.length) : 0;

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
            // Drag Handle
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Chỉnh sửa món ăn' : 'Thêm món mới',
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

            // Tên món
            Text(
              'Tên món ăn / Dịch vụ *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: !isEditing,
              maxLength: 80,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (val) {
                if (_nameError != null && val.trim().isNotEmpty) {
                  setState(() => _nameError = null);
                }
              },
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Lẩu bò nhúng dấm...',
                errorText: _nameError,
                errorStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Số lượng & Đơn giá
            Row(
              children: [
                // Số lượng
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số lượng *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
                        decoration: InputDecoration(
                          hintText: '1',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Đơn giá (VND)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn giá (VND) *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
                        decoration: InputDecoration(
                          hintText: '100.000',
                          suffixText: 'đ',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Giảm giá trên 1 phần món
            Text(
              'Giảm giá trên 1 phần / món (VND)',
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
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
              decoration: InputDecoration(
                hintText: '0 (Số tiền giảm cho 1 phần)',
                suffixText: 'đ/phần',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Giá thực tế Preview Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFDCFCE7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giá thực tế sau giảm:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                  Row(
                    children: [
                      if (_totalDiscount > 0) ...[
                        Text(
                          CurrencyFormatter.formatVND(_lineTotal.toDouble()),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        CurrencyFormatter.formatVND(_finalPrice.toDouble()),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!widget.isEvenSplit) ...[
              const SizedBox(height: 18),

              // Section: Gán người ăn
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thành viên tham gia gánh món (${_selectedMemberIds.length}/${widget.members.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAllMembers,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      _selectedMemberIds.length == widget.members.length ? 'Bỏ chọn' : 'Chọn tất cả',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Members Checkbox List
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.members.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = widget.members[index];
                    final isSelected = _selectedMemberIds.contains(member.memberId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedMemberIds.add(member.memberId);
                          } else {
                            _selectedMemberIds.remove(member.memberId);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      title: Text(
                        member.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: textMain,
                        ),
                      ),
                      subtitle: isSelected && _selectedMemberIds.isNotEmpty
                          ? Text(
                              'Tạm tính: ${CurrencyFormatter.formatVND(costPerSelected.toDouble())}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F766E),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Action Buttons
            AppButton(
              label: isEditing ? 'Lưu thay đổi' : 'Thêm vào hoá đơn',
              onPressed: _handleSave,
            ),

            // Full-Width Delete Button (If editing)
            if (isEditing && widget.onDelete != null) ...[
              const SizedBox(height: 10),
              AppButton(
                label: 'Xoá món này khỏi hoá đơn',
                variant: AppButtonVariant.danger,
                icon: const Icon(HugeIcons.strokeRoundedDelete02, size: 18, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDelete!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
