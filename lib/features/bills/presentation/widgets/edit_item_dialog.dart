import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/bill_detail_entity.dart';
import 'amount_unit_switch.dart';

class EditItemDialog extends StatefulWidget {
  final BillItemEntity? item; // null if adding new item
  final List<BillMemberEntity> members;
  final bool isEvenSplit;
  final bool isEditable;
  final bool isFinalized;
  final Function(BillItemEntity item)? onSave;
  final VoidCallback? onDelete;

  const EditItemDialog({
    super.key,
    this.item,
    required this.members,
    this.isEvenSplit = false,
    this.isEditable = true,
    this.isFinalized = false,
    this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    BillItemEntity? item,
    required List<BillMemberEntity> members,
    bool isEvenSplit = false,
    bool isEditable = true,
    bool isFinalized = false,
    Function(BillItemEntity item)? onSave,
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
        isEditable: isEditable,
        isFinalized: isFinalized,
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
  late int _unitDiscountVnd;
  AmountInputUnit _discountInputMode = AmountInputUnit.vnd;

  final Set<String> _selectedMemberIds = {};
  String? _nameError;

  static String _cleanQuantity(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '1';
    final d = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (d == null || d <= 0) return raw.trim();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toString();
  }

  static double _parseQuantityToDouble(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 1.0;
    final d = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (d == null || d <= 0) return 1.0;
    return d;
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _qtyController = TextEditingController(
      text: _cleanQuantity(item?.quantity),
    );

    int initialUnitPrice = 0;
    if (item != null) {
      if (item.unitPrice > 0) {
        initialUnitPrice = item.unitPrice;
      } else {
        final q = _parseQuantityToDouble(item.quantity);
        initialUnitPrice = q > 0
            ? (item.lineTotal / q).round()
            : item.lineTotal;
      }
    }

    int initialUnitDiscount = 0;
    if (item != null && item.discountAmount > 0) {
      final q = _parseQuantityToDouble(item.quantity);
      initialUnitDiscount = q > 0
          ? (item.discountAmount / q).round()
          : item.discountAmount;
    }

    final price = initialUnitPrice > 0
        ? initialUnitPrice
        : (item != null && item.lineTotal > 0 ? item.lineTotal : 0);
    _priceController = TextEditingController(
      text: price > 0 ? CurrencyFormatter.formatInput(price) : '',
    );
    _unitDiscountVnd = initialUnitDiscount;
    _discountController = TextEditingController(
      text: initialUnitDiscount > 0
          ? CurrencyFormatter.formatInput(initialUnitDiscount)
          : '',
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
    _qtyFocusNode.dispose();
    _priceFocusNode.dispose();
    _discountFocusNode.dispose();
    super.dispose();
  }

  int get _parsedPrice => CurrencyFormatter.parseInput(_priceController.text);
  double get _parsedQty => _parseQuantityToDouble(_qtyController.text);
  int get _parsedUnitDiscount => _unitDiscountVnd;

  int get _lineTotal => (_parsedPrice * _parsedQty).round();
  int get _totalDiscount => (_parsedUnitDiscount * _parsedQty).round();
  int get _finalPrice => (_lineTotal - _totalDiscount).clamp(0, _lineTotal);

  void _handlePriceChanged(String _) {
    if (_discountInputMode == AmountInputUnit.percent) {
      _unitDiscountVnd = CurrencyFormatter.percentToVnd(
        _discountController.text,
        _parsedPrice,
      );
    }
    setState(() {});
  }

  void _handleDiscountChanged(String value) {
    setState(() {
      _unitDiscountVnd = _discountInputMode == AmountInputUnit.vnd
          ? CurrencyFormatter.parseInput(value)
          : CurrencyFormatter.percentToVnd(value, _parsedPrice);
    });
  }

  void _setDiscountInputMode(AmountInputUnit mode) {
    if (mode == _discountInputMode) return;
    setState(() {
      _discountInputMode = mode;
      _discountController.text = mode == AmountInputUnit.vnd
          ? (_unitDiscountVnd > 0
                ? CurrencyFormatter.formatInput(_unitDiscountVnd)
                : '')
          : CurrencyFormatter.vndToPercent(_unitDiscountVnd, _parsedPrice);
      _discountController.selection = TextSelection.collapsed(
        offset: _discountController.text.length,
      );
    });
  }

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

  // Node của các ô phía sau, để phím Next đi đúng thứ tự tên → SL → giá → giảm.
  final _qtyFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _discountFocusNode = FocusNode();

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
              weight: widget.members.isNotEmpty
                  ? (1.0 / widget.members.length)
                  : 1.0,
            );
          }).toList()
        : _selectedMemberIds.map((mId) {
            final m = widget.members.firstWhere(
              (mem) => mem.memberId == mId,
              orElse: () => BillMemberEntity(
                memberId: mId,
                userId: '',
                displayName: 'Thành viên',
              ),
            );
            return BillItemAssignmentEntity(
              memberId: mId,
              userId: m.userId,
              displayName: m.displayName,
              avatarUrl: m.avatarUrl,
              weight: _selectedMemberIds.isNotEmpty
                  ? (1.0 / _selectedMemberIds.length)
                  : 1.0,
            );
          }).toList();

