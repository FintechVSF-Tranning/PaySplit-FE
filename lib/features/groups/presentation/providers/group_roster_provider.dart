import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/group_sync_entity.dart';
import '../../domain/usecases/get_group_detail_usecase.dart';
import '../../domain/usecases/sync_group_usecase.dart';

/// Trạng thái danh sách thành viên của một nhóm, kèm version đang giữ.
class GroupRosterState {
  const GroupRosterState({
    this.members = const [],
    this.version = 0,
    this.callerRole = '',
    this.callerMembershipId = '',
    this.groupName,
    this.isLoading = true,
    this.isLive = false,
    this.failure,
    this.endedReason,
  });

  final List<GroupMemberEntity> members;

  /// Version của sự kiện cuối cùng đã áp. Mọi lần mở stream và mọi lần catch-up
  /// đều xuất phát từ đây, nên nó là thứ duy nhất bắt buộc phải luôn đúng.
  final int version;
  final String callerRole;

  /// membership_id của chính người gọi — dùng để đánh dấu "tôi" trong danh sách.
  final String callerMembershipId;
  final String? groupName;
  final bool isLoading;

  /// Đang có kết nối SSE. `false` không có nghĩa là dữ liệu sai — chỉ là độ trễ
  /// quay về mức của lần catch-up gần nhất.
  final bool isLive;
  final Failure? failure;

  /// Khác null khi caller không còn quyền đọc nhóm: `group_archived` hoặc
  /// `membership_ended`. Màn hình dùng nó để điều hướng ra ngoài.
  final String? endedReason;

  bool get isCaptain => callerRole == 'captain';

  GroupRosterState copyWith({
    List<GroupMemberEntity>? members,
    int? version,
    String? callerRole,
    String? callerMembershipId,
    String? groupName,
    bool? isLoading,
    bool? isLive,
    Failure? failure,
    bool clearFailure = false,
    String? endedReason,
  }) {
    return GroupRosterState(
      members: members ?? this.members,
      version: version ?? this.version,
      callerRole: callerRole ?? this.callerRole,
      callerMembershipId: callerMembershipId ?? this.callerMembershipId,
      groupName: groupName ?? this.groupName,
      isLoading: isLoading ?? this.isLoading,
      isLive: isLive ?? this.isLive,
      failure: clearFailure ? null : (failure ?? this.failure),
      endedReason: endedReason ?? this.endedReason,
    );
  }
}

/// Giữ danh sách thành viên của một nhóm khớp với server, độ trễ tính bằng
/// mili giây thay vì bằng thao tác kéo refresh của người dùng.
///
/// Ba lớp xếp chồng, tin cậy giảm dần:
///   1. `GET /groups/{id}` dựng trạng thái xuất phát cùng version.
///   2. Stream SSE đẩy delta — nhanh, nhưng được phép mất gói.
///   3. `GET /sync?since=` hàn mọi lỗ hổng, và là đường duy nhất được tin khi
///      version không liền mạch.
///
/// Vì lớp 3 luôn có mặt, lớp 2 đứt lúc nào cũng không làm sai dữ liệu — nó chỉ
/// làm tăng độ trễ.
class GroupRosterNotifier extends StateNotifier<GroupRosterState> with WidgetsBindingObserver {
  GroupRosterNotifier(this.groupId) : super(const GroupRosterState()) {
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  final String groupId;

  StreamSubscription<GroupSyncEvent>? _subscription;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _closed = false;

  /// Backoff khi kết nối đứt. Jitter là bắt buộc chứ không phải trang trí: sau
  /// một lần deploy, mọi client rớt cùng lúc và sẽ quay lại thành đúng một đợt
  /// nếu tất cả cùng chờ một khoảng bằng nhau.
  static const List<int> _backoffSeconds = [1, 2, 4, 8, 15, 30];
  static final Random _random = Random();

  Future<void> _bootstrap() async {
    final result = await getIt<GetGroupDetailUseCase>().call(groupId);
    if (_closed) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (detail) => state = state.copyWith(
        members: detail.members,
        version: detail.version,
        callerRole: detail.callerRole,
        callerMembershipId: detail.callerMembershipId,
        groupName: detail.group.name,
        isLoading: false,
        clearFailure: true,
      ),
    );
    if (state.failure == null) _connect();
  }

  /// Mở stream từ version hiện tại. Luôn gửi `since` nên không có sự kiện nào
  /// rơi vào khoảng trống giữa hai lần kết nối.
  void _connect() {
    if (_closed || state.endedReason != null) return;
    _reconnectTimer?.cancel();
    _subscription?.cancel();

    _subscription = getIt<StreamGroupEventsUseCase>()
        .call(groupId, since: state.version)
        .listen(
          _apply,
          onError: (_) => _scheduleReconnect(),
          // Server đóng sạch khi chạm tuổi thọ tối đa: kết nối lại ngay, không
          // backoff, vì đây là đóng có kế hoạch chứ không phải sự cố.
          onDone: () => _closed ? null : _reconnect(immediate: true),
          cancelOnError: true,
        );
    state = state.copyWith(isLive: true);
    _attempt = 0;
  }

