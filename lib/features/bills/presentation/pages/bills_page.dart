import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_entity.dart';
import '../providers/bills_provider.dart';

class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hoá đơn')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(billsProvider.future),
        child: billsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Không tải được hoá đơn: $error')),
            ],
          ),
          data: (bills) {
            if (bills.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Chưa có hoá đơn nào')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bills.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bill = bills[index];
                return Card(
                  child: ListTile(
                    title: Text(bill.title),
                    subtitle: Text(CurrencyFormatter.vnd(bill.totalAmount)),
                    trailing: Chip(
                      label: Text(bill.status == BillStatus.settled ? 'Đã tất toán' : 'Chờ xử lý'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
