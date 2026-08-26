import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/invite_code.dart';
import '../../domain/usecases/preview_invite_usecase.dart';
import 'group_avatar.dart';

/// Sheet 2 bước: Nhập link/mã mời → Preview nhóm → Xác nhận tham gia.
///
/// Cả hai bước đều gọi backend thật: `GET /groups/invites/{code}` để xem trước
/// và `POST /groups/join` để vào nhóm.
class JoinByLinkBottomSheet extends StatefulWidget {
  const JoinByLinkBottomSheet({super.key});

  static Future<GroupEntity?> show(BuildContext context) {
    return showModalBottomSheet<GroupEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JoinByLinkBottomSheet(),
    );
  }

  @override
  State<JoinByLinkBottomSheet> createState() => _JoinByLinkBottomSheetState();
}

class _JoinByLinkBottomSheetState extends State<JoinByLinkBottomSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _isResolving = false;
  bool _isJoining = false;
  String? _errorText;
  GroupEntity? _preview;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final code = extractInviteCode(_controller.text);
    // Kiểm tra độ dài tại chỗ để báo lỗi ngay thay vì đợi một vòng API trả 404.
    if (code.length != kInviteCodeLength) {
      setState(() => _errorText = 'Link hoặc mã mời không hợp lệ');
      return;
    }

    setState(() {
      _errorText = null;
      _isResolving = true;
    });

    // `GET /groups/invites/{code}` chỉ trả thông tin xem trước, chưa đưa người
    // dùng vào nhóm; việc tham gia do `POST /groups/join` thực hiện sau đó.
    final result = await getIt<PreviewInviteUseCase>().call(code);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isResolving = false;
        _preview = null;
        _errorText = failure.message;
      }),
      (preview) => setState(() {
        _isResolving = false;
        _preview = GroupEntity(
          // Xem trước chưa biết id thật của nhóm; id chỉ có sau khi tham gia.
          id: 'preview:$code',
          name: preview.groupName,
          memberCount: preview.activeMemberCount,
          myBalance: 0,
          inviteCode: code,
          isCaptain: false,
          lastActivity: 'Trưởng nhóm: ${preview.captainDisplayName}',
        );
      }),
    );
  }

  Future<void> _join() async {
    setState(() => _isJoining = true);
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    // Màn hình gọi sheet này sẽ thực hiện `POST /groups/join` bằng inviteCode
    // đính kèm trong bản xem trước.
    Navigator.of(context).pop(_preview);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhập link vào nhóm',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preview == null
                                ? 'Bước 1/2 · Dán link mời hoặc nhập mã 8 ký tự (phân biệt hoa thường)'
                                : 'Bước 2/2 · Kiểm tra thông tin nhóm trước khi tham gia',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Đóng',
                      icon: const Icon(
                        HugeIcons.strokeRoundedCancel01,
                        size: 22,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: preview == null ? _buildInputStep() : _buildPreviewStep(preview),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputStep() {
    final hasError = _errorText != null;
    final borderColor = hasError
        ? AppColors.danger
        : _focusNode.hasFocus
        ? AppColors.borderFocus
        : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Icon(HugeIcons.strokeRoundedLink01, size: 19, color: AppColors.textMuted),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _resolve(),
                  onChanged: (_) {
                    if (_errorText != null) setState(() => _errorText = null);
                  },
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    hintText: 'paysplit.app/j/aB3xKm9Z',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dán từ clipboard',
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text?.trim();
                  if (text == null || text.isEmpty) return;
                  setState(() {
                    _controller.text = text;
                    _errorText = null;
                  });
                },
                icon: const Icon(HugeIcons.strokeRoundedCopy01, size: 19, color: AppColors.primary),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            _errorText!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppButton(label: 'Kiểm tra link mời', isLoading: _isResolving, onPressed: _resolve),
      ],
    );
  }

  Widget _buildPreviewStep(GroupEntity group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: GroupAvatar(group: group, size: 48),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${group.memberCount} thành viên · Mã ${group.inviteCode}',
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
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Nhập lại',
                variant: AppButtonVariant.outline,
                onPressed: () => setState(() => _preview = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Tham gia nhóm',
                variant: AppButtonVariant.gradient,
                isLoading: _isJoining,
                trailingIcon: const Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: _join,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
