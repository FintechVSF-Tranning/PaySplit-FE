import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/group_activity_entity.dart';
import 'group_models.dart';

/// Bảng ánh xạ `action_type` của backend sang [GroupActivityKind] — chốt hợp
/// đồng cho mục 3.7 của báo cáo đối chiếu. Giá trị enum lấy từ `activity_type`
/// trong `db/migrations`; giá trị lạ (backend thêm mới) rơi về [system] thay vì
/// ném lỗi, để app cũ không vỡ khi backend mở rộng enum.
const Map<String, GroupActivityKind> kActivityKindByActionType = {
  // Hóa đơn
  'created_bill': GroupActivityKind.bill,
  'updated_bill': GroupActivityKind.bill,
  'deleted_bill': GroupActivityKind.bill,
  'finalized_bill': GroupActivityKind.bill,
  'reviewed_bill': GroupActivityKind.bill,
  'voided_bill': GroupActivityKind.bill,
  // Thanh toán / công nợ
  'submitted_proof': GroupActivityKind.payment,
  'confirmed_payment': GroupActivityKind.payment,
  'rejected_payment': GroupActivityKind.payment,
  'stalled_payment_reminder': GroupActivityKind.payment,
  'payment_created': GroupActivityKind.payment,
  'debt_reminded': GroupActivityKind.payment,
  // Thành viên
  'member_joined': GroupActivityKind.member,
  'member_reactivated': GroupActivityKind.member,
  'member_left': GroupActivityKind.member,
  'member_removed': GroupActivityKind.member,
  'captain_transferred': GroupActivityKind.member,
  'invite_created': GroupActivityKind.member,
  'invite_revoked': GroupActivityKind.member,
  // Hệ thống / vòng đời nhóm
  'group_created': GroupActivityKind.system,
  'group_renamed': GroupActivityKind.system,
  'group_archived': GroupActivityKind.system,
  'bill_submission_locked': GroupActivityKind.system,
  'bill_submission_unlocked': GroupActivityKind.system,
  'bill_bulk_finalize_started': GroupActivityKind.system,
  'bill_bulk_finalize_completed': GroupActivityKind.system,
};

extension ActivityModelMapper on ActivityModel {
  GroupActivityEntity toEntity() => GroupActivityEntity(
    id: id,
    title: formatActivityTitle(description),
    subtitle: actor.displayName,
    timeText: formatRelativeTime(createdAt),
    kind: kActivityKindByActionType[actionType] ?? GroupActivityKind.system,
  );
}

