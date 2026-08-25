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
  'bill_bulk_finalize_started': GroupActivityKind.system,
  'bill_bulk_finalize_completed': GroupActivityKind.system,
};

extension ActivityModelMapper on ActivityModel {
  GroupActivityEntity toEntity() => GroupActivityEntity(
    id: id,
    // Backend đã Việt hóa sẵn `description`, FE không dựng lại câu chữ.
    title: description,
    subtitle: actor.displayName,
    timeText: formatRelativeTime(createdAt),
    kind: kActivityKindByActionType[actionType] ?? GroupActivityKind.system,
  );
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
