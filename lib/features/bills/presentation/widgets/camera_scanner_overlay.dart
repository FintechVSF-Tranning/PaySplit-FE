import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraScannerOverlay extends StatefulWidget {
  const CameraScannerOverlay({
    super.key,
    this.isFlashOn = false,
    this.onToggleFlash,
  });

  final bool isFlashOn;
  final VoidCallback? onToggleFlash;

  @override
  State<CameraScannerOverlay> createState() => _CameraScannerOverlayState();
}

class _CameraScannerOverlayState extends State<CameraScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.04, end: 0.96).animate(
      CurvedAnimation(
        parent: _laserController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Khung căn chỉnh bao trọn toàn bộ camera view với lề 10px ôm sát góc
        const margin = 10.0;
        final boxWidth = constraints.maxWidth - (margin * 2);
        final boxHeight = constraints.maxHeight - (margin * 2);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Viewfinder Box spanning full camera
            Positioned(
              top: margin,
              left: margin,
              right: margin,
              bottom: margin,
              child: Stack(
                children: [
                  // Four Corner Brackets embracing the camera edges
                  CustomPaint(
                    size: Size(boxWidth, boxHeight),
                    painter: _CornerBracketsPainter(
                      color: const Color(0xFF14B8A6), // Bright Teal
                      cornerLength: 36,
                      strokeWidth: 3.5,
                      borderRadius: 16,
                    ),
                  ),

                  // Animated Scanning Laser Bar spanning full camera width
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: boxHeight * _laserAnimation.value,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withValues(alpha: 0.0),
                                const Color(0xFF14B8A6),
                                const Color(0xFF10B981).withValues(alpha: 0.0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14B8A6).withValues(alpha: 0.75),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Top Guidance Tip pill
            Positioned(
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.document_scanner_outlined,
                      size: 14,
                      color: Color(0xFF14B8A6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Căn chỉnh hoá đơn vào trong khung',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double borderRadius;

  _CornerBracketsPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, borderRadius)
      ..quadraticBezierTo(0, 0, borderRadius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(w - cornerLength, 0)
      ..lineTo(w - borderRadius, 0)
      ..quadraticBezierTo(w, 0, w, borderRadius)
      ..lineTo(w, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, h - cornerLength)
      ..lineTo(0, h - borderRadius)
      ..quadraticBezierTo(0, h, borderRadius, h)
      ..lineTo(cornerLength, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(w - cornerLength, h)
      ..lineTo(w - borderRadius, h)
      ..quadraticBezierTo(w, h, w, h - borderRadius)
      ..lineTo(w, h - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) => false;
}
