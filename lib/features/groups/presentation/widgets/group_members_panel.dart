import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/group_detail_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import 'group_debts_panel.dart';

/// Tab "Thành viên": vai trò, số dư riêng và các thao tác quản trị.
class GroupMembersPanel extends StatelessWidget {
  const GroupMembersPanel({
    super.key,
    required this.detail,
    required this.onAddMember,
    required this.onLeaveGroup,
    this.canAddMember = true,
  });

  final GroupDetailEntity detail;
  final VoidCallback onAddMember;
  final VoidCallback onLeaveGroup;

  /// Nhóm đã khóa hóa đơn thì không mời thêm người nữa.
  final bool canAddMember;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupPanelHead(
          title: 'Thành viên',
          subtitle: 'Vai trò và số dư riêng trong nhóm',
          trailing: canAddMember
              ? _OutlineChipButton(label: '+ Thêm thành viên', onTap: onAddMember)
              : null,
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < detail.members.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.borderSubtle),
                _MemberTile(item: detail.members[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        OutlinedButton(
          onPressed: onLeaveGroup,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.dangerBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: Text(
            'Rời nhóm',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.item});

  final GroupMemberBalance item;

  @override
  Widget build(BuildContext context) {
    final isCaptain = item.member.role == GroupMemberRole.captain;
    final balanceColor = item.balance > 0
        ? AppColors.balancePositive
        : item.balance < 0
        ? AppColors.balanceNegative
        : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCaptain
                  ? const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isCaptain ? null : AppColors.surfaceMuted,
              border: isCaptain ? null : Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              item.member.initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCaptain ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    if (isCaptain) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              HugeIcons.strokeRoundedCrown,
                              size: 10,
                              color: AppColors.warningText,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Trưởng nhóm',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warningText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.isMe ? 'Bạn' : 'Thành viên',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.balance == 0
                ? CurrencyFormatter.vnd(0)
                : CurrencyFormatter.vndSigned(item.balance),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: balanceColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút chip viền mảnh dùng ở góc phải các panel head.
class _OutlineChipButton extends StatelessWidget {
  const _OutlineChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
