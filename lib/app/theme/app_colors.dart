import 'package:flutter/material.dart';

/// Complete Design Tokens mapping from PaySplit UI (Tally x Hallmark style system).
abstract class AppColors {
  // --- Light Mode (Pure White & Deep Teal) ---
  static const Color paper = Color(0xFFFFFFFF);
  static const Color paperOuter = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF9FAFB);
  static const Color surfaceMuted = Color(0xFFF3F4F6);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF3F4F6);
  static const Color borderStrong = Color(0xFFD1D5DB);
  static const Color borderFocus = Color(0xFF0F766E);

  static const Color textMain = Color(0xFF1C2118);
  static const Color textMuted = Color(0xFF676E5F);
  static const Color textSubtle = Color(0xFF98A08E);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF0F766E);
  static const Color primaryHover = Color(0xFF115E59);
  static const Color primaryActive = Color(0xFF134E4A);
  static const Color primarySubtle = Color(0xFFF0FDFA);
  static const Color primaryBorder = Color(0xFF99F6E4);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successSubtle = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);
  static const Color successText = Color(0xFF065F46);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSubtle = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningText = Color(0xFF92400E);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color dangerText = Color(0xFF991B1B);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoSubtle = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color infoText = Color(0xFF1E40AF);

  // Financial Balance Semantic
  static const Color balancePositiveBg = Color(0xFFECFDF5);
  static const Color balancePositive = Color(0xFF059669);
  static const Color balanceNegativeBg = Color(0xFFFEF2F2);
  static const Color balanceNegative = Color(0xFFDC2626);

  // Legacy mappings for backwards compatibility
  static const Color secondary = Color(0xFFF59E0B);
  static const Color error = danger;
  static const Color background = paper;
  static const Color textPrimary = textMain;
  static const Color textSecondary = textMuted;

  // --- Dark Mode (Obsidian & Deep Olive) ---
  static const Color darkPaper = Color(0xFF121512);
  static const Color darkPaperOuter = Color(0xFF0C0E0C);
  static const Color darkSurface = Color(0xFF1B2019);
  static const Color darkSurfaceSubtle = Color(0xFF222820);
  static const Color darkSurfaceMuted = Color(0xFF2B3328);

  static const Color darkBorder = Color(0xFF2D3528);
  static const Color darkBorderSubtle = Color(0xFF232A20);
  static const Color darkBorderStrong = Color(0xFF3E4A38);
  static const Color darkBorderFocus = Color(0xFF14B8A6);

  static const Color darkTextMain = Color(0xFFE8EDE4);
  static const Color darkTextMuted = Color(0xFFA2ABA0);
  static const Color darkTextSubtle = Color(0xFF6B7469);

  static const Color darkPrimary = Color(0xFF14B8A6);
  static const Color darkPrimarySubtle = Color(0xFF042F2E);

  static const Color darkBackground = darkPaper;
}
