import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';

/// Balance summary that sits on the home header.
///
/// The amount and account number are placeholders — there is no account
/// feature/endpoint yet. Swap [_mockBalance] and [_mockAccountNumber] for a
/// provider once the account API exists; nothing else here has to change.
class AccountBalanceCard extends StatefulWidget {
  const AccountBalanceCard({super.key});

  @override
  State<AccountBalanceCard> createState() => _AccountBalanceCardState();
}

class _AccountBalanceCardState extends State<AccountBalanceCard> {
  static const double _mockBalance = 12450000;
  static const String _mockAccountNumber = '1903 2847 5566';

  /// Balances start hidden so the number is not exposed to shoulder-surfers
  /// the moment the app opens.
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tài khoản thanh toán',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                _mockAccountNumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _hidden ? '••••••••' : CurrencyFormatter.vnd(_mockBalance),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: _hidden ? 'Hiện số dư' : 'Ẩn số dư',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
