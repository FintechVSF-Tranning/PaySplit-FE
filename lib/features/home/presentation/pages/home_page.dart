import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/header_wave_painter.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../bills/presentation/widgets/group_picker_bottom_sheet.dart';
import '../../../notifications/presentation/providers/notifications_notifier.dart';
import '../../../settlement/presentation/providers/settlement_controller.dart';
import '../widgets/actionable_debts_section.dart';
import '../widgets/my_groups_carousel.dart';
import '../widgets/net_balance_hero_card.dart';
import '../widgets/recent_activity_timeline.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : (user?.email != null && user!.email.isNotEmpty ? user.email.split('@').first : 'Bạn');

    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: bg,
      // Background sóng Teal KHÔNG còn cố định: nó nằm bên trong nội dung
      // cuộn và di chuyển theo cùng nội dung khi người dùng scroll.
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // 1. Organic Curved Top Wave Header Background (cuộn cùng nội dung)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(double.infinity, 210 + statusBarHeight),
                painter: HeaderWavePainter(isDark: isDark),
              ),
            ),

            // 2. Scrollable Body
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12 + statusBarHeight, 16, 96),
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
                            onTap: () => context.go(AppRoutes.profile),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF14B8A6),
                                    Color(0xFF0D9488),
                                  ],
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
                              child: ClipOval(
                                child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                                    ? Image.network(
                                        user.avatarUrl!,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, _, _) => Center(
                                          child: Text(
                                            _getInitials(displayName),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
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
                    onPayVietQr: () => context.go(
                      AppRoutes.settlement,
                      extra: SettlementTab.payable,
                    ),
                    onScanBill: () async {
                      final selected = await GroupPickerBottomSheet.show(
                        context,
                        currentGroupId: 'g-1',
                      );
                      if (selected != null && context.mounted) {
                        await context.push(
                          AppRoutes.scanBill,
                          extra: {
                            'groupId': selected.id,
                            'groupName': selected.name,
                          },
                        );
                      }
                    },
                    onCreateGroup: () => context.go(AppRoutes.groups),
                  ),
                  const SizedBox(height: 22),

                  // 2. Actionable Debts Section
                  ActionableDebtsSection(
                    onViewAll: (tab) => context.go(
                      AppRoutes.settlement,
                      extra: tab == 0
                          ? SettlementTab.payable
                          : SettlementTab.receivable,
                    ),
                    onPayQr: (name, amount, ctx) => context.go(
                      AppRoutes.settlement,
                      extra: SettlementTab.payable,
                    ),
                    onReviewProof: (name, amount) => context.go(
                      AppRoutes.settlement,
                      extra: SettlementTab.receivable,
                    ),
                    onRemind: (name) => showComingSoonSnackBar(
                      context,
                      'Đã gửi nhắc nợ tới $name',
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3. My Groups Carousel
                  MyGroupsCarousel(
                    onViewAll: () => context.go(AppRoutes.groups),
                    onTapGroupItem: (group) {
                      if (group.id.isNotEmpty) {
                        context.push('${AppRoutes.groups}/${group.id}');
                      } else {
                        context.go(AppRoutes.groups);
                      }
                    },
                    onCreateGroup: () => context.go(AppRoutes.groups),
                  ),
                  const SizedBox(height: 22),

                  // 4. Recent Activity Timeline
                  const RecentActivityTimeline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PS';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
