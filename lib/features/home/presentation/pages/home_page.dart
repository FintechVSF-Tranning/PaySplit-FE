import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../widgets/home_header.dart';
import '../widgets/paysplit_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions.dart';

/// Bank dashboard. Reads top-to-bottom as balance → the bank's own actions →
/// PaySplit (our feature) → recent activity, which is the layout users
/// already expect from a banking app.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          HomeHeader(
            userName: user?.name ?? 'bạn',
            onLogout: () => ref.read(authControllerProvider.notifier).logout(),
          ),
          const SizedBox(height: 20),
          const QuickActions(),
          const SizedBox(height: 28),
          const PaySplitSection(),
          const SizedBox(height: 28),
          const RecentTransactions(),
        ],
      ),
    );
  }
}
