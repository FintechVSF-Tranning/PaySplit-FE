import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/* Hallmark · component: amount unit switch · genre: modern minimal
 * states: default · hover · focus · active · selected · disabled
 * contrast: uses PaySplit theme tokens
 */

enum AmountInputUnit { vnd, percent }

/// A compact Ant Design inspired segmented control for choosing how a money
/// value is entered. The value remains VND outside this presentation control.
class AmountUnitSwitch extends StatelessWidget {
  final AmountInputUnit value;
  final ValueChanged<AmountInputUnit>? onChanged;

  const AmountUnitSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final outerColor = isDark
        ? AppColors.darkSurfaceMuted
        : AppColors.surfaceMuted;
    final thumbColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final selectedColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return SizedBox(
      width: 100,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: outerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: AnimatedAlign(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment: value == AmountInputUnit.vnd
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: thumbColor,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _UnitOption(
                    label: 'VND',
                    semanticLabel: 'Nhập theo Việt Nam đồng',
                    selected: value == AmountInputUnit.vnd,
                    selectedColor: selectedColor,
                    mutedColor: mutedColor,
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(AmountInputUnit.vnd),
                  ),
                  _UnitOption(
                    label: '%',
                    semanticLabel: 'Nhập theo phần trăm',
                    selected: value == AmountInputUnit.percent,
                    selectedColor: selectedColor,
                    mutedColor: mutedColor,
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(AmountInputUnit.percent),
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

class _UnitOption extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final bool selected;
  final Color selectedColor;
  final Color mutedColor;
  final VoidCallback? onTap;

  const _UnitOption({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.selectedColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        label: semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            hoverColor: selectedColor.withValues(alpha: 0.06),
            focusColor: selectedColor.withValues(alpha: 0.10),
            highlightColor: selectedColor.withValues(alpha: 0.08),
            splashColor: selectedColor.withValues(alpha: 0.10),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? selectedColor : mutedColor,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
