import '../../domain/entities/bill_entity.dart';
import '../../domain/entities/bill_list_page.dart';
import 'bill_model.dart';

/// DTO cho khối `data` của `GET /api/v1/bills`.
class BillListPageModel {
  const BillListPageModel({
    required this.bills,
    this.counts = const {},
    this.totalCount = 0,
    this.nextCursor,
  });

  final List<BillModel> bills;
  final Map<String, int> counts;
  final int totalCount;
  final String? nextCursor;

  factory BillListPageModel.fromJson(Map<String, dynamic> json) {
    final rawBills = json['bills'];
    final rawCounts = json['counts'];

    final counts = <String, int>{};
    var total = 0;
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final value = entry.value;
        if (value is! num) continue;
        if (entry.key == 'total') {
          total = value.toInt();
        } else {
          counts['${entry.key}'] = value.toInt();
        }
      }
    }

    return BillListPageModel(
      bills: rawBills is List
          ? rawBills
                .whereType<Map<String, dynamic>>()
                .map(BillModel.fromJson)
                .toList()
          : const [],
      counts: counts,
      totalCount: total,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  BillListPage toEntity() {
    return BillListPage(
      bills: bills.map((b) => b.toEntity()).toList(),
      counts: {
        for (final status in BillStatus.values)
          if (counts.containsKey(status.name)) status: counts[status.name]!,
      },
      // BE cũ chưa trả `counts` thì tổng lấy tạm theo số bản ghi đã tải.
      totalCount: totalCount > 0 ? totalCount : bills.length,
      nextCursor: nextCursor,
    );
  }
}
