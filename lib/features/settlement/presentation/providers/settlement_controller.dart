import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/realtime/realtime_interest.dart';
import '../../../../core/realtime/register_realtime_interest.dart';
import '../../../../di/injection.dart';
import '../../data/datasources/settlement_remote_data_source.dart';
import '../../data/repositories/settlement_repository_impl.dart';
import '../../domain/entities/settlement_entities.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../../../app/session/session_scope.dart';

enum SettlementTab { payable, receivable, bills, history }

const _unsetError = Object();

class SettlementState extends Equatable {
  const SettlementState({
    this.currentTab = SettlementTab.payable,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isMutating = false,
    this.overview,
    this.payableDebts = const [],
    this.receivableDebts = const [],
    this.groupedDebts = const [],
    this.pendingProofs = const [],
    this.submittedProofs = const [],
    this.settledHistory = const [],
    this.bills = const [],
    this.selectedDebtIds = const {},
    this.remindedCooldowns = const {},
    this.errorMessage,
  });

  final SettlementTab currentTab;
  final bool isLoading;

  /// Đang nạp lại ngầm (realtime). Khác [isLoading] ở chỗ màn hình vẫn giữ
  /// nguyên nội dung cũ thay vì sập thành spinner.
  final bool isRefreshing;

  final bool isMutating;
  final SettlementOverviewEntity? overview;
  final List<DebtItemEntity> payableDebts;
  final List<DebtItemEntity> receivableDebts;
  final List<SingleCreditorBatchEntity> groupedDebts;
  final List<ProofDetailEntity> pendingProofs;
  final List<ProofDetailEntity> submittedProofs;
  final List<SettledHistoryEntity> settledHistory;
  final List<SettlementBillEntity> bills;
  final Set<String> selectedDebtIds;
  final Map<String, int> remindedCooldowns;
  final String? errorMessage;

  SettlementState copyWith({
    SettlementTab? currentTab,
    bool? isLoading,
    bool? isRefreshing,
    bool? isMutating,
    SettlementOverviewEntity? overview,
    List<DebtItemEntity>? payableDebts,
    List<DebtItemEntity>? receivableDebts,
    List<SingleCreditorBatchEntity>? groupedDebts,
    List<ProofDetailEntity>? pendingProofs,
    List<ProofDetailEntity>? submittedProofs,
    List<SettledHistoryEntity>? settledHistory,
    List<SettlementBillEntity>? bills,
    Set<String>? selectedDebtIds,
    Map<String, int>? remindedCooldowns,
    Object? errorMessage = _unsetError,
  }) {
    return SettlementState(
      currentTab: currentTab ?? this.currentTab,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMutating: isMutating ?? this.isMutating,
      overview: overview ?? this.overview,
      payableDebts: payableDebts ?? this.payableDebts,
      receivableDebts: receivableDebts ?? this.receivableDebts,
      groupedDebts: groupedDebts ?? this.groupedDebts,
      pendingProofs: pendingProofs ?? this.pendingProofs,
      submittedProofs: submittedProofs ?? this.submittedProofs,
      settledHistory: settledHistory ?? this.settledHistory,
      bills: bills ?? this.bills,
      selectedDebtIds: selectedDebtIds ?? this.selectedDebtIds,
      remindedCooldowns: remindedCooldowns ?? this.remindedCooldowns,
      errorMessage: identical(errorMessage, _unsetError)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    currentTab,
    isLoading,
    isRefreshing,
    isMutating,
    overview,
    payableDebts,
    receivableDebts,
    groupedDebts,
    pendingProofs,
    submittedProofs,
    settledHistory,
    bills,
    selectedDebtIds,
    remindedCooldowns,
    errorMessage,
  ];
}

final settlementRemoteDataSourceProvider = Provider<SettlementRemoteDataSource>(
  (ref) => SettlementRemoteDataSourceImpl(
    getIt.isRegistered<Dio>() ? getIt<Dio>() : Dio(),
  ),
);

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  // Repository giữ cache dữ liệu nhóm giữa các lượt nạp. Không gắn vào phiên
  // thì cache của người dùng cũ còn nằm trong bộ nhớ sau khi đăng xuất.
  ref.watch(sessionRevisionProvider);
  return SettlementRepositoryImpl(
    ref.watch(settlementRemoteDataSourceProvider),
  );
});

final settlementControllerProvider =
    StateNotifierProvider<SettlementController, SettlementState>((ref) {
      ref.watch(sessionRevisionProvider);
      final controller = SettlementController(
        ref.watch(settlementRepositoryProvider),
      );
      registerRealtimeInterest(
        ref,
        key: RealtimeInterestKey.settlementOverview(),
        refresh: () => controller.loadData(background: true),
        // Sự kiện realtime luôn kèm `group_id`. Có patchGroup thì owner gom
        // đích theo từng nhóm và chỉ nạp lại nhóm đó, thay vì quét lại cả N
        // nhóm cho một khoản nợ vừa đổi ở đúng một nhóm.
        patchGroup: controller.patchGroupData,
      );
      return controller;
    });

