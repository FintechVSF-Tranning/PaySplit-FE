import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/floating_input_card.dart';
import '../../../../core/widgets/fluid_top_wave.dart';
import '../../../../core/widgets/password_checklist.dart';
import '../providers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Node của các ô phía sau, để phím Next của ô trước nhảy đúng thứ tự.
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  bool _agreeTerms = true;
  bool _isLoading = false;
  String _passwordInput = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản dịch vụ'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      await ref.read(authControllerProvider.notifier).register(
            name: _nameController.text.trim(),
            email: email,
            password: _passwordController.text,
            phoneNumber: _phoneController.text.trim(),
          );

      if (!mounted) return;
      // Navigate to OTP verification with email passed
      unawaited(context.push(AppRoutes.verifyOtp, extra: email));
    } catch (e) {
      if (!mounted) return;
      final message = e is Failure ? e.message : 'Đăng ký thất bại, vui lòng thử lại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : const Color(0xFF0F766E);
    final textMain = isDark ? AppColors.darkTextMain : const Color(0xFF1E293B);
    final textMuted = isDark ? AppColors.darkTextMuted : const Color(0xFF64748B);
    final bg = isDark ? AppColors.darkPaper : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Fluid Decorative Wave at top-right
          const FluidTopWave(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 24),

                    // Headline & Subtitle
                    Text(
                      'Tạo tài khoản',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Điền thông tin bên dưới để bắt đầu.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

                    const SizedBox(height: 32),

                    // 1. Floating Name Card Input
                    FloatingInputCard(
                      controller: _nameController,
                      label: 'Họ và tên',
                      hintText: 'Nguyễn Văn A',
                      icon: HugeIcons.strokeRoundedUser,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      onSubmitted: (_) => _emailFocusNode.requestFocus(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                        if (val.trim().length < 2) return 'Họ tên quá ngắn';
                        return null;
                      },
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // 2. Floating Email Card Input
                    FloatingInputCard(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'user@example.com',
                      icon: HugeIcons.strokeRoundedMail01,
                      keyboardType: TextInputType.emailAddress,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                        if (!val.contains('@') || !val.contains('.')) return 'Email không hợp lệ';
                        return null;
                      },
                    ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // 3. Floating Password Card Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FloatingInputCard(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hintText: '••••••••',
                          icon: HugeIcons.strokeRoundedLockPassword,
                          isPassword: true,
                          focusNode: _passwordFocusNode,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                          onChanged: (val) {
                            setState(() {
                              _passwordInput = val;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                            if (val.length < 8) return 'Mật khẩu phải từ 8 ký tự';
                            return null;
                          },
                        ),
                        if (_passwordInput.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: PasswordChecklist(password: _passwordInput),
                          ),
                        ],
                      ],
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // 4. Floating Phone Card Input
                    FloatingInputCard(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hintText: '0901234567',
                      icon: HugeIcons.strokeRoundedCall,
                      keyboardType: TextInputType.phone,
                      focusNode: _phoneFocusNode,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      onSubmitted: (_) => _submit(),
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        final clean = val.trim();
                        final phoneRegex = RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$');
                        if (!phoneRegex.hasMatch(clean)) {
                          return 'Số điện thoại không đúng định dạng (VD: 0901234567)';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                    const SizedBox(height: 18),

                    // Terms agreement
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeTerms,
                            activeColor: primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                _agreeTerms = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Tôi đồng ý với ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Điều khoản dịch vụ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                                const TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Chính sách bảo mật',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                    const SizedBox(height: 28),

                    // Glowing Gradient Pill CTA Button
                    AppButton(
                      label: 'Đăng ký tài khoản',
                      variant: AppButtonVariant.gradient,
                      height: 54,
                      trailingIcon: const Icon(HugeIcons.strokeRoundedArrowRight01, color: Colors.white, size: 18),
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ).animate().fadeIn(delay: 550.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    // Bottom Link to Login
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: Text(
                              'Đăng nhập',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
