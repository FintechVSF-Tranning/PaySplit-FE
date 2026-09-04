import 'package:flutter/material.dart';

/// Decorative organic fluid wave in the top-right corner of Auth screens (matching the design mockup).
class FluidTopWave extends StatelessWidget {
  const FluidTopWave({
    super.key,
    this.height = 180,
    this.width = 220,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      right: 0,
      child: CustomPaint(
        size: Size(width, height),
        painter: _FluidWavePainter(),
      ),
    );
  }
}

class _FluidWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Outermost soft Mint layer
    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF99F6E4), Color(0xFF5EEAD4)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path();
    path1.moveTo(size.width * 0.15, 0);
    path1.cubicTo(
      size.width * 0.4,
      size.height * 0.75,
      size.width * 0.85,
      size.height * 0.85,
      size.width,
      size.height * 0.5,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // 2. Middle Emerald layer
    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    path2.moveTo(size.width * 0.35, 0);
    path2.cubicTo(
      size.width * 0.55,
      size.height * 0.65,
      size.width * 0.9,
      size.height * 0.65,
      size.width,
      size.height * 0.35,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint2);

    // 3. Innermost Deep Teal layer
    final paint3 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F766E), Color(0xFF115E59)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path3 = Path();
    path3.moveTo(size.width * 0.55, 0);
    path3.cubicTo(
      size.width * 0.7,
      size.height * 0.45,
      size.width * 0.92,
      size.height * 0.45,
      size.width,
      size.height * 0.22,
    );
    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
