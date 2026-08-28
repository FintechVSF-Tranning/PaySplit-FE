// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/session/session_scope.dart';
import '../../../../core/error/failures.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/bulk_finalize_entity.dart';
import '../../domain/usecases/group_bill_close_usecases.dart';

/// Factory signature for generating UUID strings, injectable for tests.
typedef UuidFactory = String Function();

class GroupBillCloseState extends Equatable {
  const GroupBillCloseState({
    this.batch,
    this.isLoading = false,
    this.isStarting = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final BulkFinalizeBatchEntity? batch;
  final bool isLoading;

  /// True while the start-bulk-finalize request is in flight.
  final bool isStarting;
  final bool isLoadingMore;
  final String? errorMessage;

  GroupBillCloseState copyWith({
    BulkFinalizeBatchEntity? batch,
    bool? isLoading,
    bool? isStarting,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => GroupBillCloseState(
    batch: batch ?? this.batch,
    isLoading: isLoading ?? this.isLoading,
    isStarting: isStarting ?? this.isStarting,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    batch,
    isLoading,
    isStarting,
    isLoadingMore,
    errorMessage,
  ];
}

class GroupBillCloseNotifier extends StateNotifier<GroupBillCloseState>
    with WidgetsBindingObserver {
  GroupBillCloseNotifier({
    required this.groupId,
    required StartBulkFinalizeUseCase startUseCase,
    required GetBulkFinalizeUseCase getUseCase,
    UuidFactory? uuidFactory,
  }) : _startUseCase = startUseCase,
       _getUseCase = getUseCase,
       _uuidFactory = uuidFactory ?? _defaultUuid,
       super(const GroupBillCloseState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final String groupId;
  final StartBulkFinalizeUseCase _startUseCase;
  final GetBulkFinalizeUseCase _getUseCase;
  final UuidFactory _uuidFactory;

  Timer? _pollTimer;

  // --- Idempotency ---
  String? _startIdempotencyKey;

  // --- Backoff ---
  int _backoffStep = 0;
  static const _backoffDelays = [2, 4, 8, 15, 30]; // seconds

  // --- Lifecycle ---
  bool _isPaused = false;

  // --- Concurrency ---
  int _openGeneration = 0;

  static String _defaultUuid() => const Uuid().v4();

  Duration get _currentDelay => Duration(
    seconds: _backoffDelays[_backoffStep.clamp(0, _backoffDelays.length - 1)],
  );

  // ---------------------------------------------------------------------------
  // Start bulk finalize
  // ---------------------------------------------------------------------------

  Future<bool> start() async {
    if (state.isStarting) return false;
    _startIdempotencyKey ??= _uuidFactory();
    state = state.copyWith(isStarting: true, clearError: true);

    final result = await _startUseCase.call(
      StartBulkFinalizeParams(groupId, idempotencyKey: _startIdempotencyKey!),
    );
    if (!mounted) return false;

    if (result.isLeft()) {
      final failure = result.getLeft().toNullable()!;
      // Reset key on definitive business errors (4xx except 408, 429).
      if (_isDefinitiveFailure(failure)) _startIdempotencyKey = null;

      // BULK_FINALIZE_IN_PROGRESS → open the active batch instead.
      if (failure.code == 'BULK_FINALIZE_IN_PROGRESS') {
        String? batchId;
        if (failure is ServerFailure) {
          batchId = failure.details?['active_batch_id'];
        }
        if (batchId != null) {
          _startIdempotencyKey = null;
          state = state.copyWith(isStarting: false);
          await open(batchId);
          return true;
        }
      }

      state = state.copyWith(isStarting: false, errorMessage: failure.message);
      return false;
    } else {
      final batch = result.getOrElse((_) => throw StateError('unreachable'));
      _startIdempotencyKey = null;
      state = GroupBillCloseState(batch: batch);
      await open(batch.id);
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Open / poll a batch
  // ---------------------------------------------------------------------------

  Future<void> open(String batchId, {bool quiet = false}) async {
    final gen = ++_openGeneration;
    if (!quiet) state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getUseCase.call(
      GetBulkFinalizeParams(groupId, batchId),
    );
    if (!mounted || gen != _openGeneration) return; // stale → discard

    result.match(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (batch) {
        state = GroupBillCloseState(batch: batch);
        _backoffStep = 0;
        _schedulePoll(batch);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Load more items (cursor pagination)
  // ---------------------------------------------------------------------------

  Future<void> loadMore() async {
    final current = state.batch;
    if (current == null || current.nextCursor == null || state.isLoadingMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _getUseCase.call(
      GetBulkFinalizeParams(groupId, current.id, cursor: current.nextCursor),
    );
    if (!mounted) return;

    result.match(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
        // Keep existing batch + items intact.
      ),
      (page) {
        // Use latest state.batch (not the stale `current`) in case a poll
        // arrived while this request was in flight.
        final latest = state.batch ?? current;
        state = GroupBillCloseState(
          batch: latest.copyWith(
            items: [...latest.items, ...page.items],
            nextCursor: page.nextCursor, // null on last page → sentinel handles
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Polling with backoff
  // ---------------------------------------------------------------------------

  void _schedulePoll(BulkFinalizeBatchEntity batch) {
    _pollTimer?.cancel();
    if (batch.isComplete || _isPaused) {
      if (batch.isComplete) _backoffStep = 0;
      return;
    }
    _pollTimer = Timer(_currentDelay, () => _poll(batch.id));
  }

  Future<void> _poll(String batchId) async {
    if (!mounted || _isPaused) return;

    final result = await _getUseCase.call(
      GetBulkFinalizeParams(groupId, batchId),
    );
    if (!mounted || _isPaused) return;

    result.match(
      (failure) {
        _backoffStep = (_backoffStep + 1).clamp(0, _backoffDelays.length - 1);
        // Keep existing batch, only surface error message.
        state = state.copyWith(errorMessage: failure.message);
        // Retry only if we already have a real batch.
        final existing = state.batch;
        if (existing != null && !existing.isComplete) {
          _schedulePoll(existing);
        }
      },
      (freshBatch) {
        _backoffStep = 0;
        final merged = _mergeItems(state.batch, freshBatch);
        state = GroupBillCloseState(batch: merged);
        _schedulePoll(merged);
      },
    );
  }

  /// Merge poll result (page 1) with existing items from loaded-more pages.
  /// Prevents poll from overwriting items the user has already scrolled to.
  BulkFinalizeBatchEntity _mergeItems(
    BulkFinalizeBatchEntity? existing,
    BulkFinalizeBatchEntity fresh,
  ) {
    // Different batch (e.g. notification opened batch B while viewing A).
    if (existing == null || existing.id != fresh.id) return fresh;
    if (existing.items.isEmpty) return fresh;

    final freshById = {for (final item in fresh.items) item.billId: item};
    final merged = <BulkFinalizeItemEntity>[];
    final seen = <String>{};

    // Fresh items first (page 1, latest status).
    for (final item in fresh.items) {
      merged.add(item);
      seen.add(item.billId);
    }
    // Existing items from loaded-more pages that aren't in fresh.
    for (final item in existing.items) {
      if (seen.contains(item.billId)) continue;
      // Update status if fresh has a newer version.
      merged.add(freshById[item.billId] ?? item);
      seen.add(item.billId);
    }

    return fresh.copyWith(items: merged, nextCursor: existing.nextCursor);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isPaused = true;
      _pollTimer?.cancel();
      _pollTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      final batch = this.state.batch;
      if (batch != null && !batch.isComplete) {
        _backoffStep = 0;
        _schedulePoll(batch);
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns true for definitive client errors where the request will never
  /// succeed with the same key (400, 403, 404, 422). Excludes transient errors
  /// (408 timeout, 429 rate limit, 5xx) where retry with the same key is safe.
  bool _isDefinitiveFailure(Failure f) {
    if (f is ServerFailure) {
      final sc = f.statusCode;
      return sc != null && sc >= 400 && sc < 500 && sc != 408 && sc != 429;
    }
    return f is ValidationFailure || f is UnauthorizedFailure;
  }
}

final groupBillCloseProvider = StateNotifierProvider.autoDispose
    .family<GroupBillCloseNotifier, GroupBillCloseState, String>((
      ref,
      groupId,
    ) {
      ref.watch(sessionRevisionProvider);
      return GroupBillCloseNotifier(
        groupId: groupId,
        startUseCase: getIt<StartBulkFinalizeUseCase>(),
        getUseCase: getIt<GetBulkFinalizeUseCase>(),
      );
    });
