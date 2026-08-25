import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../bills/presentation/widgets/group_picker_bottom_sheet.dart';
import '../../../notifications/presentation/providers/notifications_notifier.dart';
import '../widgets/actionable_debts_section.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/my_groups_carousel.dart';
import '../widgets/net_balance_hero_card.dart';
import '../widgets/recent_activity_timeline.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Hoàng Nam';

    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 1. Organic Curved Top Wave Header Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 210),
              painter: _HomeHeaderWavePainter(isDark: isDark),
            ),
          ),

          // 2. Scrollable Body
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Avatar & Greeting
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.push(AppRoutes.profile),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(displayName),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào,',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Notification Bell Button
                      InkWell(
                        onTap: () => context.push(AppRoutes.notifications),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                HugeIcons.strokeRoundedNotification01,
                                color: Colors.white,
                                size: 20,
                              ),
                              if (unreadNotifs > 0) ...[
                                Positioned(
                                  top: 9,
                                  right: 9,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0F766E),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 1. Hero Net Balance Card
                  NetBalanceHeroCard(
                    onPayVietQr: () => showComingSoonSnackBar(context, 'Thanh toán VietQR'),
                    onScanBill: () async {
                      final selected = await GroupPickerBottomSheet.show(
                        context,
                        currentGroupId: 'g-1',
                      );
                      if (selected != null && context.mounted) {
                        await context.push(AppRoutes.scanBill, extra: {
                          'groupId': selected.id,
                          'groupName': selected.name,
                        });
                      }
                    },
                    onCreateGroup: () => context.push(AppRoutes.groups),
                  ),
                  const SizedBox(height: 22),

                  // 2. Actionable Debts Section
                  ActionableDebtsSection(
                    onViewAll: () => showComingSoonSnackBar(context, 'Tất cả công nợ'),
                    onPayQr: (name, amount, ctx) =>
                        showComingSoonSnackBar(context, 'Trả QR cho $name ($amount)'),
                    onReviewProof: (name, amount) =>
                        showComingSoonSnackBar(context, 'Duyệt biên lai của $name ($amount)'),
                    onRemind: (name) =>
                        showComingSoonSnackBar(context, 'Đã gửi nhắc nợ tới $name'),
                  ),
                  const SizedBox(height: 22),

                  // 3. My Groups Carousel
                  MyGroupsCarousel(
                    onViewAll: () => context.push(AppRoutes.groups),
                    onTapGroupItem: (group) {
                      if (group.id.isNotEmpty) {
                        context.push('${AppRoutes.groups}/${group.id}');
                      } else {
                        context.push(AppRoutes.groups);
                      }
                    },
                    onCreateGroup: () => context.push(AppRoutes.groups),
                  ),
                  const SizedBox(height: 22),

                  // 4. Recent Activity Timeline
                  const RecentActivityTimeline(),
                ],
              ),
            ),
          ),

          // 3. Fixed Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                if (index == 0) {
                  setState(() => _currentNavIndex = 0);
                } else if (index == 1) {
                  context.push(AppRoutes.groups);
                } else if (index == 2) {
                  context.push(AppRoutes.bills);
                } else if (index == 3) {
                  context.push(AppRoutes.profile);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'HN';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class _HomeHeaderWavePainter extends CustomPainter {
  final bool isDark;
  _HomeHeaderWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF0F766E), const Color(0xFF132A24)]
            : [const Color(0xFF0F766E), const Color(0xFF115E59), const Color(0xFF134E4A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final path = Path();
    path.lineTo(0, size.height - 35);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 15,
      size.width,
      size.height - 35,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
