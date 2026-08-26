import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../di/injection.dart';

class GroupItemData {
  const GroupItemData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.memberCount,
    required this.balanceText,
    this.isPositive = true,
  });

  final String id;
  final String name;
  final String emoji;
  final int memberCount;
  final String balanceText;
  final bool isPositive;
}

class GroupPickerBottomSheet extends StatelessWidget {
  const GroupPickerBottomSheet({
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.groups,
    super.key,
  });

  final String selectedGroupId;
  final ValueChanged<GroupItemData> onGroupSelected;
  final List<GroupItemData> groups;

  static Future<GroupItemData?> show(
    BuildContext context, {
    required String currentGroupId,
  }) async {
    List<GroupItemData> realGroups = [];
    try {
      final dio = getIt<Dio>();
      final response = await dio.get(ApiEndpoints.groups);
      if (response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final data = rawData['data'] as Map<String, dynamic>? ?? rawData;
        final list = data['groups'] as List? ?? const [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final group = item['group'] as Map<String, dynamic>? ?? item;
            final id = group['id'] as String? ?? item['id'] as String? ?? '';
            final name = group['name'] as String? ?? item['name'] as String? ?? '';
            final memberCount = item['active_member_count'] as int? ?? group['member_count'] as int? ?? 1;
            if (id.isNotEmpty) {
              String emoji = '👥';
              if (name.contains('Trưởng nhóm') || name.contains('1.')) {
                emoji = '👑';
              } else if (name.contains('Người tạo đơn') || name.contains('2.')) {
                emoji = '🍕';
              } else if (name.contains('Người bình thường') || name.contains('3.')) {
                emoji = '🏸';
              }

              realGroups.add(GroupItemData(
                id: id,
                name: name,
                emoji: emoji,
                memberCount: memberCount,
                balanceText: '0 đ',
              ));
            }
          }
        }
      }
    } catch (_) {
      // Ignored network errors
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<GroupItemData>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GroupPickerBottomSheet(
        selectedGroupId: currentGroupId,
        groups: realGroups,
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
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
                color: textMuted,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hóa đơn chụp sẽ được gán vào nhóm đã chọn để phân bổ chi phí.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // List of groups or Empty State
          if (groups.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      HugeIcons.strokeRoundedUserGroup,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Bạn chưa có nhóm nào',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hãy tạo nhóm chi tiêu trước khi chụp hoặc quét hóa đơn cùng bạn bè.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.groups);
                      },
                      icon: const Icon(HugeIcons.strokeRoundedPlusSign, size: 18, color: Colors.white),
                      label: Text(
                        'Tạo nhóm mới ngay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
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
                                    color: textMuted,
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
        ],
      ),
    );
  }
}
