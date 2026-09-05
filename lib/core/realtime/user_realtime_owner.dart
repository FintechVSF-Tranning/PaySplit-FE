import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session/session_scope.dart';
import '../config/env_config.dart';
import 'realtime_frame_bus.dart';
import 'realtime_interest.dart';
import 'realtime_interest_registry.dart';
import 'realtime_ports.dart';
import 'realtime_transport_mode.dart';
import 'sse_frame.dart';

enum RealtimeTransport { signedOut, connecting, resyncing, live, backoff }

class UserRealtimeState {
  const UserRealtimeState({
    this.transport = RealtimeTransport.signedOut,
    this.legacyFallback = false,
    this.sawReady = false,
  });

  final RealtimeTransport transport;
  final bool legacyFallback;
  final bool sawReady;

  UserRealtimeState copyWith({
    RealtimeTransport? transport,
    bool? legacyFallback,
    bool? sawReady,
  }) {
    return UserRealtimeState(
      transport: transport ?? this.transport,
      legacyFallback: legacyFallback ?? this.legacyFallback,
      sawReady: sawReady ?? this.sawReady,
    );
  }
}

final realtimeInterestRegistryProvider = Provider<RealtimeInterestRegistry>((
  ref,
) {
  return RealtimeInterestRegistry();
});

final realtimeFrameBusProvider = Provider<RealtimeFrameBus>((ref) {
  final bus = RealtimeFrameBus();
  ref.onDispose(bus.close);
  return bus;
});

final userRealtimeOwnerProvider =
    NotifierProvider<UserRealtimeOwner, UserRealtimeState>(
      UserRealtimeOwner.new,
    );

class UserRealtimeOwner extends Notifier<UserRealtimeState> {
  static const _backoffSeconds = [1, 2, 4, 8, 15, 30];
  static final _random = Random();

  StreamSubscription<SseFrame>? _subscription;
  Timer? _reconnectTimer;
  Timer? _coalesceTimer;
  Timer? _dirtyRetryTimer;
  CancelToken? _cancelToken;
  int _attempt = 0;
  int _dirtyAttempt = 0;
  bool _reconnectInFlight = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  /// Các đích đang bẩn, kèm số hiệu lần đánh dấu gần nhất.
  ///
  /// Một invalidation chỉ được xóa khi lần làm mới tương ứng **thành công**.
  /// Xóa trước khi chờ nghĩa là một lỗi REST thoáng qua sẽ để số dư, hóa đơn hay
  /// công nợ đứng yên vĩnh viễn trong khi stream vẫn báo "đang kết nối" — đúng
  /// kiểu mất cập nhật mà cơ chế này sinh ra để chặn.
  final Map<_DirtyTarget, int> _dirty = {};
  int _dirtySeq = 0;

  /// Số hiệu đánh dấu cho một interest chưa từng bẩn nhưng nằm trong đợt refetch
  /// toàn bộ; giữ riêng để không phải quét registry hai lần.
  bool _dirtyAll = false;

  final Map<String, List<SseFrame>> _pendingRoster = {};

  /// Nối đuôi các lần flush. Timer coalesce và flush sau `ready` có thể trùng
  /// nhau; chạy song song sẽ làm hai lượt refresh cùng ghi vào một provider.
  Future<void>? _flushChain;

