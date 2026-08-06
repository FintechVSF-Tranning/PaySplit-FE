import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';

/// Recent account activity.
///
/// Placeholder rows — there is no transaction endpoint yet. Replace
/// [_mockTransactions] with a provider when it lands; the row widget below
/// already takes everything it needs as parameters.
class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  static final List<({IconData icon, String title, DateTime date, double amount})>
  _mockTransactions = [
    (
      icon: Icons.restaurant,
      title: 'Chia hoá đơn — Lẩu Thái',
      date: DateTime(2026, 8, 5),
      amount: 285000,
    ),
    (
      icon: Icons.local_cafe,
      title: 'The Coffee House',
      date: DateTime(2026, 8, 4),
      amount: -72000,
    ),
    (
      icon: Icons.swap_horiz,
      title: 'Chuyển tiền — Nguyễn Minh',
      date: DateTime(2026, 8, 3),
      amount: -1500000,
    ),
    (
      icon: Icons.account_balance,
      title: 'Nhận lương tháng 7',
      date: DateTime(2026, 7, 31),
      amount: 18000000,
    ),
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
              Expanded(
                child: Text(
                  'Giao dịch gần đây',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => showComingSoonSnackBar(context, 'Lịch sử giao dịch'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < _mockTransactions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 68),
                  _TransactionRow(transaction: _mockTransactions[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final ({IconData icon, String title, DateTime date, double amount}) transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.amount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(transaction.icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(transaction.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(transaction.date)),
      trailing: Text(
        CurrencyFormatter.vndSigned(transaction.amount),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isCredit ? AppColors.success : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
