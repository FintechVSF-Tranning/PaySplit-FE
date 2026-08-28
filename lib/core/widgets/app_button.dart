import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

enum AppButtonVariant { primary, outline, ghost, danger, gradient }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.trailingIcon,
    this.height = 48,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final Widget? trailingIcon;
  final double height;
  final double? borderRadius;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      unawaited(_animController.forward());
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void _handleTapUp(TapUpDetails _) {
    unawaited(_animController.reverse());
  }

  void _handleTapCancel() {
    unawaited(_animController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color? bg;
    Gradient? gradient;
    List<BoxShadow>? shadows;
    Color fg = Colors.white;
    BorderSide border = BorderSide.none;
    final radius = widget.borderRadius ?? (widget.variant == AppButtonVariant.gradient ? 26.0 : 12.0);

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = isDark ? AppColors.darkPrimary : AppColors.primary;
        fg = Colors.white;
        break;
      case AppButtonVariant.gradient:
        gradient = const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF10B981)],
        );
        fg = Colors.white;
        if (!isDisabled) {
          shadows = [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ];
        }
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextMain : AppColors.textMain;
        border = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        break;
    }

    if (isDisabled) {
      if (bg != null) bg = bg.withValues(alpha: 0.5);
      fg = fg.withValues(alpha: 0.6);
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            widget.trailingIcon!,
          ],
        ],
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          height: widget.height,
          width: widget.isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: bg,
            gradient: isDisabled ? null : gradient,
            borderRadius: BorderRadius.circular(radius),
            border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
