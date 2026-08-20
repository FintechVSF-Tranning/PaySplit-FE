import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.focusNode,
    this.textInputAction,
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
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
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

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
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
        AnimatedContainer(
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
                    child: Focus(
                      onFocusChange: (focused) => setState(() => _isFocused = focused),
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        readOnly: widget.readOnly,
                        maxLength: widget.maxLength,
                        inputFormatters: widget.inputFormatters,
                        obscureText: _obscureText,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isPassword)
                    GestureDetector(
                      onTap: () => setState(() => _obscureText = !_obscureText),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
