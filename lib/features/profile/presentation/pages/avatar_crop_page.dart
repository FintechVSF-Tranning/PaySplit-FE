import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image/image.dart' as img;

/// Màn hình căn chỉnh và cắt ảnh đại diện theo khung tròn (Circular Avatar Crop).
///
/// Cho phép người dùng:
/// - Kéo (drag/pan) và phóng to/thu nhỏ (pinch-to-zoom) để căn chỉnh khuôn mặt vào ô tròn.
/// - Khung tròn ở trung tâm màn hình với viền Teal và lớp phủ mờ tối xung quanh.
/// - Giới hạn di chuyển đảm bảo ảnh luôn lấp đầy ô tròn.
/// - Cắt ảnh chính xác theo vùng hiển thị trong ô tròn và nén thành ảnh vuông chuẩn avatar.
class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage({
    super.key,
    required this.imageBytes,
    this.isFromCamera = false,
    this.initialImageWidth,
    this.initialImageHeight,
    this.customCropWorker,
  });

  /// Dữ liệu ảnh gốc (chụp từ camera hoặc chọn từ thư viện).
  final Uint8List imageBytes;

  /// Nguồn ảnh có phải từ camera hay không (để hiển thị nhãn "Chụp lại" hoặc "Hủy").
  final bool isFromCamera;

  /// Chiều rộng ban đầu (nếu đã biết trước, hữu ích cho testing).
  final int? initialImageWidth;

  /// Chiều cao ban đầu (nếu đã biết trước, hữu ích cho testing).
  final int? initialImageHeight;

  /// Dependency seam phục vụ Widget Test (nếu muốn mock logic crop).
  final Future<Uint8List> Function(Uint8List rawBytes, Rect cropRectNorm)?
      customCropWorker;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  late int _imageWidth;
  late int _imageHeight;
  bool _isCropping = false;

  // Trạng thái thu phóng và dịch chuyển ảnh
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _baseOffset = Offset.zero;
  Offset? _focalStart;

  @override
  void initState() {
    super.initState();
    _initDimensions();
  }

  void _initDimensions() {
    if (widget.initialImageWidth != null && widget.initialImageHeight != null) {
      _imageWidth = widget.initialImageWidth!;
      _imageHeight = widget.initialImageHeight!;
      return;
    }

    try {
      final decoded = img.decodeImage(widget.imageBytes);
      if (decoded != null) {
        _imageWidth = decoded.width;
        _imageHeight = decoded.height;
        return;
      }
    } catch (_) {}

    _imageWidth = 1000;
    _imageHeight = 1000;
  }

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Future<void> _handleConfirmCrop(double diameter, Offset center) async {
    if (_isCropping) return;

    setState(() => _isCropping = true);

    try {
      final radius = diameter / 2;
      final imgRatio = _imageWidth / _imageHeight;
      final baseW = (imgRatio >= 1.0) ? diameter * imgRatio : diameter;
      final baseH = (imgRatio >= 1.0) ? diameter : diameter / imgRatio;

      final currentW = baseW * _scale;
      final currentH = baseH * _scale;

      final imgLeft = center.dx + _offset.dx - currentW / 2;
      final imgTop = center.dy + _offset.dy - currentH / 2;

      final cropLeft = center.dx - radius;
      final cropTop = center.dy - radius;

      final normLeft = ((cropLeft - imgLeft) / currentW).clamp(0.0, 1.0);
      final normTop = ((cropTop - imgTop) / currentH).clamp(0.0, 1.0);
      final normWidth = (diameter / currentW).clamp(0.0, 1.0 - normLeft);
      final normHeight = (diameter / currentH).clamp(0.0, 1.0 - normTop);

      final cropRectNorm =
          Rect.fromLTWH(normLeft, normTop, normWidth, normHeight);

      Uint8List croppedBytes;
      if (widget.customCropWorker != null) {
        croppedBytes =
            await widget.customCropWorker!(widget.imageBytes, cropRectNorm);
      } else {
        try {
          croppedBytes = await compute(
            _cropWorker,
            _CropParams(
              rawBytes: widget.imageBytes,
              normLeft: normLeft,
              normTop: normTop,
              normWidth: normWidth,
              normHeight: normHeight,
              outputSize: 512,
            ),
          );
        } catch (_) {
          // Fallback chạy trực tiếp nếu isolate lỗi
          croppedBytes = _cropWorker(
            _CropParams(
              rawBytes: widget.imageBytes,
              normLeft: normLeft,
              normTop: normTop,
              normWidth: normWidth,
              normHeight: normHeight,
              outputSize: 512,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(croppedBytes);
      }
    } catch (e) {
      debugPrint('Error cropping avatar: $e');
      if (mounted) {
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Căn chỉnh ảnh thất bại. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Thanh tiêu đề trên cùng
            _buildTopBar(),

            // 2. Khu vực căn chỉnh ảnh có ô tròn
            Expanded(
              child: LayoutBuilder(
                      builder: (context, constraints) {
                        final diameter = math
                            .min(
                              constraints.maxWidth * 0.76,
                              constraints.maxHeight * 0.54,
                            )
                            .clamp(200.0, 340.0);
                        final radius = diameter / 2;
                        final center = Offset(
                          constraints.maxWidth / 2,
                          constraints.maxHeight / 2 - 16,
                        );

                        final imgRatio = _imageWidth / _imageHeight;
                        final baseW = (imgRatio >= 1.0)
                            ? diameter * imgRatio
                            : diameter;
                        final baseH = (imgRatio >= 1.0)
                            ? diameter
                            : diameter / imgRatio;

                        final currentW = baseW * _scale;
                        final currentH = baseH * _scale;

                        final imgLeft = center.dx + _offset.dx - currentW / 2;
                        final imgTop = center.dy + _offset.dy - currentH / 2;

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Lớp cử chỉ và hiển thị ảnh
                            GestureDetector(
                              key: const Key('avatar-crop-gesture-area'),
                              behavior: HitTestBehavior.opaque,
                              onScaleStart: (details) {
                                _baseScale = _scale;
                                _baseOffset = _offset;
                                _focalStart = details.localFocalPoint;
                              },
                              onScaleUpdate: (details) {
                                final newScale =
                                    (_baseScale * details.scale).clamp(1.0, 4.0);
                                final focalDelta =
                                    details.localFocalPoint - _focalStart!;
                                final newOffset = _baseOffset + focalDelta;

                                final curW = baseW * newScale;
                                final curH = baseH * newScale;
                                final maxDx = math.max(0.0, (curW - diameter) / 2);
                                final maxDy = math.max(0.0, (curH - diameter) / 2);

                                setState(() {
                                  _scale = newScale;
                                  _offset = Offset(
                                    newOffset.dx.clamp(-maxDx, maxDx),
                                    newOffset.dy.clamp(-maxDy, maxDy),
                                  );
                                });
                              },
                              onDoubleTap: () {
                                setState(() {
                                  if (_scale > 1.2) {
                                    _scale = 1.0;
                                    _offset = Offset.zero;
                                  } else {
                                    _scale = 2.0;
                                  }
                                });
                              },
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: imgLeft,
                                    top: imgTop,
                                    width: currentW,
                                    height: currentH,
                                    child: Image.memory(
                                      widget.imageBytes,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Lớp phủ mờ tối bên ngoài và đục lỗ tròn ở giữa
                            IgnorePointer(
                              child: CustomPaint(
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                painter: _AvatarCropOverlayPainter(
                                  center: center,
                                  radius: radius,
                                  overlayColor:
                                      Colors.black.withValues(alpha: 0.68),
                                  borderColor: const Color(0xFF14B8A6),
                                  borderWidth: 2.5,
                                ),
                              ),
                            ),

                            // Hướng dẫn thao tác kéo & phóng to
                            Positioned(
                              top: center.dy + radius + 22,
                              left: 20,
                              right: 20,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.pinch_rounded,
                                        color: Color(0xFF14B8A6),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Kéo hoặc thu phóng để căn chỉnh',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // 3. Thanh điều khiển phía dưới
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút quay lại / hủy
          IconButton(
            key: const Key('avatar-crop-back-button'),
            icon: const Icon(
              HugeIcons.strokeRoundedArrowLeft01,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Tiêu đề
          Text(
            'Căn chỉnh ảnh đại diện',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          // Nút Reset góc nhìn
          IconButton(
            key: const Key('avatar-crop-reset-button'),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Đặt lại',
            onPressed: _resetTransform,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          // Nút Chụp lại / Hủy
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('avatar-crop-cancel-button'),
              onPressed: _isCropping ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                widget.isFromCamera
                    ? HugeIcons.strokeRoundedReload
                    : HugeIcons.strokeRoundedCancel01,
                size: 18,
              ),
              label: Text(
                widget.isFromCamera ? 'Chụp lại' : 'Hủy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nút Dùng ảnh này (Xác nhận và cắt ảnh)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              key: const Key('avatar-crop-confirm-button'),
              onPressed: _isCropping
                  ? null
                  : () {
                      final size = MediaQuery.of(context).size;
                      final diameter = math
                          .min(size.width * 0.76, size.height * 0.54)
                          .clamp(200.0, 340.0);
                      final center = Offset(size.width / 2, size.height / 2 - 16);
                      _handleConfirmCrop(diameter, center);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isCropping
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      HugeIcons.strokeRoundedCheckmarkCircle02,
                      size: 18,
                    ),
              label: Text(
                _isCropping ? 'Đang xử lý...' : 'Dùng ảnh này',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ lớp phủ tối toàn màn hình và chừa lỗ tròn trong suốt ở tâm.
class _AvatarCropOverlayPainter extends CustomPainter {
  _AvatarCropOverlayPainter({
    required this.center,
    required this.radius,
    required this.overlayColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final Offset center;
  final double radius;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Phủ mờ toàn màn hình trừ đi hình tròn avatar
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final transparentHole = Path.combine(
      PathOperation.difference,
      backgroundPath,
      circlePath,
    );

    final paintBg = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(transparentHole, paintBg);

    // 2. Vẽ viền tròn nổi bật quanh avatar
    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(center, radius, paintBorder);
  }

  @override
  bool shouldRepaint(covariant _AvatarCropOverlayPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.center != center ||
        oldDelegate.borderColor != borderColor;
  }
}

class _CropParams {
  _CropParams({
    required this.rawBytes,
    required this.normLeft,
    required this.normTop,
    required this.normWidth,
    required this.normHeight,
    required this.outputSize,
  });

  final Uint8List rawBytes;
  final double normLeft;
  final double normTop;
  final double normWidth;
  final double normHeight;
  final int outputSize;
}

Uint8List _cropWorker(_CropParams params) {
  final original = img.decodeImage(params.rawBytes);
  if (original == null) return params.rawBytes;

  final oriented = img.bakeOrientation(original);
  final w = oriented.width;
  final h = oriented.height;

  final x = (params.normLeft * w).round().clamp(0, w - 1);
  final y = (params.normTop * h).round().clamp(0, h - 1);
  final cropW = (params.normWidth * w).round().clamp(1, w - x);
  final cropH = (params.normHeight * h).round().clamp(1, h - y);

  final side = math.min(cropW, cropH);
  final cropped =
      img.copyCrop(oriented, x: x, y: y, width: side, height: side);
  final resized =
      img.copyResize(cropped, width: params.outputSize, height: params.outputSize);
  return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
}
