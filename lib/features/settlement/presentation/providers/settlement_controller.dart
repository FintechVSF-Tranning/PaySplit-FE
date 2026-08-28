import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../di/injection.dart';
import '../../data/datasources/settlement_remote_data_source.dart';
import '../../data/repositories/settlement_repository_impl.dart';
import '../../domain/entities/settlement_entities.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../../../app/session/session_scope.dart';

enum SettlementTab { payable, receivable, bills, history }

const _unsetError = Object();

class SettlementState {
  const SettlementState({
    this.currentTab = SettlementTab.payable,
    this.isLoading = false,
    this.isMutating = false,
    this.overview,
    this.payableDebts = const [],
    this.receivableDebts = const [],
    this.groupedDebts = const [],
    this.pendingProofs = const [],
    this.settledHistory = const [],
    this.bills = const [],
    this.selectedDebtIds = const {},
    this.remindedCooldowns = const {},
    this.errorMessage,
  });

  final SettlementTab currentTab;
  final bool isLoading;
  final bool isMutating;
  final SettlementOverviewEntity? overview;
  final List<DebtItemEntity> payableDebts;
  final List<DebtItemEntity> receivableDebts;
  final List<SingleCreditorBatchEntity> groupedDebts;
  final List<ProofDetailEntity> pendingProofs;
  final List<SettledHistoryEntity> settledHistory;
  final List<SettlementBillEntity> bills;
  final Set<String> selectedDebtIds;
  final Map<String, int> remindedCooldowns;
  final String? errorMessage;

  SettlementState copyWith({
    SettlementTab? currentTab,
    bool? isLoading,
    bool? isMutating,
    SettlementOverviewEntity? overview,
    List<DebtItemEntity>? payableDebts,
    List<DebtItemEntity>? receivableDebts,
    List<SingleCreditorBatchEntity>? groupedDebts,
    List<ProofDetailEntity>? pendingProofs,
    List<SettledHistoryEntity>? settledHistory,
    List<SettlementBillEntity>? bills,
    Set<String>? selectedDebtIds,
    Map<String, int>? remindedCooldowns,
    Object? errorMessage = _unsetError,
  }) {
    return SettlementState(
      currentTab: currentTab ?? this.currentTab,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      overview: overview ?? this.overview,
      payableDebts: payableDebts ?? this.payableDebts,
      receivableDebts: receivableDebts ?? this.receivableDebts,
      groupedDebts: groupedDebts ?? this.groupedDebts,
      pendingProofs: pendingProofs ?? this.pendingProofs,
      settledHistory: settledHistory ?? this.settledHistory,
      bills: bills ?? this.bills,
      selectedDebtIds: selectedDebtIds ?? this.selectedDebtIds,
      remindedCooldowns: remindedCooldowns ?? this.remindedCooldowns,
      errorMessage: identical(errorMessage, _unsetError)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final settlementRemoteDataSourceProvider = Provider<SettlementRemoteDataSource>(
  (ref) => SettlementRemoteDataSourceImpl(
    getIt.isRegistered<Dio>() ? getIt<Dio>() : Dio(),
  ),
);

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepositoryImpl(
    ref.watch(settlementRemoteDataSourceProvider),
  );
});

final settlementControllerProvider =
    StateNotifierProvider<SettlementController, SettlementState>((ref) {
      ref.watch(sessionRevisionProvider);
      return SettlementController(ref.watch(settlementRepositoryProvider));
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

  Future<void> loadData({bool rethrowOnError = false}) async {
    if (!mounted) return;
    final hadData = state.overview != null;
    final previousSelection = state.selectedDebtIds;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.loadSettlement();
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
      final calculatedCooldowns = Map<String, int>.from(state.remindedCooldowns);
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
        overview: data.overview,
        payableDebts: data.payableDebts,
        receivableDebts: data.receivableDebts,
        groupedDebts: data.groupedDebts,
        pendingProofs: data.pendingProofs,
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
          errorMessage: _errorMessage(error),
        );
      }
      if (rethrowOnError) rethrow;
    }
  }

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
      if (mounted && error is Failure && error.code == 'REMINDER_RATE_LIMITED') {
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

  void _startCountdown() {
    _countdownTimer ??= Timer.periodic(countdownInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        _countdownTimer = null;
        return;
      }

      final next = <String, int>{};
      for (final entry in state.remindedCooldowns.entries) {
        if (entry.value > 1) next[entry.key] = entry.value - 1;
      }
      state = state.copyWith(remindedCooldowns: next);
      if (next.isEmpty) {
        timer.cancel();
        _countdownTimer = null;
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
