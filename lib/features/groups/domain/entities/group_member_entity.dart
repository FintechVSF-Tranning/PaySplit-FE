import 'package:equatable/equatable.dart';

/// Vai trò thành viên trong nhóm.
enum GroupMemberRole { captain, member }

/// Thành viên nhóm (hoặc gợi ý "thành viên gần đây" chưa được thêm).
class GroupMemberEntity extends Equatable {
  const GroupMemberEntity({
    required this.id,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.role = GroupMemberRole.member,
    this.sharedGroupCount = 0,
  });

  final String id;
  final String name;

  /// Số điện thoại. `null` từ API nhóm: `memberResponse` của backend cố ý
  /// không trả số điện thoại thành viên vì lý do quyền riêng tư.
  final String? phone;
  final String? avatarUrl;
  final GroupMemberRole role;

  /// Số nhóm đã từng chung với tôi — dùng để xếp hạng "Thành viên gần đây".
  final int sharedGroupCount;

  /// Chữ cái viết tắt cho avatar monogram.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, phone, role];
}
