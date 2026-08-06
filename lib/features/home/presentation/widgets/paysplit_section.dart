import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';

/// The PaySplit feature block — this is our surface inside the bank app, so
/// it gets a highlighted banner rather than blending into the generic
/// services grid above it.
class PaySplitSection extends StatelessWidget {
  const PaySplitSection({super.key});

  /// `route` is null for entries whose screen does not exist yet.
  static const List<({IconData icon, String label, String? route})> _entries = [
    (icon: Icons.receipt_long, label: 'Hoá đơn\ncủa tôi', route: AppRoutes.bills),
    (icon: Icons.groups_outlined, label: 'Nhóm\nchi tiêu', route: null),
    (icon: Icons.notifications_active_outlined, label: 'Nhắc\nthanh toán', route: null),
    (icon: Icons.history, label: 'Lịch sử\nchia', route: null),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PaySplit',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MỚI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chia hoá đơn thông minh, thanh toán tức thì',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _SplitBillBanner(onTap: () => context.push(AppRoutes.bills)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final entry in _entries)
                Expanded(
                  child: _PaySplitTile(
                    icon: entry.icon,
                    label: entry.label,
                    onTap: () {
                      final route = entry.route;
                      if (route != null) {
                        context.push(route);
                      } else {
                        showComingSoonSnackBar(context, entry.label.replaceAll('\n', ' '));
                      }
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitBillBanner extends StatelessWidget {
  const _SplitBillBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF3E9C85)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call_split, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chia hoá đơn',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tạo hoá đơn và đòi tiền bạn bè trong vài giây',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaySplitTile extends StatelessWidget {
  const _PaySplitTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
