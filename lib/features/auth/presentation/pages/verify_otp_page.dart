import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/fluid_top_wave.dart';
import '../providers/auth_controller.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  int _countdown = 60;
  Timer? _timer;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0 || _isResending) return;
    setState(() {
      _isResending = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).resendVerification(email: widget.email);
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi lại mã OTP tới email của bạn.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure ? e.message : 'Không thể gửi lại mã, vui lòng thử lại sau';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyOtp([String? pin]) async {
    final otp = pin ?? _pinController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số OTP'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).verifyEmail(
            email: widget.email,
            otp: otp,
          );

      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực email thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      await HapticFeedback.vibrate();
      if (!mounted) return;
      final msg = e is Failure ? e.message : 'Mã OTP không chính xác hoặc đã hết hạn';
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
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final bg = isDark ? AppColors.darkPaper : Colors.white;

    // Pin theme
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textMain,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: primary, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF8FAFC),
        border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.2),
      ),
    );

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Fluid Decorative Wave at top-right
          const FluidTopWave(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Back button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 28),

                  // Mail Icon Box
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
                      Icons.mark_email_read_outlined,
                      size: 28,
                      color: primary,
                    ),
                  ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

                  const SizedBox(height: 20),

                  // Headline & Subtitle
                  Text(
                    'Xác thực Email',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Chúng tôi đã gửi mã xác thực 6 chữ số đến hộp thư của bạn:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

                  const SizedBox(height: 12),

                  // Email Pill Display
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
                        Icon(Icons.alternate_email_rounded, size: 16, color: primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.email.isNotEmpty ? widget.email : 'Địa chỉ email của bạn',
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

                  const SizedBox(height: 36),

                  // 6-Box PIN Inputs
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: _pinController,
                      focusNode: _focusNode,
                      autofocus: true,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      onCompleted: (pin) => _verifyOtp(pin),
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // Resend Countdown Row
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_countdown > 0)
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 16, color: textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Gửi lại mã sau (${_countdown}s)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: _isResending ? null : _resendOtp,
                            child: Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 16, color: primary),
                                const SizedBox(width: 6),
                                Text(
                                  _isResending ? 'Đang gửi mã...' : 'Gửi lại mã OTP',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Mã OTP có hiệu lực trong 10 phút. Tối đa 5 lần thử.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 36),

                  // Submit Button
                  AppButton(
                    label: 'Xác nhận & Kích hoạt',
                    variant: AppButtonVariant.gradient,
                    height: 54,
                    trailingIcon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : () => _verifyOtp(),
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 28),

                  // Bottom Link to Login
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã xác thực xong? ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
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
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