    final existingId = widget.item?.id;
    final effectiveId = (existingId != null && existingId.trim().isNotEmpty)
        ? existingId.trim()
        : 'item-${DateTime.now().microsecondsSinceEpoch}';

    final item = BillItemEntity(
      id: effectiveId,
      name: name,
      quantity: _cleanQuantity(_qtyController.text),
      unitPrice: _parsedPrice,
      lineTotal: _lineTotal,
      discountAmount: _totalDiscount,
      finalPrice: _finalPrice,
      assignments: assignments,
      position: widget.item?.position ?? 0,
    );

    widget.onSave?.call(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: widget.isEditable
            ? _buildEditableForm(context)
            : _buildReadOnlyPresentation(context),
      ),
    );
  }

  /// Giao diện Trình bày chỉ xem (Read-Only Presentation Mode) khi không có quyền chỉnh sửa
  Widget _buildReadOnlyPresentation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final item = widget.item;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final hasDiscount = item.discountAmount > 0;
    final effectiveUnitPrice = item.unitPrice > 0
        ? item.unitPrice
        : (_parseQuantityToDouble(item.quantity) > 0
              ? (item.lineTotal / _parseQuantityToDouble(item.quantity)).round()
              : item.lineTotal);

    // Xác định danh sách người tham gia
    final assignedIds = item.assignments.map((a) => a.memberId).toSet();
    final effectiveMembers = widget.isEvenSplit
        ? (assignedIds.isNotEmpty
              ? widget.members
                    .where((m) => assignedIds.contains(m.memberId))
                    .toList()
              : widget.members)
        : widget.members
              .where((m) => assignedIds.contains(m.memberId))
              .toList();
    final costPerPerson = effectiveMembers.isNotEmpty
        ? (item.finalPrice ~/ effectiveMembers.length)
        : item.finalPrice;

    return Column(
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

        // Nói thẳng vì sao không sửa được khi là thành viên xem bill nháp.
        // Đối với hoá đơn đã chốt, không hiển thị vì hoá đơn đã đóng băng hoàn toàn.
        if (!widget.isFinalized) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedInformationCircle,
                  size: 15,
                  color: textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chỉ trưởng nhóm hoặc người tạo hoá đơn mới sửa được giá và nội dung món.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    HugeIcons.strokeRoundedRestaurant01,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Chi tiết món ăn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 20),
              color: textMuted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tên món ăn & Số lượng card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Bảng tóm tắt giá
              _buildSummaryRow(
                'Đơn giá',
                CurrencyFormatter.formatVND(effectiveUnitPrice.toDouble()),
                textMuted,
                textMain,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Số lượng',
                '${item.quantity} phần',
                textMuted,
                textMain,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Thành tiền',
                CurrencyFormatter.formatVND(item.lineTotal.toDouble()),
                textMuted,
                hasDiscount ? textMuted : textMain,
                isLineThrough: hasDiscount,
              ),

              if (hasDiscount) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Giảm giá món',
                  '-${CurrencyFormatter.formatVND(item.discountAmount.toDouble())}',
                  const Color(0xFFEF4444),
                  const Color(0xFFEF4444),
                  isBold: true,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  'Giá thực tế sau giảm',
                  CurrencyFormatter.formatVND(item.finalPrice.toDouble()),
                  textMain,
                  const Color(0xFF0F766E),
                  isBold: true,
                  isLarge: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section: Người tham gia / Gánh món
        Text(
          'Thành viên gánh món (${effectiveMembers.length}/${widget.members.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
        const SizedBox(height: 8),

        if (effectiveMembers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Row(
              children: [
                const Icon(
                  HugeIcons.strokeRoundedAlertCircle,
                  size: 16,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Text(
                  'Chưa phân bổ cho thành viên nào',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: effectiveMembers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = effectiveMembers[index];
                final initials = member.displayName.isNotEmpty
                    ? member.displayName
                          .trim()
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join()
                    : 'TV';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          member.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: textMain,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatVND(costPerPerson.toDouble()),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 20),

        // Nút đóng
        AppButton(
          label: 'Đóng',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool isBold = false,
    bool isLarge = false,
    bool isLineThrough = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isLarge ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: labelColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: isLarge ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
            decoration: isLineThrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  /// Giao diện Chỉnh sửa (Editable Form Mode) khi có quyền
  Widget _buildEditableForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final isEditing = widget.item != null;

    final costPerSelected = _selectedMemberIds.isNotEmpty
        ? (_finalPrice ~/ _selectedMemberIds.length)
        : 0;

    return Column(
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
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _qtyFocusNode.requestFocus(),
          maxLength: 80,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
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
            fillColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAF9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
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
                    focusNode: _qtyFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _priceFocusNode.requestFocus(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textMain,
                    ),
                    decoration: InputDecoration(
                      hintText: '1',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAF9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
                    key: const Key('item-price-field'),
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _discountFocusNode.requestFocus(),
                    inputFormatters: const [VndTextInputFormatter()],
                    onChanged: _handlePriceChanged,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textMain,
                    ),
                    decoration: InputDecoration(
                      hintText: '100.000',
                      suffixText: 'đ',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAF9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
          'Giảm giá trên 1 phần / món',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textMain,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('item-discount-field'),
          controller: _discountController,
          focusNode: _discountFocusNode,
          keyboardType: TextInputType.numberWithOptions(
            decimal: _discountInputMode == AmountInputUnit.percent,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSave(),
          inputFormatters: _discountInputMode == AmountInputUnit.vnd
              ? const [VndTextInputFormatter()]
              : const [PercentTextInputFormatter()],
          onChanged: _handleDiscountChanged,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMain),
          decoration: InputDecoration(
            hintText: _discountInputMode == AmountInputUnit.vnd
                ? '0 (Số tiền giảm cho 1 phần)'
                : '0 (Phần trăm giảm)',
            suffixIcon: AmountUnitSwitch(
              key: const Key('item-discount-unit-toggle'),
              value: _discountInputMode,
              onChanged: _setDiscountInputMode,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 112,
              minHeight: 48,
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAF9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final label = Text(
                'Giá thực tế sau giảm:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                ),
              );
              final prices = Wrap(
                spacing: 8,
                runSpacing: 2,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_totalDiscount > 0)
                    Text(
                      CurrencyFormatter.formatVND(_lineTotal.toDouble()),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    CurrencyFormatter.formatVND(_finalPrice.toDouble()),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              );
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerRight, child: prices),
                  ],
                );
              }
              return Row(
                children: [
                  label,
                  const SizedBox(width: 8),
                  Expanded(child: prices),
                ],
              );
            },
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
                  _selectedMemberIds.length == widget.members.length
                      ? 'Bỏ chọn'
                      : 'Chọn tất cả',
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  title: Text(
                    member.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
            icon: const Icon(
              HugeIcons.strokeRoundedDelete02,
              size: 18,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete!();
            },
          ),
        ],
      ],
    );
  }
}
