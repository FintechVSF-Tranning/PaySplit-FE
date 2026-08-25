import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/bill_detail_entity.dart';

class SelectEvenSplitMembersModal extends StatefulWidget {
  final List<BillMemberEntity> members;
  final Set<String> initialSelectedMemberIds;
  final String creditorMemberId;
  final ValueChanged<Set<String>> onConfirm;

  const SelectEvenSplitMembersModal({
    super.key,
    required this.members,
    required this.initialSelectedMemberIds,
    required this.creditorMemberId,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BillMemberEntity> members,
    required Set<String> initialSelectedMemberIds,
    required String creditorMemberId,
    required ValueChanged<Set<String>> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectEvenSplitMembersModal(
        members: members,
        initialSelectedMemberIds: initialSelectedMemberIds,
        creditorMemberId: creditorMemberId,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<SelectEvenSplitMembersModal> createState() => _SelectEvenSplitMembersModalState();
}

class _SelectEvenSplitMembersModalState extends State<SelectEvenSplitMembersModal> {
  late Set<String> _selectedMemberIds;

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = Set<String>.from(
      widget.initialSelectedMemberIds.isNotEmpty
          ? widget.initialSelectedMemberIds
          : widget.members.map((m) => m.memberId),
    );
  }

  void _toggleAll() {
    setState(() {
      if (_selectedMemberIds.length == widget.members.length) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds.addAll(widget.members.map((m) => m.memberId));
      }
    });
  }

  void _toggleMember(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final isAllSelected = _selectedMemberIds.length == widget.members.length;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chọn người chia đều',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              TextButton(
                onPressed: _toggleAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                ),
                child: Text(
                  isAllSelected ? 'Bỏ chọn hết' : 'Chọn tất cả',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Member Selection List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.members.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
              itemBuilder: (context, idx) {
                final member = widget.members[idx];
                final isSelected = _selectedMemberIds.contains(member.memberId);
                final isCreditor = member.memberId == widget.creditorMemberId;

                return InkWell(
                  onTap: () => _toggleMember(member.memberId),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        // Checkbox
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (_) => _toggleMember(member.memberId),
                        ),
                        const SizedBox(width: 4),

                        // Avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                          child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                              ? Text(
                                  member.initials,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? AppColors.primary : textMuted,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Name & Role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? textMain : textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isCreditor) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Người trả trước (Chủ chi)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedMemberIds.isEmpty
                  ? null
                  : () {
                      widget.onConfirm(_selectedMemberIds);
                      Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedMemberIds.isNotEmpty
                    ? 'Xác nhận (${_selectedMemberIds.length} người)'
                    : 'Vui lòng chọn ít nhất 1 người',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
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
