import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Node của các ô phía sau, để phím Next của ô trước nhảy đúng thứ tự.
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_validatePassword);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final text = _newPasswordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
      _hasDigit = RegExp(r'[0-9]').hasMatch(text);
    });
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;

    if (!_hasMinLength || !_hasUppercase || !_hasDigit) {
      showErrorSnackBar(context, 'Vui lòng đáp ứng đầy đủ các yêu cầu bảo mật mật khẩu');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        showErrorSnackBar(context, 'Mật khẩu xác nhận không khớp');
        return;
      }

      setState(() => _isLoading = true);
      try {
        await ref.read(authControllerProvider.notifier).changePassword(
              currentPassword: _currentPasswordController.text,
              newPassword: _newPasswordController.text,
            );
        if (mounted) {
          showSuccessSnackBar(context, 'Đã đổi mật khẩu thành công!');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          final message = e is Failure ? e.message : 'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại mật khẩu hiện tại.';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Đổi mật khẩu',
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
                    // Mật khẩu hiện tại
                    _buildFieldLabel('Mật khẩu hiện tại', textMuted),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) =>
                          _newPasswordFocusNode.requestFocus(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: textMain),
                      decoration: _buildInputDecoration(
                        hint: 'Nhập mật khẩu hiện tại',
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent ? HugeIcons.strokeRoundedViewOffSlash : HugeIcons.strokeRoundedView,
                            size: 19,
                            color: textMuted,
                          ),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                    ),
                    const SizedBox(height: 16),

                    // Mật khẩu mới
                    _buildFieldLabel('Mật khẩu mới', textMuted),
                    TextFormField(
                      controller: _newPasswordController,
                      focusNode: _newPasswordFocusNode,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) =>
                          _confirmPasswordFocusNode.requestFocus(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: textMain),
                      decoration: _buildInputDecoration(
                        hint: 'Nhập mật khẩu mới',
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? HugeIcons.strokeRoundedViewOffSlash : HugeIcons.strokeRoundedView,
                            size: 19,
                            color: textMuted,
                          ),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập mật khẩu mới' : null,
                    ),
                    const SizedBox(height: 10),

                    // Live Checklist Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          _buildCheckItem('Tối thiểu 8 ký tự', _hasMinLength, isDark),
                          const SizedBox(height: 6),
                          _buildCheckItem('Có ít nhất 1 chữ cái viết hoa', _hasUppercase, isDark),
                          const SizedBox(height: 6),
                          _buildCheckItem('Có ít nhất 1 chữ số', _hasDigit, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Xác nhận mật khẩu mới
                    _buildFieldLabel('Xác nhận mật khẩu mới', textMuted),
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _onSubmit(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: textMain),
                      decoration: _buildInputDecoration(
                        hint: 'Nhập lại mật khẩu mới',
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? HugeIcons.strokeRoundedViewOffSlash : HugeIcons.strokeRoundedView,
                            size: 19,
                            color: textMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                        if (val != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
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
              child: InkWell(
                onTap: _onSubmit,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                            'Cập nhật mật khẩu',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
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

  Widget _buildCheckItem(String text, bool isValid, bool isDark) {
    final activeColor = const Color(0xFF059669);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isValid ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Icon(
              HugeIcons.strokeRoundedTick01,
              size: 10,
              color: isValid ? Colors.white : Colors.transparent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isValid ? FontWeight.w600 : FontWeight.w500,
            color: isValid ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: fill,
      suffixIcon: suffixIcon,
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