  @override
  UserRealtimeState build() {
    ref.watch(realtimeSignedInProvider);
    ref.watch(sessionRevisionProvider);
    final expired = ref
        .read(realtimeSessionEventsProvider)
        .onExpired
        .listen((_) => _close());
    ref.onDispose(expired.cancel);
    ref.onDispose(() => _close(updateState: false));
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncConnection());
    return const UserRealtimeState();
  }

  void handleLifecycle(AppLifecycleState lifecycle) {
    _lifecycle = lifecycle;
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _close();
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        _syncConnection();
    }
  }

  bool get useLegacyStreams => RealtimeTransportMode.instance.useLegacy;

  @override
  set state(UserRealtimeState value) {
    super.state = value;
    // Người chờ OCR nằm ở tầng data, không đọc được provider. Đẩy chế độ hiệu
    // lực ra một chỗ chung để họ không chờ trên bus người dùng đã chết sau khi
    // `auto` rơi về legacy.
    RealtimeTransportMode.instance.setLegacyFallback(value.legacyFallback);
  }

  @override
  UserRealtimeState get state => super.state;

  Future<void> _syncConnection() async {
    final signedIn = ref.read(realtimeSignedInProvider);
    if (!signedIn || EnvConfig.realtimeMode == 'legacy') {
      _close();
      state = const UserRealtimeState(legacyFallback: true);
      return;
    }
    if (_lifecycle == AppLifecycleState.paused ||
        _lifecycle == AppLifecycleState.hidden ||
        _lifecycle == AppLifecycleState.detached) {
      return;
    }
    await _connect();
  }

  Future<void> _connect() async {
    if (_reconnectInFlight) return;
    _reconnectInFlight = true;
    _cancelToken?.cancel();
    final previous = _subscription;
    if (previous != null) {
      unawaited(previous.cancel());
    }
    _cancelToken = CancelToken();
    state = state.copyWith(transport: RealtimeTransport.connecting);
    try {
      final open = ref.read(userEventStreamOpenerProvider);
      _subscription = open(cancelToken: _cancelToken).listen(
        _onFrame,
        onError: _onError,
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (error) {
      await _onError(error);
    } finally {
      _reconnectInFlight = false;
    }
  }

  Future<void> _onError(Object error) async {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) {
        // `SseTransport` đã làm mới token và mở lại đúng một lần trước khi lỗi
        // này tới đây, nên 401 còn sót lại nghĩa là phiên hỏng thật. Không kết
        // nối lại: nếu không, kết nối realtime duy nhất sẽ chết lặng ở trạng
        // thái `connecting` trong khi UI vẫn tưởng người dùng đã đăng nhập.
        await ref.read(realtimeSessionRefresherProvider).endSession();
        _close();
        return;
      }
      if ((status == 404 || status == 501) &&
          !state.sawReady &&
          EnvConfig.realtimeMode != 'user') {
        _close();
        state = const UserRealtimeState(legacyFallback: true);
        return;
      }
      if (status == 429) {
        final retryAfter = int.tryParse(
          error.response?.headers.value('retry-after') ?? '',
        );
        _scheduleReconnect(retryAfterSeconds: retryAfter ?? 1);
        return;
      }
    }
    _scheduleReconnect();
  }

  void _onFrame(SseFrame frame) {
    RealtimeFrameBus.instance.add(frame);
    ref.read(realtimeFrameBusProvider).add(frame);
    switch (frame.event) {
      case 'ready':
        _attempt = 0;
        state = state.copyWith(
          transport: RealtimeTransport.resyncing,
          sawReady: true,
        );
        unawaited(_readyRefetch());
      case 'close':
        final reason = frame.data['reason'] as String?;
        if (reason == 'max_connection_age') {
          unawaited(_connect());
        } else {
          _scheduleReconnect();
        }
      case 'heartbeat':
        break;
      case 'roster':
        _bufferRoster(frame);
        _scheduleDispatch();
      case 'invalidate':
      case 'ocr.updated':
        _bufferInvalidate(frame);
        _scheduleDispatch();
    }
  }

  void _bufferRoster(SseFrame frame) {
    final groupId = frame.data['group_id'] as String? ?? '';
    final frames = _pendingRoster.putIfAbsent(groupId, () => []);
    if (frames.length >= 64) {
      _pendingRoster[groupId] = [];
      _dirtyAll = true;
      return;
    }
    frames.add(frame);
  }

  void _bufferInvalidate(SseFrame frame) {
    if (_dirty.length >= 256) {
      _dirtyAll = true;
      return;
    }
    final groupId = frame.data['group_id'] as String?;
    for (final interest in targetsFor(frame)) {
      _markDirty(interest, groupId: groupId);
    }
  }

  /// Đánh dấu một interest cần làm mới.
  ///
  /// Chỉ gắn [groupId] khi surface đó thực sự vá lẻ được; nếu không, hai nhóm
  /// cùng đổi sẽ thành hai đích riêng và kéo theo hai lần làm mới y hệt nhau.
  void _markDirty(RealtimeInterest interest, {String? groupId}) {
    final target = interest.patchGroup != null && groupId != null
        ? _DirtyTarget(interest.key, groupId)
        : _DirtyTarget(interest.key);
    _dirty[target] = ++_dirtySeq;
  }

  /// Hai màn hình danh sách nhóm: "Trang chủ" và "Danh sách nhóm".
  ///
  /// Cả hai gọi đúng cùng một `GET /groups` và hiển thị cùng một payload — số
  /// bill mở (`pending_bill_count`), số dư ròng, hoạt động gần nhất, trạng thái
  /// khóa — chỉ khác `limit`. Trả về cùng lúc để không thể làm mới một cái mà
  /// quên cái kia; đó chính là cách màn Danh sách nhóm giữ nguyên "1 bill mở"
  /// sau khi hóa đơn đã bị xóa.
  Iterable<RealtimeInterest> _groupSummaryLists(
    RealtimeInterestRegistry registry,
  ) => [
    ...registry.matching(surface: 'home.groups'),
    ...registry.matching(surface: 'groups.index'),
  ];

  /// Công khai seam nhỏ để regression test khóa bảng định tuyến invalidation.
  Iterable<RealtimeInterest> targetsFor(
    SseFrame frame, {
    RealtimeInterestRegistry? registryOverride,
  }) {
    final RealtimeInterestRegistry registry =
        registryOverride ?? ref.read(realtimeInterestRegistryProvider);
    if (frame.event == 'ocr.updated') {
      final groupId = frame.data['group_id'] as String?;
      final billId = frame.data['bill_id'] as String?;
      return [
        ...registry.matching(
          surface: 'ocr.waiter',
          groupId: groupId,
          billId: billId,
        ),
        ...registry.matching(
          surface: 'bill.detail',
          groupId: groupId,
          billId: billId,
        ),
        // Tab hóa đơn của nhóm hiện spinner "Đang quét..." dựa trên `ocr_status`
        // của từng dòng. Job OCR xong không đụng gì tới bảng `bills`, nên
        // `ocr.updated` là sự kiện DUY NHẤT báo spinner phải tắt: bỏ surface này
        // ra thì người tạo hóa đơn rời màn OCR là thẻ quay vòng tới hết phiên.
        ...registry.matching(surface: 'group.bills', groupId: groupId),
      ];
    }
    final type = frame.data['type'] as String? ?? '';
    final groupId = frame.data['group_id'] as String?;
    final resourceId = frame.data['resource_id'] as String?;
    switch (type) {
      case 'bill.created':
      case 'bill.content_changed':
      case 'bill.reviewed':
        return [
          ...registry.matching(
            surface: 'bill.detail',
            groupId: groupId,
            billId: resourceId,
          ),
          ...registry.matching(surface: 'group.bills', groupId: groupId),
          ..._groupSummaryLists(registry),
          ...registry.matching(surface: 'home.activities'),
        ];
      case 'bill.deleted':
      case 'bill.finalized':
      case 'bill.voided':
        return [
          ...registry.matching(
            surface: 'bill.detail',
            groupId: groupId,
            billId: resourceId,
          ),
          ...registry.matching(surface: 'group.bills', groupId: groupId),
          ...registry.matching(surface: 'group.debts', groupId: groupId),
          ...registry.matching(surface: 'group.detail', groupId: groupId),
          ...registry.matching(surface: 'settlement.overview'),
          ..._groupSummaryLists(registry),
          ...registry.matching(surface: 'home.activities'),
        ];
      case 'group.bill_submission_locked':
        return [
          ...registry.matching(surface: 'group.detail', groupId: groupId),
          ...registry.matching(surface: 'group.roster', groupId: groupId),
          ..._groupSummaryLists(registry),
        ];
      case 'home.balance_changed':
        return [
          ...registry.matching(surface: 'settlement.overview'),
          ..._groupSummaryLists(registry),
        ];
      case 'group.debts_changed':
        return [
          ...registry.matching(surface: 'group.debts', groupId: groupId),
          ...registry.matching(surface: 'group.detail', groupId: groupId),
        ];
      case 'bill.settlement_changed':
        return [
          ...registry.matching(
            surface: 'bill.detail',
            groupId: groupId,
            billId: resourceId,
          ),
          ...registry.matching(surface: 'group.bills', groupId: groupId),
        ];
      case 'settlement.payment_changed':
        return registry.matching(surface: 'settlement.overview');
      case 'settlement.debt_reminded':
        return [
          ...registry.matching(surface: 'settlement.overview'),
          ...registry.matching(surface: 'group.debts', groupId: groupId),
        ];
      case 'group.activity_changed':
        return [
          ...registry.matching(surface: 'group.activities', groupId: groupId),
          ...registry.matching(surface: 'home.activities'),
        ];
      default:
        return _groupSummaryLists(registry);
    }
  }

  void _scheduleDispatch() {
    _coalesceTimer?.cancel();
    _coalesceTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_flush());
    });
  }

  Future<void> _readyRefetch() async {
    state = state.copyWith(transport: RealtimeTransport.resyncing);
    _dirtyAll = true;
    await _flush();
    // `live` chỉ khi đã hàn xong: còn interest bẩn nghĩa là còn màn hình đang
    // hiển thị dữ liệu cũ, và một lượt thử lại đã được hẹn.
    state = state.copyWith(
      transport: _dirty.isEmpty
          ? RealtimeTransport.live
          : RealtimeTransport.resyncing,
    );
  }

  /// Nối đuôi một lượt flush. Trả về future hoàn tất khi lượt đó xong.
  Future<void> _flush() {
    final queued = (_flushChain ?? Future<void>.value()).then(
      (_) => _runFlush(),
    );
    _flushChain = queued;
    return queued.whenComplete(() {
      if (identical(_flushChain, queued)) _flushChain = null;
    });
  }

  Future<void> _runFlush() async {
    final registry = ref.read(realtimeInterestRegistryProvider);

    // Delta roster áp thẳng tại chỗ: không có lời gọi mạng nào để hỏng, nên
    // không có gì phải giữ lại để thử lại.
    final roster = Map<String, List<SseFrame>>.from(_pendingRoster);
    _pendingRoster.clear();
    for (final entry in roster.entries) {
      for (final interest in registry.matching(
        surface: 'group.roster',
        groupId: entry.key,
      )) {
        for (final frame in entry.value) {
          interest.applyRoster?.call(frame.data);
        }
      }
      for (final extra in [
        ..._groupSummaryLists(registry),
        ...registry.matching(surface: 'home.activities'),
      ]) {
        // Roster đổi có thể thêm hoặc bớt cả một nhóm khỏi danh sách, nên phải
        // làm mới cả surface chứ không vá lẻ một dòng.
        _markDirty(extra);
      }
    }

    if (_dirtyAll) {
      _dirtyAll = false;
      for (final interest in registry.all) {
        _markDirty(interest);
      }
    }
    if (_dirty.isEmpty) {
      _dirtyAttempt = 0;
      return;
    }

    var anyFailed = false;
    for (final target in _dirty.keys.toList()) {
      final markedAt = _dirty[target];
      if (markedAt == null) continue;
      final key = target.key;
      final matches = registry.matching(
        surface: key.surface,
        groupId: key.groupId,
        billId: key.billId,
      );
      if (matches.isEmpty) {
        // Màn hình đã đóng: không còn ai để làm mới, và giữ lại chỉ làm bẩn mãi.
        _dirty.remove(target);
        continue;
      }
      var refreshed = true;
      for (final interest in matches) {
        try {
          final patchGroup = interest.patchGroup;
          final groupId = target.groupId;
          if (patchGroup != null && groupId != null) {
            await patchGroup(groupId);
          } else {
            await interest.refresh?.call();
          }
        } catch (_) {
          // Giữ trạng thái tốt cuối cùng của provider và thử lại sau.
          refreshed = false;
        }
      }
      if (!refreshed) {
        anyFailed = true;
        continue;
      }
      // Chỉ xóa nếu không có invalidation mới nào tới trong lúc chờ: nếu có, lần
      // đánh dấu mới hơn phải được phục vụ bằng một lượt làm mới riêng.
      if (_dirty[target] == markedAt) {
        _dirty.remove(target);
      }
    }

    if (anyFailed || _dirty.isNotEmpty) {
      _scheduleDirtyRetry();
    } else {
      _dirtyAttempt = 0;
    }
  }

  /// Thử lại các interest còn bẩn theo đúng backoff của kết nối.
  void _scheduleDirtyRetry() {
    if (_dirty.isEmpty) return;
    final base =
        _backoffSeconds[min(_dirtyAttempt, _backoffSeconds.length - 1)];
    _dirtyAttempt++;
    final jittered = base * (0.7 + _random.nextDouble() * 0.6);
    _dirtyRetryTimer?.cancel();
    _dirtyRetryTimer = Timer(
      Duration(milliseconds: (jittered * 1000).round()),
      () => unawaited(_flush()),
    );
  }

  void _scheduleReconnect({int? retryAfterSeconds}) {
    if (state.legacyFallback) return;
    state = state.copyWith(transport: RealtimeTransport.backoff);
    _attempt++;
    final Duration delay;
    if (retryAfterSeconds != null) {
      // `Retry-After` là cửa sổ server yêu cầu, không phải gợi ý: jitter hai
      // chiều sẽ cho phép thử lại sớm hơn và ăn tiếp một 429 nữa. Chỉ cộng thêm
      // một ít, không bao giờ trừ đi.
      delay =
          Duration(seconds: retryAfterSeconds) +
          Duration(milliseconds: _random.nextInt(500));
    } else {
      final base =
          _backoffSeconds[min(_attempt - 1, _backoffSeconds.length - 1)];
      final jittered = base * (0.7 + _random.nextDouble() * 0.6);
      delay = Duration(milliseconds: (jittered * 1000).round());
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => _connect());
  }

  void _close({bool updateState = true}) {
    _reconnectTimer?.cancel();
    _coalesceTimer?.cancel();
    _dirtyRetryTimer?.cancel();
    _subscription?.cancel();
    _cancelToken?.cancel();
    _subscription = null;
    _cancelToken = null;
    if (updateState && state.transport != RealtimeTransport.signedOut) {
      state = state.copyWith(transport: RealtimeTransport.signedOut);
    }
  }
}

/// Một đích cần làm mới: surface, kèm nhóm cụ thể khi surface đó vá lẻ được.
///
/// [groupId] null nghĩa là làm mới toàn bộ surface — đó là điều luôn xảy ra sau
/// `ready`, khi tràn bộ đếm, và với mọi surface không khai báo `patchGroup`.
class _DirtyTarget {
  const _DirtyTarget(this.key, [this.groupId]);

  final RealtimeInterestKey key;
  final String? groupId;

  @override
  bool operator ==(Object other) =>
      other is _DirtyTarget && other.key == key && other.groupId == groupId;

  @override
  int get hashCode => Object.hash(key, groupId);
}