class SettlementController extends StateNotifier<SettlementState> {
  SettlementController(
    this._repository, {
    this.reminderCooldownSeconds = 24 * 3600,
    this.countdownInterval = const Duration(seconds: 1),
  }) : super(const SettlementState()) {
    unawaited(loadData());
  }

  final SettlementRepository _repository;
  final int reminderCooldownSeconds;
  final Duration countdownInterval;
  Timer? _countdownTimer;

  /// Nạp lại toàn bộ dữ liệu đối soát.
  ///
  /// [background] dành cho lượt làm mới do realtime kích hoạt: giữ nguyên nội
  /// dung đang hiển thị thay vì bật [SettlementState.isLoading], thứ mà
  /// SettlementPage dùng để thay cả trang bằng một spinner. Không tách ra thì
  /// mỗi lần ai đó trong nhóm xác nhận thanh toán là màn hình người khác chớp
  /// trắng và danh sách cuộn về đầu.
  Future<void> loadData({
    bool rethrowOnError = false,
    bool background = false,
    String? onlyGroupId,
  }) async {
    if (!mounted) return;
    final hadData = state.overview != null;
    final previousSelection = state.selectedDebtIds;
    // Lần đầu chưa có gì để giữ thì vẫn phải hiện spinner.
    final quiet = background && hadData;
    state = state.copyWith(
      isLoading: !quiet,
      isRefreshing: quiet,
      errorMessage: null,
    );
    try {
      final data = await _repository.loadSettlement(onlyGroupId: onlyGroupId);
      if (!mounted) return;
      final selectableIds = data.payableDebts
          .where((debt) => debt.status == DebtStatus.awaiting)
          .map((debt) => debt.id)
          .toSet();
      // Lần tải đầu chọn sẵn tất cả; những lần sau giữ nguyên lựa chọn của user
      // và chỉ bỏ đi các khoản không còn chọn được nữa.
      final selection = hadData
          ? previousSelection.intersection(selectableIds)
          : selectableIds;

      final now = DateTime.now();
      final calculatedCooldowns = Map<String, int>.from(
        state.remindedCooldowns,
      );
      for (final debt in data.receivableDebts) {
        if (debt.lastRemindedAt != null) {
          final elapsed = now.difference(debt.lastRemindedAt!).inSeconds;
          final remaining = reminderCooldownSeconds - elapsed;
          if (remaining > 0) {
            calculatedCooldowns[debt.id] = remaining;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        overview: data.overview,
        payableDebts: data.payableDebts,
        receivableDebts: data.receivableDebts,
        groupedDebts: data.groupedDebts,
        pendingProofs: data.pendingProofs,
        submittedProofs: data.submittedProofs,
        settledHistory: data.settledHistory,
        bills: data.bills,
        selectedDebtIds: selection,
        remindedCooldowns: calculatedCooldowns,
        errorMessage: null,
      );
      if (calculatedCooldowns.isNotEmpty) {
        _startCountdown();
      }
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: _errorMessage(error),
        );
      }
      if (rethrowOnError) rethrow;
    }
  }

  /// Làm mới ngầm, chỉ nạp lại nhóm [groupId].
  ///
  /// Dữ liệu đối soát là tổng hợp trên mọi nhóm nên vẫn phải dựng lại toàn bộ
  /// state; cái tiết kiệm được là các lời gọi API cho những nhóm không đổi.
  Future<void> patchGroupData(String groupId) =>
      loadData(background: true, onlyGroupId: groupId);

  void setTab(SettlementTab tab) {
    if (!mounted || state.currentTab == tab) return;
    state = state.copyWith(currentTab: tab);
  }

  void toggleDebtSelection(String debtId) {
    final current = Set<String>.from(state.selectedDebtIds);
    current.contains(debtId) ? current.remove(debtId) : current.add(debtId);
    state = state.copyWith(selectedDebtIds: current);
  }

  void setCreditorDebtsSelection(
    String groupId,
    String creditorId,
    bool selectAll,
  ) {
    final current = Set<String>.from(state.selectedDebtIds);
    final matches = state.groupedDebts.where(
      (group) => group.groupId == groupId && group.creditorId == creditorId,
    );
    if (matches.isEmpty) return;
    for (final debt in matches.first.debts) {
      selectAll ? current.add(debt.id) : current.remove(debt.id);
    }
    state = state.copyWith(selectedDebtIds: current);
  }

  Future<PaymentQrEntity> generatePaymentQr({
    required String groupId,
    required String creditorId,
    required List<String> debtIds,
  }) {
    final pending = state.payableDebts.any(
      (debt) =>
          debt.groupId == groupId &&
          debtIds.contains(debt.id) &&
          debt.status == DebtStatus.pendingConfirmation,
    );
    if (pending) {
      return Future.error(StateError('Khoản nợ đang chờ xác nhận thanh toán.'));
    }
    return _mutate(
      () => _repository.generatePaymentQr(
        groupId: groupId,
        creditorId: creditorId,
        debtIds: debtIds,
      ),
      reload: false,
    );
  }

