import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/captured_bill_photo.dart';

class PhotoCropDialog extends StatefulWidget {
  const PhotoCropDialog({
    super.key,
    required this.photo,
  });

  final CapturedBillPhoto photo;

  static Future<Uint8List?> show(
    BuildContext context, {
    required CapturedBillPhoto photo,
  }) {
    return showDialog<Uint8List?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => PhotoCropDialog(photo: photo),
    );
  }

  @override
  State<PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<PhotoCropDialog> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  bool _isCropping = false;

  // Normalized crop coordinates in [0.0, 1.0] range (relative to rendered image rect)
  Rect _cropRectNorm = const Rect.fromLTWH(0.05, 0.05, 0.90, 0.90);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.photo.bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetCrop() {
    setState(() {
      _cropRectNorm = const Rect.fromLTWH(0.02, 0.02, 0.96, 0.96);
    });
  }

  Future<void> _applyCrop() async {
    if (_decodedImage == null || _isCropping) return;

    setState(() => _isCropping = true);

    try {
      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();

      // Convert normalized rect to actual pixel coordinates
      final srcLeft = (_cropRectNorm.left * imgW).clamp(0.0, imgW - 10);
      final srcTop = (_cropRectNorm.top * imgH).clamp(0.0, imgH - 10);
      final srcRight = (_cropRectNorm.right * imgW).clamp(srcLeft + 10, imgW);
      final srcBottom = (_cropRectNorm.bottom * imgH).clamp(srcTop + 10, imgH);

      final cropWidth = (srcRight - srcLeft).round();
      final cropHeight = (srcBottom - srcTop).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final srcRect = Rect.fromLTRB(srcLeft, srcTop, srcRight, srcBottom);
      final dstRect = Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble());

      canvas.drawImageRect(_decodedImage!, srcRect, dstRect, Paint());

      final picture = recorder.endRecording();
      final croppedImg = await picture.toImage(cropWidth, cropHeight);
      final byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        Navigator.of(context).pop(byteData.buffer.asUint8List());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCropping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Column(
        children: [
          // 1. Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.crop_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Cắt xén hoá đơn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _resetCrop,
                      icon: const Icon(HugeIcons.strokeRoundedReload, size: 16, color: Color(0xFF94A3B8)),
                      label: Text(
                        'Đặt lại',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(HugeIcons.strokeRoundedCancel01, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Interactive Crop Canvas Area
          Expanded(
            child: Container(
              color: const Color(0xFF0F172A),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : (_decodedImage == null
                      ? Center(
                          child: Text(
                            'Không tải được ảnh',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return _CropView(
                              image: _decodedImage!,
                              viewSize: Size(constraints.maxWidth, constraints.maxHeight),
                              cropRectNorm: _cropRectNorm,
                              onCropChanged: (newRect) {
                                setState(() => _cropRectNorm = newRect);
                              },
                            );
                          },
                        )),
            ),
          ),

          // 3. Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Hủy',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCropping ? null : _applyCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isCropping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Cắt ảnh này',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropView extends StatefulWidget {
  const _CropView({
    required this.image,
    required this.viewSize,
    required this.cropRectNorm,
    required this.onCropChanged,
  });

  final ui.Image image;
  final Size viewSize;
  final Rect cropRectNorm;
  final ValueChanged<Rect> onCropChanged;

  @override
  State<_CropView> createState() => _CropViewState();
}

enum _ActiveDragHandle { none, center, topLeft, topRight, bottomLeft, bottomRight }

class _CropViewState extends State<_CropView> {
  _ActiveDragHandle _activeHandle = _ActiveDragHandle.none;
  Offset? _lastPanPos;

  Rect _calculateFittedImageRect() {
    final imgAspect = widget.image.width / widget.image.height;
    final viewAspect = widget.viewSize.width / widget.viewSize.height;

    double renderW, renderH;
    if (imgAspect > viewAspect) {
      renderW = widget.viewSize.width;
      renderH = renderW / imgAspect;
    } else {
      renderH = widget.viewSize.height;
      renderW = renderH * imgAspect;
    }

    final offsetX = (widget.viewSize.width - renderW) / 2;
    final offsetY = (widget.viewSize.height - renderH) / 2;

    return Rect.fromLTWH(offsetX, offsetY, renderW, renderH);
  }

  void _onPanStart(DragStartDetails details, Rect fittedRect) {
    final touchPos = details.localPosition;
    final normTouch = Offset(
      (touchPos.dx - fittedRect.left) / fittedRect.width,
      (touchPos.dy - fittedRect.top) / fittedRect.height,
    );

    const hitRadiusNorm = 0.08;
    final c = widget.cropRectNorm;

    if ((normTouch - c.topLeft).distance < hitRadiusNorm) {
      _activeHandle = _ActiveDragHandle.topLeft;
    } else if ((normTouch - c.topRight).distance < hitRadiusNorm) {
      _activeHandle = _ActiveDragHandle.topRight;
    } else if ((normTouch - c.bottomLeft).distance < hitRadiusNorm) {
      _activeHandle = _ActiveDragHandle.bottomLeft;
    } else if ((normTouch - c.bottomRight).distance < hitRadiusNorm) {
      _activeHandle = _ActiveDragHandle.bottomRight;
    } else if (c.contains(normTouch)) {
      _activeHandle = _ActiveDragHandle.center;
    } else {
      _activeHandle = _ActiveDragHandle.none;
    }

    _lastPanPos = touchPos;
  }

  void _onPanUpdate(DragUpdateDetails details, Rect fittedRect) {
    if (_activeHandle == _ActiveDragHandle.none || _lastPanPos == null) return;

    final dxNorm = details.delta.dx / fittedRect.width;
    final dyNorm = details.delta.dy / fittedRect.height;
    final c = widget.cropRectNorm;

    double left = c.left;
    double top = c.top;
    double right = c.right;
    double bottom = c.bottom;

    const minSize = 0.12;

    switch (_activeHandle) {
      case _ActiveDragHandle.topLeft:
        left = (left + dxNorm).clamp(0.0, right - minSize);
        top = (top + dyNorm).clamp(0.0, bottom - minSize);
        break;
      case _ActiveDragHandle.topRight:
        right = (right + dxNorm).clamp(left + minSize, 1.0);
        top = (top + dyNorm).clamp(0.0, bottom - minSize);
        break;
      case _ActiveDragHandle.bottomLeft:
        left = (left + dxNorm).clamp(0.0, right - minSize);
        bottom = (bottom + dyNorm).clamp(top + minSize, 1.0);
        break;
      case _ActiveDragHandle.bottomRight:
        right = (right + dxNorm).clamp(left + minSize, 1.0);
        bottom = (bottom + dyNorm).clamp(top + minSize, 1.0);
        break;
      case _ActiveDragHandle.center:
        final w = right - left;
        final h = bottom - top;
        left = (left + dxNorm).clamp(0.0, 1.0 - w);
        top = (top + dyNorm).clamp(0.0, 1.0 - h);
        right = left + w;
        bottom = top + h;
        break;
      case _ActiveDragHandle.none:
        break;
    }

    widget.onCropChanged(Rect.fromLTRB(left, top, right, bottom));
  }

  void _onPanEnd(DragEndDetails details) {
    _activeHandle = _ActiveDragHandle.none;
    _lastPanPos = null;
  }

  @override
  Widget build(BuildContext context) {
    final fittedRect = _calculateFittedImageRect();

    return GestureDetector(
      onPanStart: (d) => _onPanStart(d, fittedRect),
      onPanUpdate: (d) => _onPanUpdate(d, fittedRect),
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        size: widget.viewSize,
        painter: _CropPainter(
          image: widget.image,
          fittedRect: fittedRect,
          cropRectNorm: widget.cropRectNorm,
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect fittedRect;
  final Rect cropRectNorm;

  _CropPainter({
    required this.image,
    required this.fittedRect,
    required this.cropRectNorm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw scaled original image
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, srcRect, fittedRect, Paint());

    // 2. Calculate pixel crop rect
    final cropPixelRect = Rect.fromLTRB(
      fittedRect.left + cropRectNorm.left * fittedRect.width,
      fittedRect.top + cropRectNorm.top * fittedRect.height,
      fittedRect.left + cropRectNorm.right * fittedRect.width,
      fittedRect.top + cropRectNorm.bottom * fittedRect.height,
    );

    // 3. Dark mask outside crop window
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropPixelRect)
      ..fillType = PathFillType.evenOdd;

    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);
    canvas.drawPath(maskPath, maskPaint);

    // 4. White & Teal Border
    final borderPaint = Paint()
      ..color = const Color(0xFF14B8A6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(cropPixelRect, borderPaint);

    // 5. 3x3 Grid Lines inside crop window
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final wThird = cropPixelRect.width / 3;
    final hThird = cropPixelRect.height / 3;

    canvas.drawLine(
      Offset(cropPixelRect.left + wThird, cropPixelRect.top),
      Offset(cropPixelRect.left + wThird, cropPixelRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropPixelRect.left + wThird * 2, cropPixelRect.top),
      Offset(cropPixelRect.left + wThird * 2, cropPixelRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropPixelRect.left, cropPixelRect.top + hThird),
      Offset(cropPixelRect.right, cropPixelRect.top + hThird),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropPixelRect.left, cropPixelRect.top + hThird * 2),
      Offset(cropPixelRect.right, cropPixelRect.top + hThird * 2),
      gridPaint,
    );

    // 6. Corner handles
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 18.0;
    final l = cropPixelRect.left;
    final t = cropPixelRect.top;
    final r = cropPixelRect.right;
    final b = cropPixelRect.bottom;

    // TL
    canvas.drawLine(Offset(l, t + cornerLen), Offset(l, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l + cornerLen, t), cornerPaint);

    // TR
    canvas.drawLine(Offset(r - cornerLen, t), Offset(r, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + cornerLen), cornerPaint);

    // BL
    canvas.drawLine(Offset(l, b - cornerLen), Offset(l, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l + cornerLen, b), cornerPaint);

    // BR
    canvas.drawLine(Offset(r - cornerLen, b), Offset(r, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.cropRectNorm != cropRectNorm || oldDelegate.fittedRect != fittedRect;
  }
}
