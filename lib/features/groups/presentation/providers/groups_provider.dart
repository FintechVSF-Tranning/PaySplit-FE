import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/realtime/realtime_interest.dart';
import '../../../../core/realtime/register_realtime_interest.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/disband_group_usecase.dart';
import '../../domain/usecases/get_group_detail_usecase.dart';
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

  /// Tải lại **trang đầu** và ghép vào danh sách đang có.
  ///
  /// Chỉ trang đầu là realtime. Những trang người dùng đã bấm "Xem thêm" giữ
  /// nguyên nội dung tại thời điểm gọi backend — đổi lại mỗi sự kiện chỉ tốn
  /// đúng một request, thay vì tải lại tất cả những gì đang mở.
  ///
  /// Không thay cả danh sách bằng trang đầu: người dùng đang cuộn dở sẽ thấy
  /// những nhóm phía dưới biến mất ngay dưới ngón tay.
  ///
  /// [rethrowFailure] để tầng realtime biết lượt làm mới hỏng và giữ
  /// invalidation ở trạng thái bẩn để thử lại, thay vì nuốt mất nó.
  Future<void> refresh({bool rethrowFailure = false}) async {
    // Đọc trước khi đặt isLoading: state sẽ bị thay khi request xong.
    final previous = state.groups;
    final previousCursor = state.nextCursor;
    final hasScrolledPastFirstPage = previous.length > _pageSize;

    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await getIt<ListGroupsUseCase>().call(
      const ListGroupsParams(limit: _pageSize),
    );

    Failure? failure;
    GroupPage<GroupEntity>? loaded;
    result.fold((f) => failure = f, (page) => loaded = page);

    if (failure != null) {
      // Giữ nguyên danh sách đang hiển thị: một lỗi mạng thoáng qua không nên
      // trông giống như vài nhóm vừa bị xóa.
      state = state.copyWith(isLoading: false, failure: failure);
      if (rethrowFailure) throw failure!;
      return;
    }

    final fresh = loaded!.items;

    // Backend lấy `limit + 1` rồi chỉ trả nextCursor khi còn dư, nên null ở đây
    // nghĩa là trang đầu chính là toàn bộ danh sách — phần đuôi cũ đã không còn
    // tồn tại và giữ lại sẽ hiện những nhóm đã biến mất.
    if (loaded!.nextCursor == null) {
      state = GroupsState(groups: fresh);
      return;
    }

    // Ranh giới phần đuôi tìm theo id của mục cuối trang đầu, không theo vị trí
    // thứ 20 cố định. Nếu backend vừa chèn thêm một nhóm lên đầu (vừa tham gia
    // ở nơi khác), ranh giới trang đã dịch và cắt theo vị trí sẽ đánh rơi đúng
    // một nhóm đang hiển thị.
    var tailStart = _pageSize;
    final anchor = previous.indexWhere((group) => group.id == fresh.last.id);
    if (anchor >= 0) tailStart = anchor + 1;

    final freshIds = fresh.map((group) => group.id).toSet();

    state = GroupsState(
      groups: [
        ...fresh,
        // Phần người dùng đã cuộn tới, bỏ những nhóm đã có mặt ở trang đầu mới
        // để không hiện hai lần.
        ...previous
            .skip(tailStart)
            .where((group) => !freshIds.contains(group.id)),
      ],
      // Cursor phải tiếp tục từ sau phần đuôi, không phải từ sau trang đầu, nếu
      // không lần "Xem thêm" kế tiếp sẽ tải lại đúng những nhóm đang hiển thị.
      nextCursor: hasScrolledPastFirstPage
          ? previousCursor
          : loaded!.nextCursor,
    );
  }

  /// Cập nhật tại chỗ đúng một nhóm, giữ nguyên vị trí của nó trong danh sách.
  ///
  /// Đây là đường realtime cho những nhóm người dùng đã cuộn tới: tải lại trang
  /// đầu không chạm được tới chúng, còn tải lại cả danh sách thì vừa tốn vừa
  /// làm xô lệch đúng chỗ họ đang nhìn.
  ///
  /// Nhóm không nằm trong danh sách đang tải thì bỏ qua: với thứ tự cố định
  /// theo `created_at`, một nhóm chỉ lọt vào danh sách khi được tạo hoặc tham
  /// gia — cả hai đều đã cập nhật ngay tại chỗ.
  Future<void> patchGroup(String groupId, {bool rethrowFailure = false}) async {
    final index = state.groups.indexWhere((group) => group.id == groupId);
    if (index < 0) return;

    final result = await getIt<GetGroupDetailUseCase>().call(groupId);

    Failure? failed;
    result.fold((failure) => failed = failure, (detail) {
      final current = state.groups.indexWhere((group) => group.id == groupId);
      // Danh sách có thể đã đổi trong lúc chờ mạng.
      if (current < 0) return;
      final groups = [...state.groups];
      groups[current] = _mergeFromDetail(groups[current], detail.group);
      state = state.copyWith(groups: groups, clearFailure: true);
    });

    final failure = failed;
    if (failure != null) {
      // Không đặt failure lên state: một thẻ nhóm không làm mới được không phải
      // lý do để cả màn hình hiện thông báo lỗi. Lượt thử lại do tầng realtime lo.
      if (rethrowFailure) throw failure;
    }
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
  /// Ghép dữ liệu từ `GET /groups/{id}` vào một thẻ nhóm đang hiển thị.
  ///
  /// Khác [_merge] — vốn dành cho thao tác đổi tên tại chỗ và cố ý giữ nguyên
  /// các con số. Ở đây chính các con số mới là thứ cần thay: dùng nhầm [_merge]
  /// sẽ vứt đi đúng `pending_bill_count` vừa lấy về và khiến việc vá không có
  /// tác dụng gì.
  ///
  /// Những trường chỉ danh sách mới có (`last_activity`, `invite_code`) không
  /// nằm trong response chi tiết nên giữ nguyên giá trị đang hiển thị.
  GroupEntity _mergeFromDetail(GroupEntity current, GroupEntity fresh) =>
      GroupEntity(
        id: fresh.id,
        name: fresh.name,
        memberCount: fresh.memberCount,
        myBalance: fresh.myBalance,
        pendingBillCount: fresh.pendingBillCount,
        isCaptain: fresh.isCaptain,
        status: fresh.status,
        billSubmissionLocked: fresh.billSubmissionLocked,
        closedAtText: fresh.closedAtText,
        inviteCode: current.inviteCode,
        lastActivity: current.lastActivity,
        lastActivityAt: current.lastActivityAt,
        createdAt: current.createdAt ?? fresh.createdAt,
      );

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
  final notifier = GroupsNotifier();
  registerRealtimeInterest(
    ref,
    key: RealtimeInterestKey.groupsIndex(),
    refresh: () => notifier.refresh(rethrowFailure: true),
    patchGroup: (groupId) => notifier.patchGroup(groupId, rethrowFailure: true),
  );
  return notifier;
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

/// Bộ đếm kích hoạt reset trạng thái tìm kiếm nhóm khi người dùng chuyển tab hoặc bấm lại tab Nhóm.
final groupTabSearchResetProvider = StateProvider<int>((ref) => 0);

