import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:fpdart/fpdart.dart' hide State;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/invite_resolver.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import 'invite_sheet_states.dart';
import 'invite_qr_code.dart';
import 'sheet_shell.dart';
import 'group_avatar.dart';

/// Sheet hiển thị mã QR mời vào nhóm.
///
/// QR mã hóa `invite_url` thật do backend cấp và quét được bằng máy quét bất kỳ.
class InviteQrBottomSheet extends StatefulWidget {
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
  State<InviteQrBottomSheet> createState() => _InviteQrBottomSheetState();
}

class _InviteQrBottomSheetState extends State<InviteQrBottomSheet> {
  late Future<Either<Failure, GroupInvite>> _future;

  GroupEntity get group => widget.group;

  @override
  void initState() {
    super.initState();
    _future = resolveGroupInvite(group.id);
  }

  void _reload() => setState(() => _future = resolveGroupInvite(group.id));

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Mã QR mời vào nhóm',
      subtitle: 'Đưa thành viên quét mã này bằng chức năng “Quét QR vào nhóm”.',
      child: FutureBuilder<Either<Failure, GroupInvite>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const InviteSheetLoading();
          }
          final result = snapshot.data;
          if (result == null) {
            return InviteSheetError(message: 'Không tải được mã mời.', onRetry: _reload);
          }
          return result.fold(
            (failure) => InviteSheetError(message: failure.message, onRetry: _reload),
            (invite) => _body(context, invite),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, GroupInvite invite) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final codeBg = isDark ? const Color(0xFF0F766E).withValues(alpha: 0.25) : AppColors.primarySubtle;
    final codeBorder = isDark ? const Color(0xFF14B8A6).withValues(alpha: 0.4) : AppColors.primaryBorder;
    final codeColor = isDark ? const Color(0xFF14B8A6) : AppColors.primaryActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                GroupAvatar(group: group),
                const SizedBox(height: 6),
                Text(
                  group.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                Text(
                  '${group.memberCount} thành viên',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InviteQrCodeWithLabel(
                    data: invite.inviteUrl,
                    size: 200,
                    centerLabel: group.initials,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: codeBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: codeBorder),
                  ),
                  child: Text(
                    'Mã: ${invite.code}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: codeColor,
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
                    await Clipboard.setData(ClipboardData(text: invite.code));
                    await HapticFeedback.lightImpact();
                    if (!context.mounted) return;
                    showSuccessSnackBar(context, 'Đã sao chép mã ${invite.code}');
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
    );
  }
}
