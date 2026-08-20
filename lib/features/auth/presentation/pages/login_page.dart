import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/floating_input_card.dart';
import '../../../../core/widgets/fluid_top_wave.dart';
import '../providers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.resetSuccess = false});

  final bool resetSuccess;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isUnverified = false;
  int _rateLimitSeconds = 0;
  Timer? _rateLimitTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  void _startRateLimitTimer(int seconds) {
    setState(() {
      _rateLimitSeconds = seconds;
    });
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_rateLimitSeconds <= 1) {
        timer.cancel();
        setState(() {
          _rateLimitSeconds = 0;
        });
      } else {
        setState(() {
          _rateLimitSeconds--;
        });
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isUnverified = false;
    });
    ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : const Color(0xFF0F766E);
    final textMain = isDark ? AppColors.darkTextMain : const Color(0xFF1E293B);
    final textMuted = isDark ? AppColors.darkTextMuted : const Color(0xFF64748B);
    final bg = isDark ? AppColors.darkPaper : Colors.white;

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (!next.hasError) return;
      final error = next.error;
      if (error is Failure) {
        if (error.code == 'EMAIL_NOT_VERIFIED') {
          setState(() {
            _isUnverified = true;
          });
          return;
        }
        if (error.code == 'RATE_LIMITED') {
          _startRateLimitTimer(900); // 15 mins
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: AppColors.danger,
            ),
          );
      }
    });

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
                    const SizedBox(height: 24),

                    // Logo & Brand Header in Center
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/icons/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'PaySplit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textMain,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 44),

                    // Headline & Subtitle
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Đăng nhập',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Xin chào! Vui lòng đăng nhập để tiếp tục.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                    const SizedBox(height: 36),

                    // Success Alert after Password Reset
                    if (widget.resetSuccess) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.successSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.successBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 20, color: AppColors.success),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Đặt lại mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.',
                                style: AppTypography.bodySmall(color: AppColors.successText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Unverified Email Alert
                    if (_isUnverified) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.warningSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tài khoản chưa kích hoạt!',
                                    style: AppTypography.heading(fontSize: 13, color: AppColors.warningText),
                                  ),
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: () => context.push(
                                      AppRoutes.verifyOtp,
                                      extra: _emailController.text.trim(),
                                    ),
                                    child: Text(
                                      'Bấm vào đây để nhập mã OTP kích hoạt.',
                                      style: AppTypography.bodySmall(color: primary).copyWith(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Rate Limit 429 Alert
                    if (_rateLimitSeconds > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.dangerBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock_outlined, size: 20, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tài khoản tạm khóa do sai quá nhiều lần. Thử lại sau: ${_rateLimitSeconds ~/ 60}:${(_rateLimitSeconds % 60).toString().padLeft(2, '0')}s',
                                style: AppTypography.bodySmall(color: AppColors.dangerText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Floating Email Card Input
                    FloatingInputCard(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'user@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                        if (!val.contains('@') || !val.contains('.')) return 'Email không hợp lệ';
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // Floating Password Card Input
                    FloatingInputCard(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hintText: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 12),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.forgotPassword),
                        child: Text(
                          'Quên mật khẩu?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Glowing Gradient Pill CTA Button
                    AppButton(
                      label: 'Đăng nhập',
                      variant: AppButtonVariant.gradient,
                      height: 54,
                      trailingIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      isLoading: isLoading,
                      onPressed: _rateLimitSeconds > 0 ? null : _submit,
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 40),

                    // Bottom Link to Register
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.register),
                            child: Text(
                              'Đăng ký ngay',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms),
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
