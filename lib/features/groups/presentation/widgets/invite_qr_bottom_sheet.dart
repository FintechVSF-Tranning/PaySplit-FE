import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/group_entity.dart';
import 'mock_qr_code.dart';
import 'sheet_shell.dart';

/// Sheet hiển thị mã QR mời vào nhóm (mocup — xem ghi chú ở [MockQrCode]).
class InviteQrBottomSheet extends StatelessWidget {
  const InviteQrBottomSheet({super.key, required this.group});

  final GroupEntity group;

  static Future<void> show(BuildContext context, GroupEntity group) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteQrBottomSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Mã QR mời vào nhóm',
      subtitle: 'Đưa thành viên quét mã này bằng chức năng “Quét QR vào nhóm”.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
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
                children: [
                  Text(group.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(
                    group.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    '${group.memberCount} thành viên',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  MockQrCode(data: group.inviteLink, size: 216, centerEmoji: group.emoji),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Text(
                      'Mã: ${group.inviteCode}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryActive,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Sao chép mã',
                    variant: AppButtonVariant.outline,
                    icon: const Icon(HugeIcons.strokeRoundedCopy01, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: group.inviteCode));
                      await HapticFeedback.lightImpact();
                      if (!context.mounted) return;
                      showSuccessSnackBar(context, 'Đã sao chép mã ${group.inviteCode}');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Lưu ảnh QR',
                    variant: AppButtonVariant.gradient,
                    icon: const Icon(HugeIcons.strokeRoundedQrCode, size: 18, color: Colors.white),
                    onPressed: () => showComingSoonSnackBar(context, 'Lưu ảnh QR'),
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
