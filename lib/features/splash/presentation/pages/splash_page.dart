import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textMain = isDark ? AppColors.darkTextMain : AppColors.textMain;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final bg = isDark ? AppColors.darkPaper : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Subtle Ambient Glow in the background
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.2, 1.2),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated App Icon Container
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.22),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                    )
                    .fadeIn(duration: 500.ms)
                    .then()
                    .shimmer(
                      duration: 1600.ms,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                const SizedBox(height: 24),

                // Brand Title (Artistic Editorial)
                Text(
                  'PaySplit',
                  style: AppTypography.artisticTitle(
                    fontSize: 36,
                    color: textMain,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms)
                    .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Chia tiền thông minh • Thanh toán VietQR',
                  style: AppTypography.bodySmall(
                    fontSize: 13,
                    color: textMuted,
                    letterSpacing: 0.2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 500.ms),
              ],
            ),
          ),

          // Bottom Loading Indicator
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(primary.withValues(alpha: 0.8)),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}