/// Chuẩn hóa nội dung hoạt động nhóm: Tiếng Việt, viết hoa chữ cái đầu và xử lý dữ liệu lịch sử.
String formatActivityTitle(String raw) {
  if (raw.isEmpty) return raw;

  var title = raw.trim();

  // 1. Ánh xạ các câu mô tả tiếng Anh cũ trong database nếu có
  if (title.equalsIgnoreCase('Debt reminder sent')) {
    title = 'Đã gửi lời nhắc thanh toán';
  } else if (title.equalsIgnoreCase('Automated debt reminder sent')) {
    title = 'Hệ thống đã tự động gửi nhắc nợ';
  } else if (title.toLowerCase().startsWith('finalized bill')) {
    final match = RegExp(r'finalized bill \(total (\d+) VND\)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      final total = double.tryParse(match.group(1) ?? '0') ?? 0;
      title = 'Đã chốt hóa đơn (tổng ${CurrencyFormatter.formatVND(total)})';
    } else {
      title = 'Đã chốt hóa đơn';
    }
  } else if (title.toLowerCase().startsWith('reviewed bill')) {
    final match = RegExp(r'reviewed bill \(version (\d+)\)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      title = 'Đã duyệt hóa đơn (phiên bản ${match.group(1)})';
    } else {
      title = 'Đã duyệt hóa đơn';
    }
  } else if (title.toLowerCase().startsWith('updated bill draft')) {
    final match = RegExp(r'updated bill draft \(version (\d+)\)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      title = 'Đã cập nhật hóa đơn (phiên bản ${match.group(1)})';
    } else {
      title = 'Đã cập nhật hóa đơn';
    }
  } else if (title.toLowerCase().startsWith('created bill draft')) {
    final match = RegExp(r'created bill draft (.+)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      title = 'Đã tạo hóa đơn nháp ${match.group(1)}';
    } else {
      title = 'Đã tạo hóa đơn nháp';
    }
  } else if (title.toLowerCase().startsWith('voided bill:')) {
    final match = RegExp(r'voided bill:\s*(.+)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      title = 'Đã hủy hóa đơn: ${match.group(1)}';
    } else {
      title = 'Đã hủy hóa đơn';
    }
  } else if (title.toLowerCase().startsWith('deleted draft bill')) {
    title = 'Đã xóa hóa đơn nháp';
  } else if (title.equalsIgnoreCase('Payment QR created')) {
    title = 'Đã tạo mã QR thanh toán';
  } else if (title.equalsIgnoreCase('Payment proof submitted')) {
    title = 'Đã gửi minh chứng thanh toán';
  } else if (title.equalsIgnoreCase('Payment confirmed')) {
    title = 'Đã xác nhận thanh toán';
  } else if (title.toLowerCase().startsWith('payment rejected')) {
    final match = RegExp(r'Payment rejected:\s*(.+)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      title = 'Đã từ chối minh chứng thanh toán: ${match.group(1)}';
    } else {
      title = 'Đã từ chối minh chứng thanh toán';
    }
  } else if (title.equalsIgnoreCase('Payment confirmation is stalled')) {
    title = 'Minh chứng thanh toán đang chờ xác nhận';
  } else if (title.toLowerCase().endsWith('joined the group')) {
    final actor = title.substring(0, title.length - 'joined the group'.length).trim();
    title = '$actor đã tham gia nhóm';
  } else if (title.toLowerCase().endsWith('rejoined the group')) {
    final actor = title.substring(0, title.length - 'rejoined the group'.length).trim();
    title = '$actor đã tham gia lại nhóm';
  } else if (title.toLowerCase().endsWith('left the group')) {
    final actor = title.substring(0, title.length - 'left the group'.length).trim();
    title = '$actor đã rời nhóm';
  } else if (title.toLowerCase().contains('removed') && title.toLowerCase().contains('from the group')) {
    final match = RegExp(r'(.+) removed (.+) from the group', caseSensitive: false).firstMatch(title);
    if (match != null) {
      title = '${match.group(1)} đã xóa ${match.group(2)} khỏi nhóm';
    }
  } else if (title.toLowerCase().endsWith('transferred the captain role')) {
    final actor = title.substring(0, title.length - 'transferred the captain role'.length).trim();
    title = '$actor đã chuyển quyền Trưởng nhóm';
  } else if (title.toLowerCase().contains('created the group')) {
    final match = RegExp(r'(.+) created the group (.+)', caseSensitive: false).firstMatch(title);
    if (match != null) {
      title = '${match.group(1)} đã tạo nhóm ${match.group(2)}';
    }
  } else if (title.toLowerCase().endsWith('created an invite')) {
    final actor = title.substring(0, title.length - 'created an invite'.length).trim();
    title = '$actor đã tạo mã mời tham gia';
  } else if (title.toLowerCase().endsWith('revoked an invite')) {
    final actor = title.substring(0, title.length - 'revoked an invite'.length).trim();
    title = '$actor đã thu hồi mã mời';
  } else if (title.toLowerCase().endsWith('archived the group')) {
    final actor = title.substring(0, title.length - 'archived the group'.length).trim();
    title = '$actor đã giải tán nhóm';
  } else if (title.equalsIgnoreCase('đã khóa gửi hóa đơn mới cho nhóm')) {
    title = 'Đã tạm khóa nhận hóa đơn mới cho nhóm';
  } else if (title.equalsIgnoreCase('đã mở khóa gửi hóa đơn cho nhóm')) {
    title = 'Đã mở khóa nhận hóa đơn cho nhóm';
  }

  // 2. Viết hoa chữ cái đầu tiên (hỗ trợ cả ký tự unicode tiếng Việt: 'đ' -> 'Đ', etc.)
  if (title.isNotEmpty) {
    final firstChar = title.substring(0, 1).toUpperCase();
    title = '$firstChar${title.substring(1)}';
  }

  return title;
}

extension on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}

/// Mốc thời gian tương đối kiểu "5 phút trước" cho dòng hoạt động.
String formatRelativeTime(DateTime value) {
  final diff = DateTime.now().difference(value.toLocal());
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
