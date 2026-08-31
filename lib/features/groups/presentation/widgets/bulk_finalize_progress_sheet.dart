import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/bulk_finalize_entity.dart';
import '../providers/group_bill_close_provider.dart';

class BulkFinalizeProgressSheet extends ConsumerStatefulWidget {
  const BulkFinalizeProgressSheet({
    required this.groupId,
    required this.batchId,
    required this.onOpenBill,
    super.key,
  });

  final String groupId;
  final String batchId;
  final ValueChanged<String> onOpenBill;

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    required String batchId,
    required ValueChanged<String> onOpenBill,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BulkFinalizeProgressSheet(
      groupId: groupId,
      batchId: batchId,
      onOpenBill: onOpenBill,
    ),
  );

  @override
  ConsumerState<BulkFinalizeProgressSheet> createState() =>
      _BulkFinalizeProgressSheetState();
}

class _BulkFinalizeProgressSheetState
    extends ConsumerState<BulkFinalizeProgressSheet> {
  int _lastAnnouncedCount = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(groupBillCloseProvider(widget.groupId).notifier)
          .open(widget.batchId),
    );
  }

  void _maybeAnnounceProgress(BulkFinalizeBatchEntity batch) {
    if (batch.processedCount != _lastAnnouncedCount) {
      _lastAnnouncedCount = batch.processedCount;
      final message = batch.isComplete
          ? 'Đã hoàn tất chốt toàn bộ: ${batch.finalizedCount} thành công, ${batch.failedCount} lỗi trên tổng số ${batch.targetCount} hóa đơn.'
          : 'Tiến trình: đã xử lý ${batch.processedCount}/${batch.targetCount} hóa đơn.';
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        TextDirection.ltr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupBillCloseProvider(widget.groupId));
    final batch = state.batch;

    if (batch != null) {
      _maybeAnnounceProgress(batch);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final handleColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => Material(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tiến trình chốt toàn bộ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textMain,
              ),
            ),
            const SizedBox(height: 8),
            if (state.isLoading && batch == null)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.errorMessage != null && batch == null) ...[
              Text(
                state.errorMessage!,
                style: TextStyle(color: isDark ? const Color(0xFFF87171) : AppColors.danger),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref
                    .read(groupBillCloseProvider(widget.groupId).notifier)
                    .open(widget.batchId),
                child: const Text('Thử lại'),
              ),
            ] else if (batch != null) ...[
              _Summary(batch: batch),
              const SizedBox(height: 18),
              if (batch.items.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        batch.targetCount == 0
                            ? Icons.check_circle_outline
                            : Icons.hourglass_top,
                        size: 40,
                        color: batch.targetCount == 0
                            ? (isDark ? const Color(0xFF34D399) : AppColors.success)
                            : (isDark ? const Color(0xFFFBBF24) : AppColors.warningText),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        batch.targetCount == 0
                            ? 'Không có bill mở cần chốt.'
                            : 'Đang chuẩn bị danh sách bill...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final item in batch.items)
                  _BillItemRow(
                    item: item,
                    onOpenBill: () {
                      Navigator.of(context).pop();
                      widget.onOpenBill(item.billId);
                    },
                  ),
              if (batch.nextCursor != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: state.isLoadingMore
                      ? null
                      : () => ref
                            .read(
                              groupBillCloseProvider(widget.groupId).notifier,
                            )
                            .loadMore(),
                  child: Text(state.isLoadingMore ? 'Đang tải...' : 'Xem thêm'),
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: isDark ? const Color(0xFFF87171) : AppColors.danger),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BillItemRow extends StatelessWidget {
  const _BillItemRow({required this.item, required this.onOpenBill});

  final BulkFinalizeItemEntity item;
  final VoidCallback onOpenBill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dangerColor = isDark ? const Color(0xFFF87171) : AppColors.danger;
    final successColor = isDark ? const Color(0xFF34D399) : AppColors.success;
    final warningColor = isDark ? const Color(0xFFFBBF24) : AppColors.warningText;

    final statusLabel = switch (item.status) {
      BulkFinalizeItemStatus.finalized => 'Đã chốt thành công',
      BulkFinalizeItemStatus.failed => 'Thất bại: ${item.resultText}',
      BulkFinalizeItemStatus.pending => 'Đang chờ xử lý',
    };

    final icon = switch (item.status) {
      BulkFinalizeItemStatus.finalized => Icon(
        Icons.check_circle,
        color: successColor,
      ),
      BulkFinalizeItemStatus.failed => Icon(
        Icons.error_outline,
        color: dangerColor,
      ),
      BulkFinalizeItemStatus.pending => Icon(
        Icons.schedule,
        color: warningColor,
      ),
    };

    return Semantics(
      label: '${item.billName}: $statusLabel',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Semantics(label: statusLabel, child: icon),
        title: Text(
          item.billName,
          style: TextStyle(fontWeight: FontWeight.w600, color: textMain),
        ),
        subtitle: Text(
          item.resultText,
          style: TextStyle(
            color: item.status == BulkFinalizeItemStatus.failed
                ? dangerColor
                : textMuted,
            fontSize: 12.5,
          ),
        ),
        trailing: item.canOpenBill
            ? TextButton(
                onPressed: onOpenBill,
                style: TextButton.styleFrom(minimumSize: const Size(44, 40)),
                child: Text(item.actionLabel),
              )
            : null,
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.batch});
  final BulkFinalizeBatchEntity batch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceMuted = isDark ? const Color(0xFF0F172A) : AppColors.surfaceMuted;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final progress = batch.targetCount == 0
        ? 1.0
        : batch.processedCount / batch.targetCount;
    final summaryText =
        '${batch.finalizedCount} đã chốt · ${batch.failedCount} cần xử lý · ${batch.targetCount} tổng cộng';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            batch.isComplete ? 'Đã hoàn tất' : 'Đang xử lý',
            style: TextStyle(fontWeight: FontWeight.w700, color: textMain),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Tiến độ ${batch.processedCount} trên ${batch.targetCount}',
            value: '${(progress * 100).toInt()}%',
            child: LinearProgressIndicator(value: progress.clamp(0, 1)),
          ),
          const SizedBox(height: 10),
          Text(summaryText, style: TextStyle(color: textMuted)),
        ],
      ),
    );
  }
}
