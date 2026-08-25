import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';

class GroupItemData {
  final String id;
  final String name;
  final String emoji;
  final int memberCount;
  final String balanceText;
  final bool isPositive;

  const GroupItemData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.memberCount,
    required this.balanceText,
    this.isPositive = false,
  });
}

class GroupPickerBottomSheet extends StatelessWidget {
  const GroupPickerBottomSheet({
    super.key,
    required this.selectedGroupId,
    required this.onGroupSelected,
    this.groups = _defaultGroups,
  });

  final String selectedGroupId;
  final ValueChanged<GroupItemData> onGroupSelected;
  final List<GroupItemData> groups;

  static const List<GroupItemData> _defaultGroups = [
    GroupItemData(
      id: '01a02363-242d-7cee-ae30-8f61857fd62c',
      name: 'Phòng Dev Cty',
      emoji: '💻',
      memberCount: 7,
      balanceText: '+350.000 đ',
      isPositive: true,
    ),
    GroupItemData(
      id: '01a02363-2431-7ca7-a2a2-7b68b461f712',
      name: 'Du lịch Đà Lạt 2026',
      emoji: '🏖️',
      memberCount: 5,
      balanceText: '-120.000 đ',
    ),
    GroupItemData(
      id: '01a02363-2432-72d9-a7d8-19af1fdf0fe3',
      name: 'Hội bạn thân C4',
      emoji: '☕',
      memberCount: 4,
      balanceText: '0 đ',
    ),
    GroupItemData(
      id: '01a02363-2432-75f2-a125-8a557f88ecfe',
      name: 'Ăn trưa K-Pub',
      emoji: '🥩',
      memberCount: 4,
      balanceText: '+50.000 đ',
      isPositive: true,
    ),
  ];

  static Future<GroupItemData?> show(
    BuildContext context, {
    required String currentGroupId,
  }) {
    return showModalBottomSheet<GroupItemData>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GroupPickerBottomSheet(
        selectedGroupId: currentGroupId,
        onGroupSelected: (group) => Navigator.of(ctx).pop(group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chọn nhóm chi tiêu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 20),
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hóa đơn chụp sẽ được gán vào nhóm đã chọn để phân bổ chi phí.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // List of groups
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final group = groups[index];
                final isSelected = group.id == selectedGroupId;

                return InkWell(
                  onTap: () => onGroupSelected(group),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primarySubtle)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Emoji Box
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(group.emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppColors.primary : textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.memberCount} thành viên',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selected checkmark
                        if (isSelected)
                          const Icon(
                            HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: AppColors.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
