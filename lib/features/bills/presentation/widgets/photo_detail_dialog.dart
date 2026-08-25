import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/captured_bill_photo.dart';
import 'photo_crop_dialog.dart';

class PhotoDetailDialog extends StatefulWidget {
  const PhotoDetailDialog({
    super.key,
    required this.photo,
    required this.currentIndex,
    required this.totalCount,
    required this.onDelete,
    required this.onRotate,
    this.onCrop,
  });

  final CapturedBillPhoto photo;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onDelete;
  final VoidCallback onRotate;
  final ValueChanged<Uint8List>? onCrop;

  static Future<void> show(
    BuildContext context, {
    required CapturedBillPhoto photo,
    required int currentIndex,
    required int totalCount,
    required VoidCallback onDelete,
    required VoidCallback onRotate,
    ValueChanged<Uint8List>? onCrop,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => PhotoDetailDialog(
        photo: photo,
        currentIndex: currentIndex,
        totalCount: totalCount,
        onDelete: onDelete,
        onRotate: onRotate,
        onCrop: onCrop,
      ),
    );
  }

  @override
  State<PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<PhotoDetailDialog> {
  late int _quarterTurns;

  @override
  void initState() {
    super.initState();
    _quarterTurns = widget.photo.rotationQuarterTurns;
  }

  void _handleRotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
    widget.onRotate();
  }

  Future<void> _handleCrop() async {
    final croppedBytes = await PhotoCropDialog.show(context, photo: widget.photo);
    if (croppedBytes != null && mounted) {
      widget.onCrop?.call(croppedBytes);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Content Container
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar in Dialog
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Index indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Ảnh ${widget.currentIndex + 1}/${widget.totalCount}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Actions: Crop & Rotate & Delete & Close
                    Row(
                      children: [
                        // Crop button
                        IconButton(
                          onPressed: _handleCrop,
                          icon: const Icon(Icons.crop_rounded, color: Colors.white, size: 20),
                          tooltip: 'Cắt xén',
                        ),
                        // Rotate button
                        IconButton(
                          onPressed: _handleRotate,
                          icon: const Icon(HugeIcons.strokeRoundedRotateRight01, color: Colors.white, size: 20),
                          tooltip: 'Xoay ảnh 90°',
                        ),
                        // Delete button
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onDelete();
                          },
                          icon: const Icon(HugeIcons.strokeRoundedDelete02, color: Color(0xFFEF4444), size: 20),
                          tooltip: 'Xóa ảnh này',
                        ),
                        // Close button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(HugeIcons.strokeRoundedCancel01, color: Colors.white, size: 20),
                          tooltip: 'Đóng',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Image Preview Area (Interactive Viewer)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: _quarterTurns,
                        child: Image.memory(
                          widget.photo.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
