import 'package:equatable/equatable.dart';

import 'bill_entity.dart';

/// Một trang kết quả của `GET /api/v1/bills`: danh sách hóa đơn (đã lọc theo
/// `status` nếu có), số lượng theo từng trạng thái của **toàn nhóm** và cursor
/// trang kế tiếp.
class BillListPage extends Equatable {
  const BillListPage({
    this.bills = const [],
    this.counts = const {},
    this.totalCount = 0,
    this.nextCursor,
  });

  final List<BillEntity> bills;

  /// Đếm theo trạng thái, không bị bộ lọc của request cắt bớt — dùng cho badge
  /// các chip lọc.
  final Map<BillStatus, int> counts;
  final int totalCount;
  final String? nextCursor;

  int countFor(BillStatus status) => counts[status] ?? 0;

  @override
  List<Object?> get props => [bills, counts, totalCount, nextCursor];
}
