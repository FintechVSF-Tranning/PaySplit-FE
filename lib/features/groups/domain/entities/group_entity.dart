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
    required this.memberCount,
    required this.myBalance,
    this.inviteCode,
    required this.isCaptain,
    this.lastActivity,
    this.lastActivityAt,
    this.pendingBillCount = 0,
    this.status = GroupStatus.active,
    this.closedAtText,
  });

  final String id;
  final String name;
  final int memberCount;

  /// Số dư ròng của tôi trong nhóm: dương = được nhận, âm = cần trả.
  final int myBalance;

  /// Mã mời hiện hành. `null` khi chưa tải: `GET /groups` không trả mã mời,
  /// phải gọi riêng `GET /groups/{id}/invites` hoặc tạo mới bằng
  /// `POST /groups/{id}/invites`.
  final String? inviteCode;
  final bool isCaptain;

  /// Hoạt động gần nhất; `null` khi nhóm chưa có hoạt động nào.
  final String? lastActivity;
  final DateTime? lastActivityAt;
  final int pendingBillCount;
  final GroupStatus status;

  /// Ngày khóa bill hiển thị trên thẻ nhóm, chỉ có khi [isClosed].
  final String? closedAtText;

  bool get isClosed => status == GroupStatus.closed;

  /// Chữ viết tắt hiển thị trên avatar nhóm: hai chữ cái đầu của hai từ đầu
  /// tiên trong tên. Thay cho icon emoji đã bỏ.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PS';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  GroupBalanceState get balanceState => myBalance > 0
      ? GroupBalanceState.positive
      : myBalance < 0
      ? GroupBalanceState.negative
      : GroupBalanceState.settled;

  /// Link mời chia sẻ được ra ngoài ứng dụng (deep link universal).
  /// `null` khi [inviteCode] chưa được tải.
  String? get inviteLink => inviteCode == null ? null : 'https://paysplit.app/j/$inviteCode';

  @override
  List<Object?> get props => [id, name, memberCount, myBalance, inviteCode, status];
}