  void _scheduleReconnect() {
    if (_closed) return;
    state = state.copyWith(isLive: false);
    final base = _backoffSeconds[min(_attempt, _backoffSeconds.length - 1)];
    _attempt++;
    final jittered = base * (0.7 + _random.nextDouble() * 0.6);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: (jittered * 1000).round()), () => _reconnect());
  }

  /// Nối lại: catch-up trước rồi mới mở stream, vì những gì xảy ra lúc mất kết
  /// nối chỉ có `/sync` mới lấy về được.
  Future<void> _reconnect({bool immediate = false}) async {
    if (_closed || state.endedReason != null) return;
    if (!immediate) await resync();
    if (_closed) return;
    _connect();
  }

  /// Hàn gắp bằng đường nguội. Public vì màn hình cũng gọi nó khi kéo refresh.
  Future<void> resync() async {
    if (_closed) return;
    final result = await getIt<SyncGroupUseCase>().call(
      SyncGroupParams(groupId: groupId, since: state.version),
    );
    if (_closed) return;
    result.fold((failure) => state = state.copyWith(failure: failure), (sync) {
      final snapshot = sync.snapshot;
      if (snapshot != null) {
        state = state.copyWith(
          members: snapshot.members,
          version: snapshot.version,
          callerRole: snapshot.callerRole,
          callerMembershipId: snapshot.callerMembershipId,
          groupName: snapshot.groupName,
          clearFailure: true,
        );
        return;
      }
      for (final event in sync.events) {
        _apply(event, fromCatchUp: true);
      }
      state = state.copyWith(version: max(state.version, sync.version), clearFailure: true);
    });
  }

  /// Áp một sự kiện. Đây là toàn bộ phần "version fencing" ở phía client.
  void _apply(GroupSyncEvent event, {bool fromCatchUp = false}) {
    if (_closed) return;

    // Trùng lặp, hoặc chính là tiếng vọng của một thao tác vừa cập nhật lạc
    // quan tại chỗ. Bỏ qua để UI không nháy.
    if (event.version <= state.version) return;

    // Nhảy cóc: đã sót sự kiện. Không được đoán phần thiếu — chuyển sang đường
    // nguội. Trong lúc catch-up chạy, các sự kiện đến sau vẫn rơi vào nhánh
    // này và bị bỏ qua, cho tới khi version được kéo lên đúng.
    if (event.version != state.version + 1) {
      if (!fromCatchUp) unawaited(resync());
      return;
    }

    // Payload bị cắt hoặc loại sự kiện client chưa biết: vẫn tiến version để
    // không tự tạo ra một lỗ hổng giả, rồi lấy nội dung thật qua catch-up.
    if (event.isOpaque) {
      state = state.copyWith(version: event.version);
      if (!fromCatchUp) unawaited(resync());
      return;
    }

    switch (event.type) {
      case GroupSyncEventType.memberJoined:
      case GroupSyncEventType.memberReactivated:
        final member = event.member!;
        // Chèn idempotent: một thành viên tái kích hoạt có thể đã nằm sẵn
        // trong danh sách của snapshot vừa nhận.
        final members = [...state.members.where((m) => m.id != member.id), member];
        state = state.copyWith(members: members, version: event.version);

      case GroupSyncEventType.memberLeft:
      case GroupSyncEventType.memberRemoved:
        state = state.copyWith(
          members: state.members.where((m) => m.id != event.membershipId).toList(),
          version: event.version,
        );

      case GroupSyncEventType.captainTransferred:
        state = state.copyWith(
          members: [
            for (final m in state.members)
              _withRole(
                m,
                m.id == event.currentCaptainMembershipId
                    ? GroupMemberRole.captain
                    : GroupMemberRole.member,
              ),
          ],
          // Quyền của chính caller đổi theo: nếu membership của tôi là đích
          // chuyển quyền thì tôi thành Captain, ngược lại thành thành viên.
          callerRole: _callerRoleAfterTransfer(event),
          version: event.version,
        );

      case GroupSyncEventType.groupRenamed:
        state = state.copyWith(groupName: event.groupName, version: event.version);

      case GroupSyncEventType.groupArchived:
        state = state.copyWith(version: event.version, endedReason: 'group_archived');
        _teardown();

      case GroupSyncEventType.unknown:
        state = state.copyWith(version: event.version);
    }
  }

  String _callerRoleAfterTransfer(GroupSyncEvent event) {
    // Biết membership của chính mình nên vai trò mới suy được trực tiếp, không
    // phải đoán từ vai trò cũ.
    if (state.callerMembershipId.isEmpty) return state.callerRole;
    return event.currentCaptainMembershipId == state.callerMembershipId ? 'captain' : 'member';
  }

  GroupMemberEntity _withRole(GroupMemberEntity member, GroupMemberRole role) {
    return GroupMemberEntity(
      id: member.id,
      name: member.name,
      phone: member.phone,
      avatarUrl: member.avatarUrl,
      role: role,
      sharedGroupCount: member.sharedGroupCount,
    );
  }

  /// Sau một mutation do chính thiết bị này thực hiện: version server trả về
  /// cho phép bỏ qua tiếng vọng sắp tới thay vì dựng lại toàn bộ danh sách.
  void markLocalMutation(int serverVersion) {
    if (serverVersion > state.version) {
      state = state.copyWith(version: serverVersion);
    }
  }

  // Tham số cố ý không đặt tên `state` như chữ ký gốc: trong một StateNotifier
  // cái tên đó che mất state của chính notifier.
  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed || _closed) return;
    // iOS cắt kết nối sống lâu khi app xuống nền, và bản thân stream không biết
    // điều đó. Resume là thời điểm rẻ nhất và chắc chắn nhất để đồng bộ lại.
    unawaited(_reconnect());
  }

  void _teardown() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    if (mounted) state = state.copyWith(isLive: false);
  }

  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

/// Roster được key theo `group_id`.
///
/// Cố ý KHÔNG `autoDispose`: người dùng chuyển sang tab Hóa đơn rồi quay lại sẽ
/// dựng lại kết nối liên tục. Màn hình chi tiết tự gỡ provider khi rời hẳn.
final groupRosterProvider =
    StateNotifierProvider.family<GroupRosterNotifier, GroupRosterState, String>(
      (ref, groupId) => GroupRosterNotifier(groupId),
    );
