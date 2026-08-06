import 'package:flutter/material.dart';

import '../../../../core/utils/ui_feedback.dart';

/// The four core banking verbs, kept above the fold. These are the bank's
/// own flows — none of them are built yet, so each one reports itself as
/// pending rather than pretending to navigate.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const List<({IconData icon, String label})> _actions = [
    (icon: Icons.swap_horiz, label: 'Chuyển tiền'),
    (icon: Icons.add_card, label: 'Nạp tiền'),
    (icon: Icons.receipt_long, label: 'Thanh toán'),
    (icon: Icons.qr_code_scanner, label: 'Quét QR'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final action in _actions)
            Expanded(
              child: _QuickActionButton(
                icon: action.icon,
                label: action.label,
                onTap: () => showComingSoonSnackBar(context, action.label),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
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
