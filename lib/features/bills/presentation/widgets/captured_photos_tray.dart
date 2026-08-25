import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/captured_bill_photo.dart';

class CapturedPhotosTray extends StatelessWidget {
  const CapturedPhotosTray({
    super.key,
    required this.photos,
    required this.maxCount,
    required this.onRemovePhoto,
    required this.onTapPhoto,
    required this.onReorderPhotos,
  });

  final List<CapturedBillPhoto> photos;
  final int maxCount;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<int> onTapPhoto;
  final void Function(int oldIndex, int newIndex) onReorderPhotos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header count badge & reorder instruction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ẢNH ĐÃ CHỌN (${photos.length}/$maxCount)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.drag_indicator, size: 13, color: Color(0xFF14B8A6)),
                    const SizedBox(width: 3),
                    Text(
                      'Kéo để đổi thứ tự',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF14B8A6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Horizontal Reorderable Photo Thumbnails
          SizedBox(
            height: 86,
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: photos.length,
                // ignore: deprecated_member_use
                onReorder: onReorderPhotos,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 12,
                        child: Transform.scale(
                          scale: 1.08,
                          child: child,
                        ),
                      );
                    },
                  );
                },
                itemBuilder: (context, index) {
                  final photo = photos[index];

                  return Container(
                    key: ValueKey(photo.id),
                    margin: const EdgeInsets.only(right: 14, top: 6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Thumbnail Card
                        Container(
                          width: 64,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.5),
                            child: Column(
                              children: [
                                // Photo Preview Area (Tap to view full screen)
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onTapPhoto(index),
                                    child: SizedBox.expand(
                                      child: RotatedBox(
                                        quarterTurns: photo.rotationQuarterTurns,
                                        child: Image.memory(
                                          photo.bytes,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Bottom Dedicated Drag Handle (Immediate Drag & Drop)
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: Colors.black.withValues(alpha: 0.8),
                                    child: const Center(
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Top-Right: Delete [✕] Button
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => onRemovePhoto(index),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  HugeIcons.strokeRoundedCancel01,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
