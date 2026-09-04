import 'package:equatable/equatable.dart';

/// Chiều của khoản nợ so với người dùng hiện tại.
enum DebtDirection {
  /// Tôi phải trả cho đối phương.
  iOwe,

  /// Đối phương phải trả cho tôi.
  owesMe,
}

/// Khoản nợ đã gom (netting) giữa tôi và một thành viên trong nhóm.
class GroupDebtEntity extends Equatable {
  const GroupDebtEntity({
    required this.id,
    required this.counterpartName,
    required this.direction,
    required this.amount,
    required this.note,
    this.hasPendingProof = false,
    this.transferRef = '',
  });

  final String id;
  final String counterpartName;
  final DebtDirection direction;

  /// Luôn là số dương; chiều nợ do [direction] quyết định.
  final int amount;

  /// Dòng mô tả phụ, ví dụ "Bạn cần trả cho Lâm".
  final String note;

  /// Đối phương đã nộp minh chứng, đang chờ tôi duyệt.
  final bool hasPendingProof;

  /// Nội dung chuyển khoản gợi ý cho VietQR.
  final String transferRef;

  String get initials {
    final parts = counterpartName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  List<Object?> get props => [id, counterpartName, direction, amount, hasPendingProof];
}

/// Một dòng trong ma trận công nợ "ai trả ai".
class DebtMatrixRow extends Equatable {
  const DebtMatrixRow({required this.from, required this.to, required this.amount});

  final String from;
  final String to;
  final int amount;

  @override
  List<Object?> get props => [from, to, amount];
}
