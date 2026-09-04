import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

/// Hộp thoại xem ảnh phóng to toàn màn hình hỗ trợ cả ảnh từ bộ nhớ (Uint8List) và URL mạng.
/// Hỗ trợ cử chỉ thu phóng (pinch-to-zoom), xoay ảnh và chạm đúp để phóng to.
class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    this.bytes,
    this.imageUrl,
    this.title,
    this.subtitle,
  }) : assert(
         bytes != null || imageUrl != null,
         'Cần truyền ít nhất một trong hai: bytes hoặc imageUrl',
       );

  final Uint8List? bytes;
  final String? imageUrl;
  final String? title;
  final String? subtitle;

  static Future<void> show(
    BuildContext context, {
    Uint8List? bytes,
    String? imageUrl,
    String? title,
    String? subtitle,
  }) {
    HapticFeedback.selectionClick();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => FullScreenImageViewer(
        bytes: bytes,
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  int _rotationQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = currentScale > 1.2 ? 1.0 : 2.5;

    final targetMatrix = Matrix4.identity();
    if (targetScale > 1.0) {
      final position = details.localPosition;
      targetMatrix
        ..translateByDouble(
          -position.dx * (targetScale - 1),
          -position.dy * (targetScale - 1),
          0.0,
          1.0,
        )
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward(from: 0);
  }

  void _rotate() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Image Viewer with Zoom & Pan & Double Tap
          GestureDetector(
            onDoubleTapDown: _handleDoubleTapDown,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Center(
                child: RotatedBox(
                  quarterTurns: _rotationQuarterTurns,
                  child: _buildImage(),
                ),
              ),
            ),
          ),

          // 2. Top App Bar (Header)
          Positioned(
            top: math.max(statusBarHeight, 16),
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Nút xoay ảnh
                IconButton.filled(
                  onPressed: _rotate,
                  tooltip: 'Xoay ảnh 90°',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(
                    HugeIcons.strokeRoundedRotateRight01,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                // Nút đóng
                IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Đóng',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(
                    HugeIcons.strokeRoundedCancel01,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Hint
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'Chụm tay để thu phóng • Chạm đúp để phóng to',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.bytes != null) {
      return Image.memory(
        widget.bytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    }

    if (widget.imageUrl != null) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    }

    return _buildError();
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            color: Colors.white54,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Không thể tải ảnh',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
