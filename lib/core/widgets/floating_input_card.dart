import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../app/theme/app_colors.dart';

/// Floating Input Card matching the exact Dribbble design mockup.
class FloatingInputCard extends StatefulWidget {
  const FloatingInputCard({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.autofillHints,
    this.readOnly = false,
    this.maxLength,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  /// Chạy khi người dùng bấm phím hành động của bàn phím (Next / Done / Go).
  /// Không có nó thì Enter trên web và nút Done trên mobile đều là ngõ cụt.
  final void Function(String)? onSubmitted;

  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<FloatingInputCard> createState() => _FloatingInputCardState();
}

class _FloatingInputCardState extends State<FloatingInputCard> {
  late bool _obscureText;
  bool _isFocused = false;
  String? _errorText;

  /// Chỉ dựng khi caller không truyền [FloatingInputCard.focusNode]; node của
  /// caller thì caller tự dispose.
  FocusNode? _internalNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant FloatingInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalNode)?.removeListener(
        _handleFocusChange,
      );
      _focusNode.addListener(_handleFocusChange);
      _handleFocusChange();
    }
  }

  @override
  void dispose() {
    (widget.focusNode ?? _internalNode)?.removeListener(_handleFocusChange);
    _internalNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted || _isFocused == _focusNode.hasFocus) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  /// Bấm bất kỳ đâu trên thẻ đều đưa con trỏ vào ô nhập.
  ///
  /// Thẻ cao ~64px nhưng vùng chữ thật của [TextFormField] chỉ chiếm dải giữa
  /// bên phải icon, nên nếu không có bước này thì nhãn, icon, viền và toàn bộ
  /// phần đệm đều là vùng chết: nhìn thì to, bấm thì trượt.
  void _requestFocus() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : const Color(0xFF0F766E);
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final textMain = isDark ? AppColors.darkTextMain : const Color(0xFF1E293B);
    final textMuted = isDark ? AppColors.darkTextMuted : const Color(0xFF64748B);

    final borderColor = _errorText != null
        ? AppColors.danger
        : _isFocused
        ? primary
        : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          // opaque: nhận cả những cú bấm rơi vào phần đệm trong suốt của thẻ.
          behavior: HitTestBehavior.opaque,
          onTap: _requestFocus,
          child: MouseRegion(
            cursor: SystemMouseCursors.text,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small Label on top
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Input Row with Icon + TextField + Suffix
                  Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 20,
                        color: _isFocused ? primary : textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        // Không bọc trong `Focus`: node phụ đó cũng nhận được
                        // focus, nên Tab trên web dừng lại ở nó thay vì ở ô
                        // nhập, và trên mobile bàn phím không bật vì thứ đang
                        // giữ focus không phải EditableText.
                        child: TextFormField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          readOnly: widget.readOnly,
                          maxLength: widget.maxLength,
                          inputFormatters: widget.inputFormatters,
                          obscureText: _obscureText,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          autofillHints: widget.autofillHints,
                          onFieldSubmitted: widget.onSubmitted,
                          onChanged: (val) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            }
                            widget.onChanged?.call(val);
                          },
                          validator: (val) {
                            final err = widget.validator?.call(val);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _errorText != err) {
                                setState(() => _errorText = err);
                              }
                            });
                            return err != null ? '' : null;
                          },
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textMain,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            counterText: '',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: textMuted.withValues(alpha: 0.6),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            errorStyle: const TextStyle(height: 0, fontSize: 0),
                          ),
                        ),
                      ),
                      if (widget.isPassword)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _obscureText = !_obscureText),
                            child: Padding(
                              // Đệm rộng để nút con mắt đạt vùng bấm tối thiểu,
                              // thay vì chỉ đúng 19px của icon.
                              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                              child: Icon(
                                _obscureText
                                    ? HugeIcons.strokeRoundedViewOffSlash
                                    : HugeIcons.strokeRoundedView,
                                size: 19,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_errorText != null && _errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _errorText!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
