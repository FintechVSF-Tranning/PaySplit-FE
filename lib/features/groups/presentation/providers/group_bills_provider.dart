import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/session/session_scope.dart';
import '../../../../core/error/failures.dart';
import '../../../../di/injection.dart';
import '../../../bills/domain/usecases/get_bills_usecase.dart';
import '../../data/models/group_bill_mapper.dart';
import '../../domain/entities/group_bill_entity.dart';

/// Khóa của [groupBillsProvider]: một nhóm + một bộ lọc trạng thái. Backend lọc
/// theo `?status=`, nên mỗi chip là một danh sách riêng có cursor riêng.
class GroupBillsKey extends Equatable {
  const GroupBillsKey({required this.groupId, this.filter = GroupBillFilter.all});

  final String groupId;
  final GroupBillFilter filter;

  @override
  List<Object?> get props => [groupId, filter];
}

class GroupBillsState extends Equatable {
  const GroupBillsState({
    this.bills = const [],
    this.counts = const {},
    this.totalCount = 0,
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<GroupBillEntity> bills;

  /// Đếm theo trạng thái của cả nhóm — badge chip không phụ thuộc trang đã tải.
  final Map<GroupBillStatus, int> counts;
  final int totalCount;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  int countFor(GroupBillFilter filter) {
    final status = filter.status;
    return status == null ? totalCount : (counts[status] ?? 0);
  }

  GroupBillsState copyWith({
    List<GroupBillEntity>? bills,
    Map<GroupBillStatus, int>? counts,
    int? totalCount,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroupBillsState(
      bills: bills ?? this.bills,
      counts: counts ?? this.counts,
      totalCount: totalCount ?? this.totalCount,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    bills,
    counts,
    totalCount,
    nextCursor,
    isLoading,
    isLoadingMore,
    errorMessage,
  ];
}

/// Danh sách hóa đơn của một nhóm cho tab "Hóa đơn" của màn chi tiết nhóm,
/// phân trang theo cursor của backend.
class GroupBillsNotifier extends StateNotifier<GroupBillsState> {
  GroupBillsNotifier(this._key) : super(const GroupBillsState(isLoading: true)) {
    load();
  }

  final GroupBillsKey _key;

  static const int _pageSize = 20;

  Future<void> load() async {
    if (_key.groupId.isEmpty) {
      state = const GroupBillsState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetch(cursor: null, append: false);
  }

  /// Tải trang kế tiếp. Bỏ qua khi đã hết dữ liệu hoặc đang tải dở.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetch(cursor: state.nextCursor, append: true);
  }

  Future<void> _fetch({required String? cursor, required bool append}) async {
    final result = await getIt<GetBillsUseCase>().call(
      GetBillsParams(
        groupId: _key.groupId,
        limit: _pageSize,
        cursor: cursor,
        statuses: _key.filter.apiStatuses,
      ),
    );
    if (!mounted) return;

    result.match(
      (Failure failure) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (page) {
        final mapped = page.toGroupBillsPage();
        // Trang sau có thể trùng phần tử nếu có hóa đơn mới chen vào giữa hai
        // lần gọi; lọc theo id để danh sách không hiện đôi.
        final seen = append ? {for (final b in state.bills) b.id} : <String>{};
        final merged = append
            ? [...state.bills, ...mapped.bills.where((b) => !seen.contains(b.id))]
            : mapped.bills;

        state = GroupBillsState(
          bills: merged,
          counts: mapped.counts,
          totalCount: mapped.totalCount,
          nextCursor: mapped.nextCursor,
        );
      },
    );
  }
}

/// `autoDispose` có chủ đích: mỗi chip lọc là một provider riêng, giữ cả 5 sống
/// mãi vừa tốn bộ nhớ vừa khiến chip mở lại hiện dữ liệu cũ. Khi màn hình còn
/// mở thì provider vẫn được `watch` nên trang đã tải thêm không bị mất.
final groupBillsProvider =
    StateNotifierProvider.autoDispose
        .family<GroupBillsNotifier, GroupBillsState, GroupBillsKey>((ref, key) {
          ref.watch(sessionRevisionProvider);
          return GroupBillsNotifier(key);
        });
