import 'package:equatable/equatable.dart';

/// Trạng thái vòng đời của một hóa đơn trong nhóm.
enum GroupBillStatus {
  /// Đang chạy OCR bóc tách ảnh hóa đơn.
  ocrScanning,

  /// OCR xong, chờ gán món cho từng người.
  awaitingAllocation,

  /// Đã chốt chia tiền, chỉ còn theo dõi tiến độ thanh toán.
  settled,

  /// Hóa đơn đã bị hủy.
  voided,
}

extension GroupBillStatusX on GroupBillStatus {
  String get label => switch (this) {
    GroupBillStatus.ocrScanning => 'Đang quét OCR',
    GroupBillStatus.awaitingAllocation => 'Chờ phân bổ món',
    GroupBillStatus.settled => 'Đã chốt',
    GroupBillStatus.voided => 'Đã hủy',
  };

  /// Hóa đơn chưa chốt xong được gom vào bộ lọc "Đang xử lý".
  bool get isActive =>
      this == GroupBillStatus.ocrScanning || this == GroupBillStatus.awaitingAllocation;
}

/// Bộ lọc hóa đơn trên tab Hóa đơn của màn chi tiết nhóm.
enum GroupBillFilter { all, active, settled, voided }

extension GroupBillFilterX on GroupBillFilter {
  String get label => switch (this) {
    GroupBillFilter.all => 'Tất cả',
    GroupBillFilter.active => 'Đang xử lý',
    GroupBillFilter.settled => 'Đã chốt',
    GroupBillFilter.voided => 'Đã hủy',
  };

  bool matches(GroupBillStatus status) => switch (this) {
    GroupBillFilter.all => true,
    GroupBillFilter.active => status.isActive,
    GroupBillFilter.settled => status == GroupBillStatus.settled,
    GroupBillFilter.voided => status == GroupBillStatus.voided,
  };
}

/// Hóa đơn hiển thị trong feed của một nhóm.
class GroupBillEntity extends Equatable {
  const GroupBillEntity({
    required this.id,
    required this.title,
    required this.dateText,
    required this.payerName,
    required this.status,
    required this.totalAmount,
    required this.paidMemberCount,
    required this.memberCount,
    this.myShare,
  });

  final String id;
  final String title;
  final String dateText;
  final String payerName;
  final GroupBillStatus status;
  final int totalAmount;

  /// Phần của tôi — `null` khi hóa đơn chưa phân bổ xong.
  final int? myShare;
  final int paidMemberCount;
  final int memberCount;

  /// Chữ viết tắt 2 ký tự cho ô icon vuông của thẻ hóa đơn.
  String get initials {
    final parts = title.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'HD';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  double get paidRatio => memberCount == 0 ? 0 : paidMemberCount / memberCount;

  @override
  List<Object?> get props => [id, title, status, totalAmount, myShare, paidMemberCount];
}
