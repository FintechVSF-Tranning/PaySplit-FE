import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_entity.dart';
import '../providers/bills_provider.dart';
import '../widgets/group_picker_bottom_sheet.dart';

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
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              Center(
                child: Text(
                  error is Failure ? error.message : 'Không tải được hoá đơn, vui lòng thử lại',
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(billsProvider),
                  child: const Text('Thử lại'),
                ),
              ),
            ],
          ),
          data: (bills) {
            if (bills.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Chưa có hoá đơn nào')),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Chụp bill mới'),
      ),
    );
  }
}
