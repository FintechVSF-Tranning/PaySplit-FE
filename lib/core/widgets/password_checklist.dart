import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({
    super.key,
    required this.password,
    this.title = 'Độ mạnh mật khẩu:',
  });

  final String password;
  final String title;

  bool get hasLength => password.length >= 8 && password.length <= 72;
  bool get hasUpper => password.contains(RegExp(r'[A-Z]'));
  bool get hasLower => password.contains(RegExp(r'[a-z]'));
  bool get hasDigit => password.contains(RegExp(r'[0-9]'));

  bool get isAllValid => hasLength && hasUpper && hasLower && hasDigit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          _ChecklistItem(
            label: 'Từ 8 đến 72 ký tự',
            isValid: hasLength,
          ),
          const SizedBox(height: 4),
          _ChecklistItem(
            label: 'Chứa ít nhất 1 chữ in hoa (A-Z)',
            isValid: hasUpper,
          ),
          const SizedBox(height: 4),
          _ChecklistItem(
            label: 'Chứa ít nhất 1 chữ số (0-9)',
            isValid: hasDigit,
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.label, required this.isValid});

  final String label;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final validColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final invalidColor = isDark ? AppColors.darkTextSubtle : AppColors.textSubtle;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isValid ? validColor : Colors.transparent,
            border: Border.all(
              color: isValid ? validColor : invalidColor,
              width: 1.5,
            ),
          ),
          child: isValid
              ? const Icon(Icons.check, size: 9, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.w400,
              color: isValid
                  ? (isDark ? AppColors.darkTextMain : AppColors.textMain)
                  : invalidColor,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
