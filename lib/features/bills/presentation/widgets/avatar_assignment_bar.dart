import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_detail_entity.dart';

class AvatarAssignmentBar extends StatelessWidget {
  final BillItemEntity item;
  final List<BillMemberEntity> members;
  final bool isEditable;
  final Function(String memberId) onToggleMember;
  final VoidCallback onAssignAll;
  final VoidCallback onOpenDetail;

  const AvatarAssignmentBar({
    super.key,
    required this.item,
    required this.members,
    this.isEditable = true,
    required this.onToggleMember,
    required this.onAssignAll,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignedIds = item.assignments.map((a) => a.memberId).toSet();
    final assignedCount = assignedIds.length;

    // Sắp xếp: Đưa các thành viên đã được chọn lên đầu danh sách
    final sortedMembers = List<BillMemberEntity>.from(members)..sort((a, b) {
      final aAssigned = assignedIds.contains(a.memberId);
      final bAssigned = assignedIds.contains(b.memberId);
      if (aAssigned && !bAssigned) return -1;
      if (!aAssigned && bAssigned) return 1;
      return 0;
    });

    final costPerPerson = assignedCount > 0 ? (item.finalPrice ~/ assignedCount) : 0;
    final isAllAssigned = members.isNotEmpty && assignedCount == members.length;

    // Hiển thị tối đa 4 avatar, avatar thứ 5 là badge +N nếu còn dư
    final visibleMembers = sortedMembers.take(4).toList();
    final remainingCount = sortedMembers.length - 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // List of Avatars
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final member in visibleMembers) ...[
                      _buildAvatarBadge(
                        context,
                        member: member,
                        isSelected: assignedIds.contains(member.memberId),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // +N Badge if group has more than 4 members
                    if (remainingCount > 0)
                      InkWell(
                        onTap: onOpenDetail,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+$remainingCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
                       // "All" Button (Only visible if isEditable)
            if (isEditable)
              InkWell(
                onTap: onAssignAll,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAllAssigned
                        ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primarySubtle)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAllAssigned
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllAssigned
                            ? HugeIcons.strokeRoundedCheckmarkBadge01
                            : HugeIcons.strokeRoundedUserGroup,
                        size: 13,
                        color: isAllAssigned
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAllAssigned ? 'Tất cả (${members.length})' : '+ Tất cả',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isAllAssigned
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Subtitle: Cost per person & status
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (assignedCount > 0)
              Text(
                '➔ ${CurrencyFormatter.formatVND(costPerPerson.toDouble())} / người ($assignedCount người)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F766E),
                ),
              )
            else
              Row(
                children: [
                  const Icon(
                    HugeIcons.strokeRoundedAlertCircle,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Chưa gán cho ai trong nhóm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarBadge(
    BuildContext context, {
    required BillMemberEntity member,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = member.displayName.isNotEmpty
        ? member.displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'TV';

    return InkWell(
      onTap: isEditable ? () => onToggleMember(member.memberId) : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primarySubtle)
              : (isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.4)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Monogram Circle
            CircleAvatar(
              radius: 11,
              backgroundColor: isSelected
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              child: Text(
                initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              member.displayName.split(' ').last,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
