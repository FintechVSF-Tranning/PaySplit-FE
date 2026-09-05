import 'package:equatable/equatable.dart';

class RealtimeInterestKey extends Equatable {
  const RealtimeInterestKey._(
    this.surface, {
    this.groupId,
    this.billId,
    this.extra,
  });

  factory RealtimeInterestKey.homeGroups() =>
      const RealtimeInterestKey._('home.groups');
  factory RealtimeInterestKey.homeActivities() =>
      const RealtimeInterestKey._('home.activities');
  factory RealtimeInterestKey.groupsIndex() =>
      const RealtimeInterestKey._('groups.index');
  factory RealtimeInterestKey.settlementOverview() =>
      const RealtimeInterestKey._('settlement.overview');
  factory RealtimeInterestKey.groupRoster(String groupId) =>
      RealtimeInterestKey._('group.roster', groupId: groupId);
  factory RealtimeInterestKey.groupDetail(String groupId) =>
      RealtimeInterestKey._('group.detail', groupId: groupId);
  factory RealtimeInterestKey.groupDebts(String groupId) =>
      RealtimeInterestKey._('group.debts', groupId: groupId);
  factory RealtimeInterestKey.groupActivities(String groupId) =>
      RealtimeInterestKey._('group.activities', groupId: groupId);
  factory RealtimeInterestKey.groupBills(String groupId, Object billsKey) =>
      RealtimeInterestKey._('group.bills', groupId: groupId, extra: billsKey);
  factory RealtimeInterestKey.billDetail(String groupId, String billId) =>
      RealtimeInterestKey._('bill.detail', groupId: groupId, billId: billId);
  factory RealtimeInterestKey.ocrWaiter(String groupId, String billId) =>
      RealtimeInterestKey._('ocr.waiter', groupId: groupId, billId: billId);

  final String surface;
  final String? groupId;
  final String? billId;
  final Object? extra;

  @override
  List<Object?> get props => [surface, groupId, billId, extra];
}

class RealtimeInterest {
  RealtimeInterest({
    required this.key,
    this.refresh,
    this.applyRoster,
    this.patchGroup,
    this.resourceVersion,
  });

  final RealtimeInterestKey key;

  /// Current persisted resource version, read when routing an invalidation.
  final int Function()? resourceVersion;

  /// Làm mới toàn bộ surface. Luôn được dùng sau `ready` và khi tràn bộ đếm.
  final Future<void> Function()? refresh;

  final void Function(Map<String, dynamic> frame)? applyRoster;

  /// Cập nhật tại chỗ đúng một nhóm, khi sự kiện chỉ đích danh nhóm đó.
  ///
  /// Dành cho những màn hình danh sách dài: người dùng đã cuộn xuống giữa danh
  /// sách thì việc tải lại cả trang đầu vừa không chạm tới dòng họ đang nhìn,
  /// vừa có nguy cơ xô lệch những gì bên dưới. Vá một dòng thì không.
  ///
  /// Bỏ trống nghĩa là surface này không vá lẻ được; owner sẽ gọi [refresh].
  final Future<void> Function(String groupId)? patchGroup;
}
