import 'package:flutter/material.dart';

/// DTO cấu hình cho từng nút hành động con (mini action) trong Speed Dial.
class SpeedDialAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });
}

/// Expandable Speed Dial FAB tuân thủ Design System PaySplit (Tally x Hallmark / Forui).
///
/// - Dạng Circular FAB tiêu chuẩn (tròn, chỉ chứa icon dấu "+").
/// - Tự động xoay icon 45 độ (0.125 turn) thành dấu "x" khi mở menu.
/// - Hiển thị backdrop mờ nhẹ che nền để tập trung vào menu.
/// - Bung danh sách các nút con (SpeedDialAction) với hiệu ứng Scale + Slide mượt mà.
class ExpandableBillFab extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final Color? primaryColor;
  final Color? foregroundColor;
  final String? tooltip;

  const ExpandableBillFab({
    super.key,
    required this.actions,
    this.primaryColor,
    this.foregroundColor,
    this.tooltip = 'Tạo hóa đơn',
  });

  @override
  State<ExpandableBillFab> createState() => _ExpandableBillFabState();
}

class _ExpandableBillFabState extends State<ExpandableBillFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuad,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.primaryColor ?? const Color(0xFF0F766E); // Deep Teal
    final foreground = widget.foregroundColor ?? Colors.white;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // 1. Lớp phủ mờ (Backdrop) khi mở menu
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

        // 2. Danh sách các nút mini Speed Dial bung lên từ dưới
        Positioned(
          right: 0,
          bottom: 64, // Cách nút FAB chính 64px
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.actions.length, (index) {
              final reversedIndex = widget.actions.length - 1 - index;
              final action = widget.actions[reversedIndex];
              return _buildSpeedDialItem(action, reversedIndex, theme);
            }),
          ),
        ),

        // 3. Nút Circular FAB chính (dấu "+" xoay thành "x")
        FloatingActionButton(
          heroTag: 'main_speed_dial_fab',
          onPressed: _toggle,
          tooltip: widget.tooltip,
          elevation: _isOpen ? 2 : 4,
          highlightElevation: 6,
          backgroundColor: primary,
          foregroundColor: foreground,
          shape: const CircleBorder(),
          child: RotationTransition(
            turns: _rotateAnimation,
            child: const Icon(
              Icons.add,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem(
    SpeedDialAction action,
    int index,
    ThemeData theme,
  ) {
    return ScaleTransition(
      scale: _expandAnimation,
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label Chip bên cạnh nút
              Material(
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    _close();
                    action.onTap();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDBE0CE)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      action.label,
                      style: const TextStyle(
                        fontFamily: 'Roboto Slab',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1C2118),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Mini FAB tròn 44x44
              SizedBox(
                width: 44,
                height: 44,
                child: FloatingActionButton.small(
                  heroTag: 'speed_dial_item_$index',
                  onPressed: () {
                    _close();
                    action.onTap();
                  },
                  elevation: 3,
                  backgroundColor: action.backgroundColor ?? Colors.white,
                  foregroundColor: action.foregroundColor ?? const Color(0xFF0F766E),
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xFFDBE0CE)),
                  ),
                  child: Icon(
                    action.icon,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
