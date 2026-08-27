import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/disband_group_usecase.dart';
import '../../domain/usecases/join_group_usecase.dart';
import '../../domain/usecases/leave_or_remove_member_usecase.dart';
import '../../domain/usecases/list_groups_usecase.dart';
import '../../domain/usecases/rename_group_usecase.dart';
import '../../../../app/session/session_scope.dart';

/// Trạng thái màn hình danh sách nhóm: giữ danh sách đã tải cùng cờ tải/lỗi và
/// cursor phân trang của backend.
class GroupsState {
  const GroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
    this.nextCursor,
  });

  final List<GroupEntity> groups;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? failure;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  GroupsState copyWith({
    List<GroupEntity>? groups,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    String? nextCursor,
    bool clearCursor = false,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    );
  }
}

/// Store cho luồng Nhóm, nay gọi API thật qua UseCase.
///
/// Các method thay đổi dữ liệu đều trả về [Failure] `null` khi thành công, để
/// màn hình quyết định hiển thị snackbar lỗi mà không cần bắt exception.
class GroupsNotifier extends StateNotifier<GroupsState> {
  GroupsNotifier() : super(const GroupsState()) {
    refresh();
  }

  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await getIt<ListGroupsUseCase>().call(
      const ListGroupsParams(limit: _pageSize),
    );
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, failure: failure),
      (page) => GroupsState(groups: page.items, nextCursor: page.nextCursor),
    );
  }

  /// Tải trang tiếp theo bằng cursor của backend; không làm gì khi đã hết dữ liệu.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    final result = await getIt<ListGroupsUseCase>().call(
      ListGroupsParams(limit: _pageSize, cursor: state.nextCursor),
    );
    state = result.fold(
      (failure) => state.copyWith(isLoadingMore: false, failure: failure),
      (page) => GroupsState(
        groups: [...state.groups, ...page.items],
        nextCursor: page.nextCursor,
      ),
    );
  }

  /// Tạo nhóm và đưa lên đầu danh sách. Trả về nhóm vừa tạo, hoặc `null` khi lỗi.
  Future<GroupEntity?> createGroup({required String name}) async {
    final result = await getIt<CreateGroupUseCase>().call(
      CreateGroupParams(name: name.trim()),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(failure: failure);
        return null;
      },
      (group) {
        state = state.copyWith(
          groups: [group, ...state.groups],
          clearFailure: true,
        );
        return group;
      },
    );
  }

  /// Tham gia nhóm bằng mã mời rồi tải lại danh sách để lấy dữ liệu thật của nhóm.
  Future<Failure?> joinGroupByCode(String code) async {
    final result = await getIt<JoinGroupUseCase>().call(code);
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) return failure;
    await refresh();
    return null;
  }

  Future<Failure?> renameGroup(String groupId, String newName) async {
    final result = await getIt<RenameGroupUseCase>().call(
      RenameGroupParams(groupId: groupId, name: newName.trim()),
    );
    return result.fold((failure) => failure, (updated) {
      _replace(groupId, (current) => _merge(current, updated));
      return null;
    });
  }

  /// Giải tán nhóm (Captain). Backend trả 409 khi nhóm còn hóa đơn hoặc công nợ.
  Future<Failure?> disbandGroup(String groupId) async {
    final result = await getIt<DisbandGroupUseCase>().call(groupId);
    return result.fold((failure) => failure, (_) {
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
      );
      return null;
    });
  }

  /// Rời nhóm — cùng endpoint với việc Captain xóa thành viên.
  Future<Failure?> leaveGroup(String groupId, String myMembershipId) async {
    final result = await getIt<LeaveOrRemoveMemberUseCase>().call(
      MemberParams(groupId: groupId, membershipId: myMembershipId),
    );
    return result.fold((failure) => failure, (_) {
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
      );
      return null;
    });
  }

  /// Gỡ nhóm khỏi danh sách khi quyền đọc không còn (nhóm bị giải tán, hoặc
  /// mình bị xóa khỏi nhóm) — biết được qua stream của màn chi tiết.
  void removeGroupLocally(String groupId) {
    if (!state.groups.any((g) => g.id == groupId)) return;
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != groupId).toList(),
    );
  }

  /// Áp trạng thái đã khóa hóa đơn vào danh sách sau khi
  /// `POST /groups/{id}/bills/lock-submissions` thành công, để không phải tải
  /// lại cả danh sách chỉ vì một nhóm đổi trạng thái. Khóa ở backend là một
  /// chiều: không có endpoint mở lại.
  void markGroupClosedLocally(String groupId, String closedAtText) {
    _replace(
      groupId,
      (g) => GroupEntity(
        id: g.id,
        name: g.name,
        memberCount: g.memberCount,
        myBalance: g.myBalance,
        inviteCode: g.inviteCode,
        isCaptain: g.isCaptain,
        lastActivity: g.lastActivity,
        lastActivityAt: g.lastActivityAt,
        pendingBillCount: g.pendingBillCount,
        status: g.status,
        billSubmissionLocked: true,
        closedAtText: closedAtText,
        createdAt: g.createdAt,
      ),
    );
  }

  /// Áp trạng thái mở khóa nhận hóa đơn vào danh sách sau khi mở khóa thành công.
  void markGroupUnlockedLocally(String groupId) {
    _replace(
      groupId,
      (g) => GroupEntity(
        id: g.id,
        name: g.name,
        memberCount: g.memberCount,
        myBalance: g.myBalance,
        inviteCode: g.inviteCode,
        isCaptain: g.isCaptain,
        lastActivity: g.lastActivity,
        lastActivityAt: g.lastActivityAt,
        pendingBillCount: g.pendingBillCount,
        status: g.status,
        createdAt: g.createdAt,
      ),
    );
  }

  /// Ghi ngược dữ liệu vừa đọc được ở màn chi tiết nhóm vào danh sách.
  ///
  /// Danh sách chỉ được tải một lần mỗi phiên, nên khi người khác đổi tên nhóm
  /// hay có người vào/rời, item ở đây đứng yên cho tới lần mở app sau: mở nhóm
  /// ra thấy tên mới, back lại vẫn thấy tên cũ. Màn chi tiết có sẵn dữ liệu
  /// tươi từ `GET /groups/{id}` + stream roster, nên nó trả lại cho danh sách.
  ///
  /// Không đụng tới nhóm chưa có trong danh sách (chưa tải tới trang đó).
  void applyGroupSnapshot({
    required String groupId,
    String? name,
    int? memberCount,
    bool? isCaptain,
  }) {
    final trimmedName = name?.trim();
    final index = state.groups.indexWhere((g) => g.id == groupId);
    if (index < 0) return;

    final current = state.groups[index];
    final nextName = (trimmedName == null || trimmedName.isEmpty)
        ? current.name
        : trimmedName;
    final nextMemberCount = memberCount ?? current.memberCount;
    final nextIsCaptain = isCaptain ?? current.isCaptain;
    if (nextName == current.name &&
        nextMemberCount == current.memberCount &&
        nextIsCaptain == current.isCaptain) {
      return;
    }

    _replace(
      groupId,
      (g) => GroupEntity(
        id: g.id,
        name: nextName,
        memberCount: nextMemberCount,
        myBalance: g.myBalance,
        inviteCode: g.inviteCode,
        isCaptain: nextIsCaptain,
        lastActivity: g.lastActivity,
        lastActivityAt: g.lastActivityAt,
        pendingBillCount: g.pendingBillCount,
        status: g.status,
        closedAtText: g.closedAtText,
        createdAt: g.createdAt,
      ),
    );
  }

  void _replace(String groupId, GroupEntity Function(GroupEntity) transform) {
    state = state.copyWith(
      groups: [
        for (final g in state.groups)
          if (g.id == groupId) transform(g) else g,
      ],
      clearFailure: true,
    );
  }

  /// Response của PATCH chỉ chứa thông tin nhóm, không có sĩ số hay số dư — giữ
  /// lại các giá trị đó từ item đang hiển thị.
  GroupEntity _merge(GroupEntity current, GroupEntity updated) => GroupEntity(
    id: updated.id,
    name: updated.name,
    memberCount: current.memberCount,
    myBalance: current.myBalance,
    inviteCode: current.inviteCode,
    isCaptain: current.isCaptain,
    lastActivity: current.lastActivity,
    lastActivityAt: current.lastActivityAt,
    pendingBillCount: current.pendingBillCount,
    status: updated.status,
    billSubmissionLocked: updated.billSubmissionLocked,
    closedAtText: updated.closedAtText,
    createdAt: current.createdAt ?? updated.createdAt,
  );
}

final groupsProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((
  ref,
) {
  ref.watch(sessionRevisionProvider);
  return GroupsNotifier();
});

/// Nhóm gần đây — dẫn xuất từ dữ liệu thật của [groupsProvider] (backend chưa
/// có API "ghé thăm gần đây" riêng), xếp theo hoạt động mới nhất và bỏ nhóm đã
/// khóa; tối đa 3 nhóm.
final recentGroupsProvider = Provider<List<GroupEntity>>((ref) {
  final groups =
      ref.watch(groupsProvider).groups.where((g) => !g.isClosed).toList()
        ..sort((a, b) {
          final aAt = a.lastActivityAt;
          final bAt = b.lastActivityAt;
          if (aAt == null && bAt == null) return 0;
          if (aAt == null) return 1;
          if (bAt == null) return -1;
          return bAt.compareTo(aAt);
        });
  return groups.take(3).toList();
});
