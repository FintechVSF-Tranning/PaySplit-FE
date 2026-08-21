import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late String _initialName;
  late String _initialPhone;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;

    _initialName = user?.name ?? '';
    _initialPhone = PhoneFormatter.formatForDisplay(user?.phoneNumber);

    _nameController = TextEditingController(text: _initialName);
    _phoneController = TextEditingController(text: _initialPhone);

    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isLoading) return;

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final phoneInput = _phoneController.text.trim();
        final normalizedPhone = phoneInput.isNotEmpty ? PhoneFormatter.normalizeForApi(phoneInput) : null;

        await ref.read(authControllerProvider.notifier).updateProfile(
              name: _nameController.text.trim(),
              phoneNumber: normalizedPhone,
            );

        if (mounted) {
          showSuccessSnackBar(context, 'Đã lưu thông tin cá nhân thành công!');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          final message = e is Failure ? e.message : 'Cập nhật thông tin thất bại. Vui lòng thử lại.';
          showErrorSnackBar(context, message);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final email = (user?.email != null && user!.email.isNotEmpty) ? user.email : '';

    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryTeal = const Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: textMain),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chỉnh sửa thông tin',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: border, height: 1),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THÔNG TIN CÁ NHÂN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field 1: Họ và tên
                    _buildFieldLabel('Họ và tên', textMuted),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: textMain, fontWeight: FontWeight.w600),
                      decoration: _buildInputDecoration('Ví dụ: Nguyen Van A', isDark),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Số điện thoại
                    _buildFieldLabel('Số điện thoại', textMuted),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.jetBrainsMono(fontSize: 14.5, color: textMain, fontWeight: FontWeight.w600),
                      decoration: _buildInputDecoration('Ví dụ: 0123456789', isDark),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final cleaned = val.trim().replaceAll(RegExp(r'\s+'), '');
                        final phoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
                        if (!phoneRegex.hasMatch(cleaned)) {
                          return 'Số điện thoại không hợp lệ (Ví dụ: 0123456789)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Email (Read only)
                    _buildFieldLabel('Email (Không thể thay đổi)', textMuted),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        email.isNotEmpty ? email : 'Chưa có email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  final hasChanged = _nameController.text.trim() != _initialName ||
                      _phoneController.text.trim() != _initialPhone;
                  final canSave = hasChanged && !_isLoading;

                  return InkWell(
                    onTap: canSave ? _onSave : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: canSave
                            ? const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: canSave
                            ? null
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canSave
                            ? [
                                BoxShadow(
                                  color: primaryTeal.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Lưu thay đổi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: canSave
                                      ? Colors.white
                                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool isDark) {
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
      ),
    );
  }
}
