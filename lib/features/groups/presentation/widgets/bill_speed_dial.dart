import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';

/// FAB tròn mở menu tạo hóa đơn (Quét OCR / Nhập tay) với hiệu ứng xoay `+`
/// và các sub-action trượt lên so le.
class BillSpeedDial extends StatefulWidget {
  const BillSpeedDial({super.key, required this.onScanOcr, required this.onManualEntry});

  final VoidCallback onScanOcr;
  final VoidCallback onManualEntry;

  @override
  State<BillSpeedDial> createState() => _BillSpeedDialState();
}

class _BillSpeedDialState extends State<BillSpeedDial> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  bool _isOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _run(VoidCallback action) {
    _toggle();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop bắt tap để đóng menu.
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SubAction(
                controller: _controller,
                order: 1,
                label: 'Quét hóa đơn AI OCR',
                icon: HugeIcons.strokeRoundedCamera01,
                onTap: () => _run(widget.onScanOcr),
              ),
              _SubAction(
                controller: _controller,
                order: 0,
                label: 'Nhập tay',
                icon: HugeIcons.strokeRoundedEdit02,
                onTap: () => _run(widget.onManualEntry),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.125).animate(_controller),
                    child: const Icon(HugeIcons.strokeRoundedAdd01, size: 26, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubAction extends StatelessWidget {
  const _SubAction({
    required this.controller,
    required this.order,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final AnimationController controller;

  /// Thứ tự trượt lên (0 = gần FAB nhất, xuất hiện trước).
  final int order;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final iconColor = isDark ? const Color(0xFF14B8A6) : AppColors.primary;

    final start = order * 0.15;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
    );

    return SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface,
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 19, color: iconColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
