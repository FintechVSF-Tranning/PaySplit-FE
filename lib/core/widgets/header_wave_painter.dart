import 'package:flutter/material.dart';

/// Dải sóng Teal uốn lượn phía đầu màn hình — dùng chung cho Home,
/// Công nợ & Hóa đơn... để đồng bộ ngôn ngữ thiết kế giữa các tab.
///
/// Lớp này KHÔNG cố định (fixed) trên màn hình: widget cha đặt nó bên trong
/// nội dung cuộn để sóng cuộn theo cùng nội dung khi người dùng scroll.
class HeaderWavePainter extends CustomPainter {
  const HeaderWavePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF0F766E), const Color(0xFF132A24)]
            : [
                const Color(0xFF0F766E),
                const Color(0xFF115E59),
                const Color(0xFF134E4A),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final path = Path()
      ..lineTo(0, size.height - 35)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 15,
        size.width,
        size.height - 35,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeaderWavePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
