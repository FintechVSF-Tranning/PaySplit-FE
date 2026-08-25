import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/group_entity.dart';
import 'sheet_shell.dart';

/// Sheet hiển thị link mời vừa được sinh cho nhóm.
///
/// Link mock dạng `https://paysplit.app/j/<inviteCode>` — khi nối API thật,
/// thay bằng response của `POST /api/v1/groups/{id}/invites`.
class InviteLinkBottomSheet extends StatelessWidget {
  const InviteLinkBottomSheet({super.key, required this.group});

  final GroupEntity group;

  static Future<void> show(BuildContext context, GroupEntity group) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteLinkBottomSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Link mời vào nhóm',
      subtitle: 'Link có hiệu lực 7 ngày. Người nhận chỉ cần bấm vào là tham gia ngay.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupPreviewRow(group: group),
            const SizedBox(height: 18),

            Text(
              'Đường dẫn mời',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.inviteLink,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryActive,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sao chép link',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: group.inviteLink));
                      await HapticFeedback.lightImpact();
                      if (!context.mounted) return;
                      showSuccessSnackBar(context, 'Đã sao chép link mời');
                    },
                    icon: const Icon(
                      HugeIcons.strokeRoundedCopy01,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Hoặc chia sẻ mã mời',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    group.inviteCode,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: group.inviteCode));
                    await HapticFeedback.lightImpact();
                    if (!context.mounted) return;
                    showSuccessSnackBar(context, 'Đã sao chép mã ${group.inviteCode}');
                  },
                  icon: const Icon(HugeIcons.strokeRoundedCopy01, size: 18),
                  label: Text(
                    'Sao chép mã',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Tạo link mới',
                    variant: AppButtonVariant.outline,
                    icon: const Icon(HugeIcons.strokeRoundedReload, size: 18),
                    onPressed: () => showComingSoonSnackBar(context, 'Thu hồi & tạo link mới'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Chia sẻ',
                    variant: AppButtonVariant.gradient,
                    icon: const Icon(
                      HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () => showComingSoonSnackBar(context, 'Chia sẻ hệ thống'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hàng preview nhóm dùng chung cho sheet link mời & QR mời.
class _GroupPreviewRow extends StatelessWidget {
  const _GroupPreviewRow({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(group.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.memberCount} thành viên',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
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
