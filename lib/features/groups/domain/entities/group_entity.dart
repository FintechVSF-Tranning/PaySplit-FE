import 'package:equatable/equatable.dart';

/// Trạng thái công nợ của người dùng hiện tại bên trong một nhóm.
enum GroupBalanceState { positive, negative, settled }

/// Vòng đời của nhóm chi tiêu.
enum GroupStatus {
  /// Đang dùng: còn thêm hóa đơn, còn chia tiền.
  active,

  /// Đã khóa bill: mọi hóa đơn đã chia xong, bảng chia tiền bị khóa. Công nợ
  /// vẫn tiếp tục được thanh toán sau khi khóa.
  closed,
}

/// Nhóm chi tiêu — entity thuần, không phụ thuộc Dio/JSON.
class GroupEntity extends Equatable {
  const GroupEntity({
    required this.id,
    required this.name,
    required this.emoji,
    required this.memberCount,
    required this.myBalance,
    required this.inviteCode,
    required this.isCaptain,
    required this.lastActivity,
    required this.lastActivityAt,
    this.pendingBillCount = 0,
    this.status = GroupStatus.active,
    this.closedAtText,
  });

  final String id;
  final String name;
  final String emoji;
  final int memberCount;

  /// Số dư ròng của tôi trong nhóm: dương = được nhận, âm = cần trả.
  final int myBalance;
  final String inviteCode;
  final bool isCaptain;
  final String lastActivity;
  final DateTime lastActivityAt;
  final int pendingBillCount;
  final GroupStatus status;

  /// Ngày khóa bill hiển thị trên thẻ nhóm, chỉ có khi [isClosed].
  final String? closedAtText;

  bool get isClosed => status == GroupStatus.closed;

  GroupBalanceState get balanceState => myBalance > 0
      ? GroupBalanceState.positive
      : myBalance < 0
      ? GroupBalanceState.negative
      : GroupBalanceState.settled;

  /// Link mời chia sẻ được ra ngoài ứng dụng (deep link universal).
  String get inviteLink => 'https://paysplit.app/j/$inviteCode';

  @override
  List<Object?> get props => [id, name, emoji, memberCount, myBalance, inviteCode, status];
}
