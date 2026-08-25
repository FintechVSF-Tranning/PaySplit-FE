import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/entities/captured_bill_photo.dart';

class ImageViewerDialog extends StatefulWidget {
  final List<CapturedBillPhoto> photos;
  final int initialIndex;

  const ImageViewerDialog({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CapturedBillPhoto> photos,
    int initialIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => ImageViewerDialog(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, int> _rotations = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _rotateCurrent() {
    setState(() {
      final current = _rotations[_currentIndex] ?? 0;
      _rotations[_currentIndex] = (current + 90) % 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo PageView with InteractiveViewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              final rotation = _rotations[index] ?? 0;

              return InteractiveViewer(
                maxScale: 4.0,
                child: Center(
                  child: Transform.rotate(
                    angle: rotation * (math.pi / 180),
                    child: Image.memory(
                      photo.bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),

          // Top App Bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Ảnh ${_currentIndex + 1} / ${widget.photos.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                Row(
                  children: [
                    // Rotate Button
                    IconButton.filled(
                      onPressed: _rotateCurrent,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(HugeIcons.strokeRoundedRotateRight01, size: 20),
                    ),
                    const SizedBox(width: 8),
                    // Close Button
                    IconButton.filled(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