  Future<void> confirmPendingPayment({
    required String groupId,
    required String paymentId,
  }) {
    return _mutate(
      () => _repository.confirmPayment(groupId: groupId, paymentId: paymentId),
    );
  }

  Future<void> rejectPendingPayment({
    required String groupId,
    required String paymentId,
    required String reason,
  }) {
    return _mutate(
      () => _repository.rejectPayment(
        groupId: groupId,
        paymentId: paymentId,
        reason: reason,
      ),
    );
  }

  Future<void> submitProof({
    required String groupId,
    required String paymentId,
    required ProofUploadEntity image,
    String? note,
  }) {
    return _mutate(
      () => _repository.submitProof(
        groupId: groupId,
        paymentId: paymentId,
        image: image,
        note: note,
      ),
    );
  }

  Future<void> remindDebt({
    required String groupId,
    required String debtId,
  }) async {
    final currentCooldown = state.remindedCooldowns[debtId] ?? 0;
    if (currentCooldown > 0) {
      return;
    }

    try {
      await _mutate(
        () => _repository.remindDebt(groupId: groupId, debtId: debtId),
      );
      if (!mounted) return;

      final cooldowns = Map<String, int>.from(state.remindedCooldowns)
        ..[debtId] = reminderCooldownSeconds;
      state = state.copyWith(remindedCooldowns: cooldowns, errorMessage: null);
      _startCountdown();
    } catch (error) {
      if (mounted &&
          error is Failure &&
          error.code == 'REMINDER_RATE_LIMITED') {
        final cooldowns = Map<String, int>.from(state.remindedCooldowns)
          ..[debtId] = reminderCooldownSeconds;
        state = state.copyWith(
          remindedCooldowns: cooldowns,
          errorMessage: null,
        );
        _startCountdown();
        return;
      }
      rethrow;
    }
  }

  Future<T> _mutate<T>(
    Future<T> Function() action, {
    bool reload = true,
  }) async {
    if (state.isMutating) {
      const message = 'Một thao tác khác đang được xử lý';
      state = state.copyWith(errorMessage: message);
      throw StateError(message);
    }
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final result = await action();
      if (reload) await loadData();
      return result;
    } catch (error) {
      if (mounted) state = state.copyWith(errorMessage: _errorMessage(error));
      rethrow;
    } finally {
      if (mounted) state = state.copyWith(isMutating: false);
    }
  }

  /// Nhịp đếm ngược, chọn theo khoảng còn lại lớn nhất.
  ///
  /// `TimeFormatter.formatRemainingCooldown` chỉ hiện tới đơn vị giờ khi còn
  /// trên một tiếng, và tới đơn vị phút khi còn trên một phút. Cooldown nhắc nợ
  /// dài 24 tiếng, nên nhịp mỗi giây nghĩa là 86.400 lần phát state để dòng chữ
  /// đổi đúng 24 lần — mỗi lần phát là một lần dựng lại cả màn Đối soát.
  Duration _countdownTickFor(int maxRemaining) {
    if (maxRemaining > 3600) return const Duration(minutes: 1);
    if (maxRemaining > 60) return const Duration(seconds: 10);
    return countdownInterval;
  }

  void _startCountdown() {
    if (_countdownTimer != null) return;
    _scheduleCountdownTick();
  }

  void _scheduleCountdownTick() {
    final cooldowns = state.remindedCooldowns;
    if (cooldowns.isEmpty) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      return;
    }
    final maxRemaining = cooldowns.values.reduce((a, b) => a > b ? a : b);
    final tick = _countdownTickFor(maxRemaining);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(tick, (timer) {
      if (!mounted) {
        timer.cancel();
        _countdownTimer = null;
        return;
      }

      // Nhịp dưới một giây (chỉ test dùng) làm `inSeconds` bằng 0, và cooldown
      // sẽ không bao giờ giảm. Sàn ở 1 giây mỗi nhịp.
      final elapsed = tick.inSeconds > 0 ? tick.inSeconds : 1;
      final next = <String, int>{};
      for (final entry in state.remindedCooldowns.entries) {
        if (entry.value > elapsed) next[entry.key] = entry.value - elapsed;
      }
      state = state.copyWith(remindedCooldowns: next);

      if (next.isEmpty) {
        timer.cancel();
        _countdownTimer = null;
        return;
      }
      // Còn ít thời gian hơn thì chuyển sang nhịp dày hơn để giây cuối vẫn chạy.
      final maxLeft = next.values.reduce((a, b) => a > b ? a : b);
      if (_countdownTickFor(maxLeft) != tick) {
        _scheduleCountdownTick();
      }
    });
  }

  String _errorMessage(Object error) {
    if (error is Failure) return error.message;
    if (error is StateError) return error.message;
    return 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
