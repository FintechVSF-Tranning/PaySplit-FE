import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/group_mock_data.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';

/// Store tạm cho luồng Nhóm. Dữ liệu đến từ [GroupMockData]; khi có API thật
/// chỉ cần thay thân các method bằng lời gọi UseCase, chữ ký giữ nguyên.
class GroupsNotifier extends StateNotifier<List<GroupEntity>> {
  GroupsNotifier() : super(GroupMockData.myGroups);

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final _random = Random();

  /// Tạo nhóm mới và đưa lên đầu danh sách. Trả về nhóm vừa tạo để màn hình
  /// tiếp theo (Thêm thành viên) điều hướng ngay bằng object thật.
  GroupEntity createGroup({required String name, required String emoji}) {
    final group = GroupEntity(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      emoji: emoji,
      memberCount: 1,
      myBalance: 0,
      inviteCode: _generateInviteCode(),
      isCaptain: true,
      lastActivity: 'Bạn vừa tạo nhóm',
      lastActivityAt: DateTime.now(),
    );
    state = [group, ...state];
    return group;
  }

  /// Đưa nhóm vừa tham gia (qua link mời hoặc quét QR) lên đầu danh sách.
  /// Nếu đã ở trong nhóm thì chỉ nhấc lên đầu, không tạo bản ghi trùng.
  void joinGroup(GroupEntity group) {
    final existing = findById(group.id);
    final rest = state.where((g) => g.id != group.id);
    state = [
      if (existing != null)
        _copyWith(existing, lastActivity: 'Bạn vừa tham gia nhóm', lastActivityAt: DateTime.now())
      else
        group,
      ...rest,
    ];
  }

  /// Thêm thành viên vào nhóm — ở mock chỉ cập nhật sĩ số hiển thị.
  void addMembers(String groupId, List<GroupMemberEntity> members) {
    if (members.isEmpty) return;
    state = [
      for (final g in state)
        if (g.id == groupId)
          _copyWith(
            g,
            memberCount: g.memberCount + members.length,
            lastActivity: 'Đã thêm ${members.length} thành viên mới',
            lastActivityAt: DateTime.now(),
          )
        else
          g,
    ];
  }

  /// Đổi tên nhóm (đồng bộ với thay đổi từ màn Chi tiết nhóm).
  void renameGroup(String groupId, String newName) {
    state = [
      for (final g in state)
        if (g.id == groupId) _copyWith(g, name: newName.trim()) else g,
    ];
  }

  /// Gỡ nhóm khỏi danh sách khi rời nhóm hoặc giải tán nhóm.
  void deleteGroup(String groupId) {
    state = state.where((g) => g.id != groupId).toList();
  }

  /// Khóa / mở khóa bill của nhóm, đồng bộ từ màn Chi tiết nhóm.
  void setGroupStatus(String groupId, GroupStatus status, {String? closedAtText}) {
    state = [
      for (final g in state)
        if (g.id == groupId) _copyWith(g, status: status, closedAtText: closedAtText) else g,
    ];
  }

  GroupEntity _copyWith(
    GroupEntity g, {
    String? name,
    int? memberCount,
    GroupStatus? status,
    String? closedAtText,
    String? lastActivity,
    DateTime? lastActivityAt,
  }) {
    return GroupEntity(
      id: g.id,
      name: name ?? g.name,
      emoji: g.emoji,
      memberCount: memberCount ?? g.memberCount,
      myBalance: g.myBalance,
      inviteCode: g.inviteCode,
      isCaptain: g.isCaptain,
      lastActivity: lastActivity ?? g.lastActivity,
      lastActivityAt: lastActivityAt ?? g.lastActivityAt,
      pendingBillCount: g.pendingBillCount,
      status: status ?? g.status,
      closedAtText: closedAtText ?? g.closedAtText,
    );
  }

  GroupEntity? findById(String groupId) {
    for (final g in state) {
      if (g.id == groupId) return g;
    }
    return null;
  }

  String _generateInviteCode({int length = 8}) =>
      List.generate(length, (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)]).join();
}

final groupsProvider = StateNotifierProvider<GroupsNotifier, List<GroupEntity>>(
  (ref) => GroupsNotifier(),
);

/// Nhóm ghé thăm gần đây (mock tĩnh, tách khỏi danh sách nhóm chính).
final recentGroupsProvider = Provider<List<GroupEntity>>((ref) => GroupMockData.recentGroups);

/// Danh bạ gợi ý cho màn hình Thêm thành viên.
final recentContactsProvider = Provider<List<GroupMemberEntity>>(
  (ref) => GroupMockData.recentContacts,
);
