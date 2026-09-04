import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_detail_entity.dart';
import 'amount_unit_switch.dart';

typedef BillAdjustmentUpdate =
    void Function({int? serviceCharge, int? vat, int? generalDiscount});

class BillAdjustmentsSection extends StatelessWidget {
  final BillDetailEntity bill;
  final int computedGrossSubtotal;
  final int computedTotalItemDiscount;
  final int computedNetItemsTotal;
  final int computedTotal;
  final bool isEditable;
  final BillAdjustmentUpdate onUpdateAdjustments;

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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAdjustmentsModal(
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
    final colors = _AdjustmentColors.of(context);
    final useCompactEditAction = MediaQuery.sizeOf(context).width < 360;

    return Semantics(
      label: 'Thuế, Phí và Khuyến mãi',
      button: isEditable,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('bill-adjustments-card'),
          onTap: isEditable ? () => _openAdjustmentsDialog(context) : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Icon(
                        HugeIcons.strokeRoundedReceiptDollar,
                        size: 18,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thuế, Phí & Khuyến mãi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textMain,
                          ),
                        ),
                      ),
                      if (isEditable && useCompactEditAction)
                        IconButton(
                          key: const Key('edit-adjustments-button'),
                          onPressed: () => _openAdjustmentsDialog(context),
                          color: colors.accent,
                          tooltip: 'Chỉnh sửa',
                          icon: const Icon(
                            HugeIcons.strokeRoundedEdit02,
                            size: 17,
                          ),
                        )
                      else if (isEditable)
                        TextButton.icon(
                          key: const Key('edit-adjustments-button'),
                          onPressed: () => _openAdjustmentsDialog(context),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.accent,
                            minimumSize: const Size(44, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const Icon(
                            HugeIcons.strokeRoundedEdit02,
                            size: 15,
                          ),
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
                Divider(height: 1, color: colors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _MoneyRow(
                        label: 'Tổng tiền món gốc',
                        semanticLabel: 'Tổng tiền món gốc, Subtotal',
                        value: _formatAmount(computedGrossSubtotal),
                        labelColor: colors.textMain,
                        valueColor: colors.textMain,
                      ),
                      _MoneyRow(
                        label: 'Khuyến mãi món',
                        semanticLabel: 'Tổng khuyến mãi từng món',
                        value: _formatSignedAmount(
                          computedTotalItemDiscount,
                          negative: true,
                        ),
                        labelColor: colors.textMuted,
                        valueColor: AppColors.balancePositive,
                      ),
                      _MoneyRow(
                        label: 'Tiền món thực tế',
                        semanticLabel: 'Tiền món thực tế, Net Items Total',
                        value: _formatAmount(computedNetItemsTotal),
                        labelColor: colors.accent,
                        valueColor: colors.accent,
                        emphasized: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Divider(height: 1, color: colors.border),
                      ),
                      _MoneyRow(
                        label: 'Phí dịch vụ',
                        value: _formatSignedAmount(bill.serviceCharge),
                        labelColor: colors.textMain,
                        valueColor: colors.textMain,
                      ),
                      _MoneyRow(
                        label: 'Thuế VAT',
                        value: _formatSignedAmount(bill.vat),
                        labelColor: colors.textMain,
                        valueColor: colors.textMain,
                      ),
                      _MoneyRow(
                        label: 'Voucher chung',
                        semanticLabel: 'Voucher giảm giá chung',
                        value: _formatSignedAmount(
                          bill.generalDiscount,
                          negative: true,
                        ),
                        labelColor: colors.textMain,
                        valueColor: AppColors.balancePositive,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Divider(
                          height: 1.5,
                          thickness: 1.5,
                          color: colors.textMain,
                        ),
                      ),
                      _MoneyRow(
                        label: 'Tổng thanh toán',
                        semanticLabel: 'Tổng cộng thanh toán',
                        value: _formatAmount(computedTotal),
                        labelColor: colors.textMain,
                        valueColor: colors.accent,
                        total: true,
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '* Voucher chung được chia theo tỷ lệ tiền món thực tế của từng người',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            height: 1.35,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String? semanticLabel;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool emphasized;
  final bool total;

  const _MoneyRow({
    required this.label,
    this.semanticLabel,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.emphasized = false,
    this.total = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = total || emphasized ? FontWeight.w700 : FontWeight.w500;
    return Semantics(
      label: '${semanticLabel ?? label}, $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: total ? 13.5 : 13,
                  height: 1.35,
                  fontWeight: weight,
                  color: labelColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                key: total ? const Key('computed-total-value') : null,
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: total ? 15 : 13,
                  height: 1.35,
                  fontWeight: total || emphasized
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAdjustmentsModal extends StatefulWidget {
  final BillDetailEntity bill;
  final int computedGrossSubtotal;
  final int computedTotalItemDiscount;
  final int computedNetItemsTotal;
  final BillAdjustmentUpdate onSave;

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
  late final TextEditingController _serviceController;
  late final TextEditingController _vatController;
  late final TextEditingController _discountController;
  late int _serviceCharge;
  late int _vat;
  late int _generalDiscount;
  AmountInputUnit _serviceMode = AmountInputUnit.vnd;
  AmountInputUnit _vatMode = AmountInputUnit.vnd;
  AmountInputUnit _discountMode = AmountInputUnit.vnd;

  int get _previewTotal => math.max(
    0,
    widget.computedNetItemsTotal + _serviceCharge + _vat - _generalDiscount,
  );

  @override
  void initState() {
    super.initState();
    _serviceCharge = widget.bill.serviceCharge;
    _vat = widget.bill.vat;
    _generalDiscount = widget.bill.generalDiscount;
    _serviceController = _controllerFor(widget.bill.serviceCharge);
    _vatController = _controllerFor(widget.bill.vat);
    _discountController = _controllerFor(widget.bill.generalDiscount);
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _vatController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _updateInput(_AdjustmentField field, String text, AmountInputUnit mode) {
    final amount = mode == AmountInputUnit.vnd
        ? CurrencyFormatter.parseInput(text)
        : CurrencyFormatter.percentToVnd(text, widget.computedNetItemsTotal);
    setState(() => _setAmount(field, amount));
  }

  void _changeMode(_AdjustmentField field, AmountInputUnit mode) {
    if (_modeFor(field) == mode) return;
    setState(() {
      _setMode(field, mode);
      final amount = _amountFor(field);
      final controller = _controllerForField(field);
      controller.text = mode == AmountInputUnit.vnd
          ? (amount > 0 ? CurrencyFormatter.formatInput(amount) : '')
          : CurrencyFormatter.vndToPercent(
              amount,
              widget.computedNetItemsTotal,
            );
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  void _applyAmount(_AdjustmentField field, int amount) {
    final safeAmount = math.max(0, amount);
    setState(() {
      _setMode(field, AmountInputUnit.vnd);
      _setAmount(field, safeAmount);
      final controller = _controllerForField(field);
      controller.text = safeAmount > 0
          ? CurrencyFormatter.formatInput(safeAmount)
          : '';
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  void _applyPercent(_AdjustmentField field, double percent) {
    final amount = (widget.computedNetItemsTotal * percent).round();
    setState(() {
      _setMode(field, AmountInputUnit.percent);
      _setAmount(field, amount);
      final controller = _controllerForField(field);
      controller.text = CurrencyFormatter.vndToPercent(
        amount,
        widget.computedNetItemsTotal,
      );
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  TextEditingController _controllerForField(_AdjustmentField field) =>
      switch (field) {
        _AdjustmentField.service => _serviceController,
        _AdjustmentField.vat => _vatController,
        _AdjustmentField.discount => _discountController,
      };

  int _amountFor(_AdjustmentField field) => switch (field) {
    _AdjustmentField.service => _serviceCharge,
    _AdjustmentField.vat => _vat,
    _AdjustmentField.discount => _generalDiscount,
  };

  AmountInputUnit _modeFor(_AdjustmentField field) => switch (field) {
    _AdjustmentField.service => _serviceMode,
    _AdjustmentField.vat => _vatMode,
    _AdjustmentField.discount => _discountMode,
  };

  void _setAmount(_AdjustmentField field, int amount) {
    switch (field) {
      case _AdjustmentField.service:
        _serviceCharge = amount;
      case _AdjustmentField.vat:
        _vat = amount;
      case _AdjustmentField.discount:
        _generalDiscount = amount;
    }
  }

  void _setMode(_AdjustmentField field, AmountInputUnit mode) {
    switch (field) {
      case _AdjustmentField.service:
        _serviceMode = mode;
      case _AdjustmentField.vat:
        _vatMode = mode;
      case _AdjustmentField.discount:
        _discountMode = mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _AdjustmentColors.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;

    return Semantics(
      label: 'Phụ phí, Thuế và Khuyến mãi',
      child: Container(
        key: const Key('edit-adjustments-modal'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.border),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          bottomInset + 20,
        ),
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
                    color: colors.strongBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Phụ phí, Thuế & Khuyến mãi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('close-adjustments-modal'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(HugeIcons.strokeRoundedCancel01),
                    color: colors.textMuted,
                    tooltip: 'Đóng',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      side: BorderSide(color: colors.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AdjustmentInput(
                key: const Key('service-charge-field'),
                label: 'Phí dịch vụ',
                semanticLabel: 'Phí dịch vụ, VND',
                controller: _serviceController,
                mode: _serviceMode,
                onModeChanged: (mode) =>
                    _changeMode(_AdjustmentField.service, mode),
                onChanged: (value) =>
                    _updateInput(_AdjustmentField.service, value, _serviceMode),
                actions: [
                  _QuickAction(
                    '0đ',
                    () => _applyAmount(_AdjustmentField.service, 0),
                  ),
                  _QuickAction(
                    '5%',
                    () => _applyPercent(_AdjustmentField.service, 0.05),
                  ),
                  _QuickAction(
                    '10%',
                    () => _applyPercent(_AdjustmentField.service, 0.10),
                  ),
                ],
                colors: colors,
              ),
              const SizedBox(height: 16),
              _AdjustmentInput(
                key: const Key('vat-field'),
                label: 'Thuế VAT',
                semanticLabel: 'Thuế VAT, VND',
                controller: _vatController,
                mode: _vatMode,
                onModeChanged: (mode) =>
                    _changeMode(_AdjustmentField.vat, mode),
                onChanged: (value) =>
                    _updateInput(_AdjustmentField.vat, value, _vatMode),
                actions: [
                  _QuickAction(
                    '0%',
                    () => _applyPercent(_AdjustmentField.vat, 0),
                  ),
                  _QuickAction(
                    '8%',
                    () => _applyPercent(_AdjustmentField.vat, 0.08),
                  ),
                  _QuickAction(
                    '10%',
                    () => _applyPercent(_AdjustmentField.vat, 0.10),
                  ),
                ],
                colors: colors,
              ),
              const SizedBox(height: 16),
              _ReadOnlyDiscount(
                value: widget.computedTotalItemDiscount,
                colors: colors,
              ),
              const SizedBox(height: 16),
              _AdjustmentInput(
                key: const Key('general-discount-field'),
                label: 'Voucher chung',
                semanticLabel: 'Voucher giảm giá chung, VND',
                controller: _discountController,
                mode: _discountMode,
                onModeChanged: (mode) =>
                    _changeMode(_AdjustmentField.discount, mode),
                onChanged: (value) => _updateInput(
                  _AdjustmentField.discount,
                  value,
                  _discountMode,
                ),
                actions: [
                  _QuickAction(
                    '0đ',
                    () => _applyAmount(_AdjustmentField.discount, 0),
                  ),
                  _QuickAction(
                    '50k',
                    () => _applyAmount(_AdjustmentField.discount, 50000),
                  ),
                  _QuickAction(
                    '10%',
                    () => _applyPercent(_AdjustmentField.discount, 0.10),
                  ),
                ],
                colors: colors,
                successLabel: true,
              ),
              const SizedBox(height: 18),
              _LivePreview(
                grossSubtotal: widget.computedGrossSubtotal,
                itemDiscount: widget.computedTotalItemDiscount,
                netItemsTotal: widget.computedNetItemsTotal,
                serviceCharge: _serviceCharge,
                vat: _vat,
                generalDiscount: _generalDiscount,
                total: _previewTotal,
                colors: colors,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('cancel-adjustments'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('save-adjustments'),
                      onPressed: () {
                        widget.onSave(
                          serviceCharge: _serviceCharge,
                          vat: _vat,
                          generalDiscount: _generalDiscount,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Lưu áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final VoidCallback onPressed;

  const _QuickAction(this.label, this.onPressed);
}

enum _AdjustmentField { service, vat, discount }

class _AdjustmentInput extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final TextEditingController controller;
  final AmountInputUnit mode;
  final ValueChanged<AmountInputUnit> onModeChanged;
  final ValueChanged<String> onChanged;
  final List<_QuickAction> actions;
  final _AdjustmentColors colors;
  final bool successLabel;

  const _AdjustmentInput({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.controller,
    required this.mode,
    required this.onModeChanged,
    required this.onChanged,
    required this.actions,
    required this.colors,
    this.successLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final useStackedHeader = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: successLabel ? AppColors.balancePositive : colors.textMain,
      ),
    );
    final actionsWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          OutlinedButton(
            onPressed: actions[index].onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textMain,
              backgroundColor: colors.mutedSurface,
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              side: BorderSide(color: colors.border),
              textStyle: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actions[index].label),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (useStackedHeader) ...[
          labelWidget,
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: actionsWidget),
        ] else
          Row(
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: 8),
              actionsWidget,
            ],
          ),
        const SizedBox(height: 6),
        Semantics(
          label: semanticLabel,
          textField: true,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: mode == AmountInputUnit.percent,
            ),
            inputFormatters: mode == AmountInputUnit.vnd
                ? const [VndTextInputFormatter()]
                : const [PercentTextInputFormatter()],
            onChanged: onChanged,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              color: colors.textMain,
            ),
            decoration: InputDecoration(
              hintText: '0',
              suffixIcon: AmountUnitSwitch(
                value: mode,
                onChanged: onModeChanged,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 112,
                minHeight: 48,
              ),
              fillColor: colors.inputSurface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.accent, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyDiscount extends StatelessWidget {
  final int value;
  final _AdjustmentColors colors;

  const _ReadOnlyDiscount({required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatAmount(value);
    return Semantics(
      label:
          'Tổng khuyến mãi từng món, tự động gộp từ các món, $formattedValue',
      readOnly: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khuyến mãi món',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Tự động từ các món',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: const Key('item-discount-read-only'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: colors.readOnlySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              formattedValue,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final int grossSubtotal;
  final int itemDiscount;
  final int netItemsTotal;
  final int serviceCharge;
  final int vat;
  final int generalDiscount;
  final int total;
  final _AdjustmentColors colors;

  const _LivePreview({
    required this.grossSubtotal,
    required this.itemDiscount,
    required this.netItemsTotal,
    required this.serviceCharge,
    required this.vat,
    required this.generalDiscount,
    required this.total,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tổng cộng tự tính ${_formatAmount(total)}',
      liveRegion: true,
      child: Container(
        key: const Key('adjustments-live-preview'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.previewSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            _PreviewRow(
              label: 'Tổng tiền món gốc',
              value: _formatAmount(grossSubtotal),
              color: colors.textMain,
            ),
            _PreviewRow(
              label: 'Khuyến mãi món',
              value: _formatSignedAmount(itemDiscount, negative: true),
              color: AppColors.balanceNegative,
            ),
            _PreviewRow(
              label: 'Tiền món thực tế',
              value: _formatAmount(netItemsTotal),
              color: colors.accent,
              emphasized: true,
            ),
            const SizedBox(height: 4),
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 4),
            _PreviewRow(
              label: 'Phí dịch vụ',
              value: _formatSignedAmount(serviceCharge),
              color: colors.textMuted,
            ),
            _PreviewRow(
              label: 'Thuế VAT',
              value: _formatSignedAmount(vat),
              color: colors.textMuted,
            ),
            _PreviewRow(
              label: 'Voucher chung',
              value: _formatSignedAmount(generalDiscount, negative: true),
              color: AppColors.balancePositive,
            ),
            const SizedBox(height: 4),
            Divider(height: 1.5, color: colors.border),
            const SizedBox(height: 4),
            _PreviewRow(
              key: const Key('preview-total-row'),
              label: 'Tổng thanh toán',
              value: _formatAmount(total),
              color: colors.accent,
              total: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool emphasized;
  final bool total;

  const _PreviewRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
    this.total = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: total ? 14 : 12.5,
                fontWeight: total || emphasized
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                fontSize: total ? 14.5 : 12.5,
                fontWeight: total || emphasized
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentColors {
  final Color surface;
  final Color inputSurface;
  final Color mutedSurface;
  final Color readOnlySurface;
  final Color previewSurface;
  final Color border;
  final Color strongBorder;
  final Color textMain;
  final Color textMuted;
  final Color accent;

  const _AdjustmentColors({
    required this.surface,
    required this.inputSurface,
    required this.mutedSurface,
    required this.readOnlySurface,
    required this.previewSurface,
    required this.border,
    required this.strongBorder,
    required this.textMain,
    required this.textMuted,
    required this.accent,
  });

  factory _AdjustmentColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _AdjustmentColors(
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      inputSurface: isDark
          ? AppColors.darkSurfaceSubtle
          : AppColors.surfaceSubtle,
      mutedSurface: isDark
          ? AppColors.darkSurfaceMuted
          : AppColors.surfaceMuted,
      readOnlySurface: isDark
          ? AppColors.darkSurfaceMuted
          : AppColors.surfaceMuted,
      previewSurface: isDark
          ? AppColors.darkSurfaceSubtle
          : AppColors.surfaceMuted,
      border: isDark ? AppColors.darkBorder : AppColors.border,
      strongBorder: isDark
          ? AppColors.darkBorderStrong
          : AppColors.borderStrong,
      textMain: isDark ? AppColors.darkTextMain : AppColors.textMain,
      textMuted: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
      accent: isDark ? AppColors.darkPrimary : AppColors.primary,
    );
  }
}

TextEditingController _controllerFor(int value) {
  return TextEditingController(text: value > 0 ? value.toString() : '');
}

String _formatAmount(int amount) {
  return CurrencyFormatter.formatVND(math.max(0, amount).toDouble());
}

String _formatSignedAmount(int amount, {bool negative = false}) {
  if (amount <= 0) return '0 đ';
  return '${negative ? '-' : '+'} ${_formatAmount(amount)}';
}
