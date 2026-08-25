import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../providers/groups_provider.dart';
import '../widgets/invite_link_bottom_sheet.dart';
import '../widgets/invite_qr_bottom_sheet.dart';
import '../widgets/group_avatar.dart';

/// Màn hình thêm thành viên, mở ngay sau khi tạo nhóm thành công.
///
/// Gồm 2 lối mời: sinh link mời & sinh QR mời, cộng danh sách gợi ý
/// "Thành viên gần đây" tick chọn hàng loạt.
class AddMembersPage extends ConsumerStatefulWidget {
  const AddMembersPage({super.key, required this.group});

  final GroupEntity group;

  @override
  ConsumerState<AddMembersPage> createState() => _AddMembersPageState();
}

class _AddMembersPageState extends ConsumerState<AddMembersPage> {
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(GroupMemberEntity member) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.remove(member.id)) _selectedIds.add(member.id);
    });
  }

  void _finish(List<GroupMemberEntity> contacts) {
    final selected = contacts.where((c) => _selectedIds.contains(c.id)).toList();
    // Backend không có `POST /groups/{id}/members`: người được mời phải tự vào
    // bằng mã mời, nên ở đây chỉ cập nhật sĩ số hiển thị (mục 3.6).
    ref.read(groupsProvider.notifier).bumpMemberCountLocally(widget.group.id, selected.length);

    final message = selected.isEmpty
        ? 'Đã tạo nhóm ${widget.group.name}'
        : 'Đã thêm ${selected.length} thành viên vào ${widget.group.name}';
    showSuccessSnackBar(context, message);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(recentContactsProvider);
    final filtered = _query.isEmpty
        ? contacts
        : contacts
              .where(
                (c) =>
                    c.name.toLowerCase().contains(_query) ||
                    (c.phone ?? '').replaceAll(' ', '').contains(_query),
              )
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01, size: 22),
          color: AppColors.textMain,
        ),
        title: Text(
          'Thêm thành viên',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Bỏ qua',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _CreatedGroupBanner(group: widget.group),
                  const SizedBox(height: 18),

                  // 2 lối mời chính
                  Row(
                    children: [
                      Expanded(
                        child: _InviteActionCard(
                          icon: HugeIcons.strokeRoundedLink01,
                          title: 'Tạo link mời',
                          subtitle: 'Gửi qua Zalo, Messenger',
                          onTap: () => InviteLinkBottomSheet.show(context, widget.group),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InviteActionCard(
                          icon: HugeIcons.strokeRoundedQrCode,
                          title: 'Tạo QR mời',
                          subtitle: 'Quét trực tiếp tại chỗ',
                          onTap: () => InviteQrBottomSheet.show(context, widget.group),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thành viên gần đây',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (_selectedIds.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(_selectedIds.clear),
                          child: Text(
                            'Bỏ chọn',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'Không tìm thấy ai khớp “${_searchController.text.trim()}”',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContactTile(
                          member: member,
                          isSelected: _selectedIds.contains(member.id),
                          onTap: () => _toggle(member),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => showComingSoonSnackBar(context, 'Mời qua số điện thoại'),
                    icon: const Icon(HugeIcons.strokeRoundedUserAdd01, size: 18),
                    label: Text(
                      'Mời bằng số điện thoại',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sticky bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Chưa chọn thành viên nào'
                          : 'Đã chọn ${_selectedIds.length} thành viên',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedIds.isEmpty ? AppColors.textMuted : AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: AppButton(
                      label: _selectedIds.isEmpty ? 'Xong' : 'Thêm vào nhóm',
                      variant: AppButtonVariant.gradient,
                      trailingIcon: const Icon(
                        HugeIcons.strokeRoundedArrowRight01,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => _finish(contacts),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatedGroupBanner extends StatelessWidget {
  const _CreatedGroupBanner({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: GroupAvatar(group: group, size: 44),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      HugeIcons.strokeRoundedCheckmarkCircle02,
                      size: 15,
                      color: Color(0xFFA7F3D0),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Đã tạo nhóm thành công',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA7F3D0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Mã mời không đi kèm response nhóm; nó được tải trong sheet
                // "Link mời"/"QR mời" nên chỉ hiện ở đây khi đã biết.
                if (group.inviteCode != null)
                  Text(
                    'Mã mời: ${group.inviteCode}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 1,
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

class _InviteActionCard extends StatelessWidget {
  const _InviteActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Icon(icon, size: 19, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMain,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: const Icon(
            HugeIcons.strokeRoundedSearch01,
            size: 18,
            color: AppColors.textMuted,
          ),
          hintText: 'Tìm theo tên hoặc số điện thoại',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubtle,
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.member, required this.isSelected, required this.onTap});

  final GroupMemberEntity member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySubtle : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                member.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${member.phone} · ${member.sharedGroupCount} nhóm chung',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(HugeIcons.strokeRoundedTick01, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
