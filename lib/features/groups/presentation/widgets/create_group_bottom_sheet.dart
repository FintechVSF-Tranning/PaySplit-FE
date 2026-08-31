import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/group_entity.dart';
import '../providers/groups_provider.dart';

/// Bottom sheet tạo nhóm chi tiêu mới (bo góc trên 24px, drag handle 40x4px).
///
/// Trả về [GroupEntity] vừa tạo qua `Navigator.pop`, hoặc `null` nếu người
/// dùng đóng sheet.
class CreateGroupBottomSheet extends ConsumerStatefulWidget {
  const CreateGroupBottomSheet({super.key});

  static Future<GroupEntity?> show(BuildContext context) {
    return showModalBottomSheet<GroupEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateGroupBottomSheet(),
    );
  }

  @override
  ConsumerState<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends ConsumerState<CreateGroupBottomSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    _controller.addListener(() {
      if (_errorText != null) setState(() => _errorText = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập tên nhóm chi tiêu');
      return;
    }
    if (name.length < 3) {
      setState(() => _errorText = 'Tên nhóm cần tối thiểu 3 ký tự');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    await HapticFeedback.mediumImpact();

    final group = await ref.read(groupsProvider.notifier).createGroup(name: name);
    if (!mounted) return;

    // Lỗi API: giữ sheet mở và hiện thông báo ngay dưới ô nhập, thay vì đóng
    // sheet và để người dùng không biết vì sao nhóm không được tạo.
    if (group == null) {
      setState(() {
        _isSubmitting = false;
        _errorText =
            ref.read(groupsProvider).failure?.message ?? 'Không tạo được nhóm. Vui lòng thử lại.';
      });
      return;
    }

    setState(() => _isSubmitting = false);
    Navigator.of(context).pop(group);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final handleColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle 40x4
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // Header: tiêu đề + nút đóng
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tạo nhóm chi tiêu mới',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        HugeIcons.strokeRoundedCancel01,
                        size: 22,
                        color: textMuted,
                      ),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên nhóm chi tiêu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _NameField(
                      controller: _controller,
                      focusNode: _focusNode,
                      errorText: _errorText,
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _errorText!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFF87171) : AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    AppButton(label: 'Tạo nhóm ngay', isLoading: _isSubmitting, onPressed: _submit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null;
    final isFocused = focusNode.hasFocus;

    final fieldBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final primaryColor = isDark ? const Color(0xFF14B8A6) : AppColors.primary;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSubtle = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final borderColor = hasError
        ? (isDark ? const Color(0xFFEF4444) : AppColors.danger)
        : isFocused
        ? primaryColor
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isFocused || hasError ? 1.5 : 1.2),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 50,
        onSubmitted: onSubmitted,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          hintText: 'Ví dụ: Du lịch Vũng Tàu 2026',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textSubtle,
          ),
        ),
      ),
    );
  }
}
