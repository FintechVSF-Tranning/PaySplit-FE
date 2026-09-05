import 'package:equatable/equatable.dart';

/// Trạng thái vòng đời của một hóa đơn, khớp 1-1 với `bill_status` của backend.
enum GroupBillStatus {
  /// `draft` — vừa tạo / vừa OCR xong, còn sửa được.
  draft,

  /// `reviewed` — đã đối soát, chờ chốt sổ.
  reviewed,

  /// `finalized` — đã chốt sổ, sinh công nợ.
  finalized,

  /// `voided` — đã hủy.
  voided,
}

extension GroupBillStatusX on GroupBillStatus {
  /// Giá trị gửi lên query param `status` của `GET /api/v1/bills`.
  String get apiValue => name;

  String get label => switch (this) {
    GroupBillStatus.draft => 'Nháp',
    GroupBillStatus.reviewed => 'Chờ duyệt',
    GroupBillStatus.finalized => 'Đã chốt',
    GroupBillStatus.voided => 'Đã hủy',
  };

  /// Hóa đơn còn phải xử lý (chưa chốt, chưa hủy).
  bool get isActive => this == GroupBillStatus.draft || this == GroupBillStatus.reviewed;

  static GroupBillStatus fromApi(String value) => switch (value) {
    'reviewed' => GroupBillStatus.reviewed,
    'finalized' => GroupBillStatus.finalized,
    'voided' => GroupBillStatus.voided,
    _ => GroupBillStatus.draft,
  };
}

/// Bộ lọc hóa đơn trên tab Hóa đơn của màn chi tiết nhóm: "Tất cả" cộng với
/// đúng 4 trạng thái của backend.
enum GroupBillFilter { all, draft, reviewed, finalized, voided }

extension GroupBillFilterX on GroupBillFilter {
  String get label => switch (this) {
    GroupBillFilter.all => 'Tất cả',
    GroupBillFilter.draft => GroupBillStatus.draft.label,
    GroupBillFilter.reviewed => GroupBillStatus.reviewed.label,
    GroupBillFilter.finalized => GroupBillStatus.finalized.label,
    GroupBillFilter.voided => GroupBillStatus.voided.label,
  };

  /// Trạng thái tương ứng, `null` với "Tất cả".
  GroupBillStatus? get status => switch (this) {
    GroupBillFilter.all => null,
    GroupBillFilter.draft => GroupBillStatus.draft,
    GroupBillFilter.reviewed => GroupBillStatus.reviewed,
    GroupBillFilter.finalized => GroupBillStatus.finalized,
    GroupBillFilter.voided => GroupBillStatus.voided,
  };

  /// Danh sách gửi lên `?status=` — rỗng nghĩa là không lọc.
  List<String> get apiStatuses {
    final value = status;
    return value == null ? const [] : [value.apiValue];
  }

  bool matches(GroupBillStatus billStatus) {
    final value = status;
    return value == null || value == billStatus;
  }
}

/// Vai trò của người đang xem trong một hóa đơn — quyết định dòng "Phần của
/// bạn" trên thẻ hóa đơn.
enum GroupBillShareStatus { none, creditor, pending, settled }

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
    this.version = 1,
    this.myShare,
    this.myShareStatus = GroupBillShareStatus.none,
    this.isScanningOcr = false,
    this.ocrFailed = false,
  });

  final String id;
  final String title;
  final String dateText;
  final String payerName;
  final GroupBillStatus status;
  final int totalAmount;

  /// Phần của tôi — `null` khi hóa đơn chưa chốt sổ.
  final int? myShare;
  final GroupBillShareStatus myShareStatus;

  /// Ảnh hóa đơn còn đang được AI bóc tách.
  final bool isScanningOcr;

  /// Lần bóc tách AI gần nhất đã thất bại. Không có cờ này thì một hóa đơn OCR
  /// hỏng trông y hệt một bản nháp bình thường đang chờ gán món, và người tạo
  /// nó không có lý do gì để mở vào xem.
  final bool ocrFailed;

  final int paidMemberCount;
  final int memberCount;

  /// Optimistic locking version của backend — cần khi huỷ hóa đơn đã chốt.
  final int version;

  /// Chữ viết tắt 2 ký tự cho ô icon vuông của thẻ hóa đơn.
  String get initials {
    final parts = title.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'HD';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  double get paidRatio => memberCount == 0 ? 0 : paidMemberCount / memberCount;

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    totalAmount,
    myShare,
    myShareStatus,
    isScanningOcr,
    ocrFailed,
    paidMemberCount,
  ];
}

/// Một trang hóa đơn của nhóm kèm số lượng theo từng trạng thái (badge của các
/// chip lọc), đúng shape `data` của `GET /api/v1/bills`.
class GroupBillsPage extends Equatable {
  const GroupBillsPage({
    required this.bills,
    this.counts = const {},
    this.totalCount = 0,
    this.nextCursor,
  });

  final List<GroupBillEntity> bills;
  final Map<GroupBillStatus, int> counts;
  final int totalCount;
  final String? nextCursor;

  int countFor(GroupBillFilter filter) {
    final status = filter.status;
    return status == null ? totalCount : (counts[status] ?? 0);
  }

  @override
  List<Object?> get props => [bills, counts, totalCount, nextCursor];
}
