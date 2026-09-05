import 'dart:async';

import 'package:flutter/material.dart';
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
import '../providers/auth_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi mã khôi phục OTP tới email của bạn.'),
          backgroundColor: AppColors.success,
        ),
      );
      unawaited(context.push(AppRoutes.resetPassword, extra: email));
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure ? e.message : 'Không thể gửi yêu cầu, vui lòng thử lại';
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
                      'Quên mật khẩu?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

                    const SizedBox(height: 8),

                    Text(
                      'Nhập địa chỉ email tài khoản của bạn. PaySplit sẽ gửi mã OTP 6 số để bạn thiết lập lại mật khẩu.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textMuted,
                        height: 1.45,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

                    const SizedBox(height: 32),

                    // Email Card Input
                    FloatingInputCard(
                      controller: _emailController,
                      label: 'Email tài khoản',
                      hintText: 'user@example.com',
                      icon: HugeIcons.strokeRoundedMail01,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _submit(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                    const SizedBox(height: 32),

                    // Submit Button
                    AppButton(
                      label: 'Gửi mã khôi phục',
                      variant: AppButtonVariant.gradient,
                      height: 54,
                      trailingIcon: const Icon(HugeIcons.strokeRoundedArrowRight01, color: Colors.white, size: 18),
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 36),

                    // Bottom Link to Back to Login
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nhớ mật khẩu rồi? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Đăng nhập ngay',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms),
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
