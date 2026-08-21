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

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _passwordInput = '';

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            email: widget.email,
            otp: _otpController.text.trim(),
            newPassword: _passwordController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.login, extra: true); // resetSuccess = true
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure ? e.message : 'Mã OTP không đúng hoặc đã hết hạn';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
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
                      icon: const Icon(HugeIcons.strokeRoundedArrowLeft01, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 28),

                    // Icon Container
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        HugeIcons.strokeRoundedLockPassword,
                        size: 28,
                        color: primary,
                      ),
                    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

                    const SizedBox(height: 20),

                    // Headline & Subtitle
                    Text(
                      'Đặt lại mật khẩu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

                    const SizedBox(height: 8),

                    Text(
                      'Nhập mã OTP 6 số và thiết lập mật khẩu mới cho tài khoản của bạn.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textMuted,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

                    const SizedBox(height: 14),

                    // Target Email Badge
                    if (widget.email.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(HugeIcons.strokeRoundedUser, size: 16, color: primary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.email,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

                    const SizedBox(height: 24),

                    // 1. OTP Input Card
                    FloatingInputCard(
                      controller: _otpController,
                      label: 'Mã OTP 6 số',
                      hintText: '123456',
                      icon: HugeIcons.strokeRoundedDialpadCircle01,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) {
                        if (val == null || val.trim().length != 6) {
                          return 'Vui lòng nhập đủ 6 chữ số OTP';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // 2. New Password Input Card
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FloatingInputCard(
                          controller: _passwordController,
                          label: 'Mật khẩu mới',
                          hintText: '••••••••',
                          icon: HugeIcons.strokeRoundedLockPassword,
                          isPassword: true,
                          onChanged: (val) {
                            setState(() {
                              _passwordInput = val;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Vui lòng nhập mật khẩu mới';
                            }
                            if (val.length < 8) {
                              return 'Mật khẩu phải từ 8 ký tự';
                            }
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

                    // 3. Confirm Password Input Card
                    FloatingInputCard(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu mới',
                      hintText: '••••••••',
                      icon: HugeIcons.strokeRoundedLockPassword,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu mới';
                        }
                        if (val != _passwordController.text) {
                          return 'Mật khẩu xác nhận không khớp';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                    const SizedBox(height: 32),

                    // Submit Button
                    AppButton(
                      label: 'Lưu mật khẩu mới & Đăng nhập',
                      variant: AppButtonVariant.gradient,
                      height: 54,
                      trailingIcon: const Icon(HugeIcons.strokeRoundedArrowRight01, color: Colors.white, size: 18),
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ).animate().fadeIn(delay: 550.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    // Bottom Link to Login
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Quay lại ',
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
