import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import 'account_balance_card.dart';

/// Gradient banner carrying the greeting, the account actions and the
/// balance card. The card lives inside the gradient (rather than overlapping
/// it via a [Stack]) so the header height stays driven by its content.
class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.userName, required this.onLogout, super.key});

  final String userName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1F5A4C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _initials(userName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showComingSoonSnackBar(context, 'Thông báo'),
                    icon: const Icon(HugeIcons.strokeRoundedNotification01, size: 20),
                    color: Colors.white,
                    tooltip: 'Thông báo',
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(HugeIcons.strokeRoundedLogout01, size: 20),
                    color: Colors.white,
                    tooltip: 'Đăng xuất',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const AccountBalanceCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// First letter of the first and last name parts, e.g. "Phạm Tùng Lâm" → "PL".
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
