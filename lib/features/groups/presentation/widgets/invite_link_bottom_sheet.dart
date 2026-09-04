import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:fpdart/fpdart.dart' hide State;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../di/injection.dart';
import '../../data/invite_resolver.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/create_invite_usecase.dart';
import 'invite_sheet_states.dart';
import 'sheet_shell.dart';
import 'group_avatar.dart';

/// Sheet hiển thị link mời của nhóm.
///
/// Mã mời không nằm trong `GET /groups`, nên sheet tự tải qua
/// [resolveGroupInvite]: đọc mã còn hiệu lực trước, chỉ tạo mới khi nhóm chưa
/// có mã nào.
class InviteLinkBottomSheet extends StatefulWidget {
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
  State<InviteLinkBottomSheet> createState() => _InviteLinkBottomSheetState();
}

class _InviteLinkBottomSheetState extends State<InviteLinkBottomSheet> {
  late Future<Either<Failure, GroupInvite>> _future;
  bool _isRegenerating = false;

  GroupEntity get group => widget.group;

  @override
  void initState() {
    super.initState();
    _future = resolveGroupInvite(group.id);
  }

  void _reload() => setState(() => _future = resolveGroupInvite(group.id));

  /// Thu hồi mã hiện tại và sinh mã mới bằng `regenerate: true` — chỉ Captain
  /// được backend cho phép gửi cấu hình này.
  Future<void> _regenerate() async {
    setState(() => _isRegenerating = true);
    final result = await getIt<CreateInviteUseCase>().call(
      CreateInviteParams(groupId: group.id, regenerate: true),
    );
    if (!mounted) return;
    setState(() {
      _isRegenerating = false;
      _future = Future.value(result);
    });
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      showErrorSnackBar(context, failure.message);
    } else {
      showSuccessSnackBar(context, 'Đã tạo link mời mới');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Link mời vào nhóm',
      subtitle: 'Người nhận chỉ cần bấm vào link là tham gia ngay.',
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
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final primaryColor = isDark ? const Color(0xFF14B8A6) : AppColors.primary;
    final urlBg = isDark ? const Color(0xFF0F766E).withValues(alpha: 0.25) : AppColors.primarySubtle;
    final urlBorder = isDark ? const Color(0xFF14B8A6).withValues(alpha: 0.4) : AppColors.primaryBorder;
    final codeBoxBg = isDark ? const Color(0xFF0F172A) : AppColors.surfaceMuted;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
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
              color: textMain,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            decoration: BoxDecoration(
              color: urlBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: urlBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    invite.inviteUrl,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép link',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: invite.inviteUrl));
                    await HapticFeedback.lightImpact();
                    if (!context.mounted) return;
                    showSuccessSnackBar(context, 'Đã sao chép link mời');
                  },
                  icon: Icon(
                    HugeIcons.strokeRoundedCopy01,
                    size: 20,
                    color: primaryColor,
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
              color: textMain,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: codeBoxBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text(
                  invite.code,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: invite.code));
                  await HapticFeedback.lightImpact();
                  if (!context.mounted) return;
                  showSuccessSnackBar(context, 'Đã sao chép mã ${invite.code}');
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
                  isLoading: _isRegenerating,
                  icon: const Icon(HugeIcons.strokeRoundedReload, size: 18),
                  onPressed: _isRegenerating ? null : _regenerate,
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
    );
  }
}

/// Hàng preview nhóm dùng chung cho sheet link mời & QR mời.
class _GroupPreviewRow extends StatelessWidget {
  const _GroupPreviewRow({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final avatarBoxBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarBoxBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: GroupAvatar(group: group, size: 44),
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
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.memberCount} thành viên',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
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
