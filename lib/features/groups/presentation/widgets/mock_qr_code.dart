import 'dart:math';

import 'package:flutter/material.dart';

/// Mã QR **mocup** cho giai đoạn dựng UI.
///
/// Ma trận module được sinh xác định (deterministic) từ [data] nên cùng một
/// mã mời luôn vẽ ra cùng một hình — đủ để review bố cục, chụp ảnh demo và
/// duyệt thiết kế. Đây KHÔNG phải QR quét được: khi nối API thật, thay widget
/// này bằng `QrImageView` của package `qr_flutter`, giữ nguyên chữ ký
/// `data` / `size` / `foreground`.
class MockQrCode extends StatelessWidget {
  const MockQrCode({
    super.key,
    required this.data,
    this.size = 220,
    this.foreground = const Color(0xFF0F172A),
    this.centerEmoji,
  });

  final String data;
  final double size;
  final Color foreground;

  /// Biểu tượng nhóm chèn giữa mã, giống logo overlay của VietQR.
  final String? centerEmoji;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _MockQrPainter(data: data, foreground: foreground),
          ),
          if (centerEmoji != null)
            Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.06),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(centerEmoji!, style: TextStyle(fontSize: size * 0.12)),
            ),
        ],
      ),
    );
  }
}

class _MockQrPainter extends CustomPainter {
  _MockQrPainter({required this.data, required this.foreground});

  final String data;
  final Color foreground;

  static const int _modules = 29;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final paint = Paint()..color = foreground;

    // Seed từ nội dung => cùng data cho ra cùng hoa văn.
    final seed = data.codeUnits.fold<int>(7, (acc, c) => (acc * 31 + c) & 0x7fffffff);
    final random = Random(seed);

    for (var row = 0; row < _modules; row++) {
      for (var col = 0; col < _modules; col++) {
        if (_isFinderZone(row, col)) continue;
        if (_isCenterReserved(row, col)) continue;
        if (random.nextDouble() < 0.46) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(col * cell, row * cell, cell, cell),
              Radius.circular(cell * 0.28),
            ),
            paint,
          );
        }
      }
    }

    // 3 ô định vị góc (finder patterns).
    _drawFinder(canvas, cell, 0, 0, paint);
    _drawFinder(canvas, cell, 0, _modules - 7, paint);
    _drawFinder(canvas, cell, _modules - 7, 0, paint);
  }

  /// Vùng 8x8 quanh mỗi finder pattern được chừa trống.
  bool _isFinderZone(int row, int col) {
    const s = _modules - 8;
    final top = row < 8;
    final bottom = row >= s;
    final left = col < 8;
    final right = col >= s;
    return (top && left) || (top && right) || (bottom && left);
  }

  /// Ô trống giữa mã dành cho logo/emoji.
  bool _isCenterReserved(int row, int col) {
    const mid = _modules ~/ 2;
    return (row - mid).abs() <= 4 && (col - mid).abs() <= 4;
  }

  void _drawFinder(Canvas canvas, double cell, int row, int col, Paint paint) {
    final outer = Rect.fromLTWH(col * cell, row * cell, cell * 7, cell * 7);
    canvas.drawRRect(RRect.fromRectAndRadius(outer, Radius.circular(cell * 1.9)), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(cell), Radius.circular(cell * 1.3)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(cell * 2), Radius.circular(cell * 0.9)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MockQrPainter old) =>
      old.data != data || old.foreground != foreground;
}
