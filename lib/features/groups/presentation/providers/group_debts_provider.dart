import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/session/session_scope.dart';
import '../../../../core/realtime/realtime_interest.dart';
import '../../../../core/realtime/register_realtime_interest.dart';
import '../../../settlement/presentation/providers/settlement_controller.dart';
import '../../data/models/group_debt_mapper.dart';
import '../../domain/entities/group_debt_entity.dart';
import 'group_roster_provider.dart';

class GroupDebtsState extends Equatable {
  const GroupDebtsState({
    this.debts = const [],
    this.matrix = const [],
    this.debtIdsByCounterpart = const {},
    this.netBalanceByMember = const {},
    this.isLoading = true,
    this.errorMessage,
  });

  final List<GroupDebtEntity> debts;
  final List<DebtMatrixRow> matrix;
  final Map<String, List<String>> debtIdsByCounterpart;

  /// Số dư ròng theo `membership_id`, cùng công thức với backend.
  final Map<String, int> netBalanceByMember;
  final bool isLoading;
  final String? errorMessage;

  int get outstandingTotal => matrix.fold(0, (sum, row) => sum + row.amount);

  /// Số dư ròng của tôi suy ra từ chính các khoản đang hiển thị: dương = được
  /// nhận lại, âm = còn nợ.
  int get myNetBalance => debts.fold(
    0,
    (sum, debt) =>
        sum +
        (debt.direction == DebtDirection.owesMe ? debt.amount : -debt.amount),
  );

  @override
  List<Object?> get props => [debts, matrix, isLoading, errorMessage];
}

/// Công nợ thật của một nhóm (`GET /api/v1/groups/{id}/debts`), đã gom theo
/// từng người để khớp với cách tab Công nợ nói chuyện.
class GroupDebtsNotifier extends StateNotifier<GroupDebtsState> {
  GroupDebtsNotifier(this._ref, this._groupId)
    : super(const GroupDebtsState()) {
    load();
  }

  final Ref _ref;
  final String _groupId;

  Future<void> load() async {
    if (_groupId.isEmpty) {
      state = const GroupDebtsState(isLoading: false);
      return;
    }
    state = GroupDebtsState(
      debts: state.debts,
      matrix: state.matrix,
      debtIdsByCounterpart: state.debtIdsByCounterpart,
      netBalanceByMember: state.netBalanceByMember,
    );

    try {
      final rows = await _ref
          .read(settlementRemoteDataSourceProvider)
          .listDebts(_groupId);
      if (!mounted) return;

      // membership_id của tôi đến từ roster (cùng nguồn với tab Thành viên).
      final callerMembershipId = _ref
          .read(groupRosterProvider(_groupId))
          .callerMembershipId;

      final view = buildGroupDebtsView(
        raw: rows.map(RawGroupDebt.fromJson).toList(),
        callerMembershipId: callerMembershipId,
      );
      state = GroupDebtsState(
        debts: view.debts,
        matrix: view.matrix,
        debtIdsByCounterpart: view.debtIdsByCounterpart,
        netBalanceByMember: view.netBalanceByMember,
        isLoading: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = GroupDebtsState(
        isLoading: false,
        errorMessage: 'Không tải được công nợ của nhóm.',
      );
    }
  }
}

final groupDebtsProvider = StateNotifierProvider.autoDispose
    .family<GroupDebtsNotifier, GroupDebtsState, String>((ref, groupId) {
      ref.watch(sessionRevisionProvider);
      // Chờ roster có callerMembershipId trước khi gom nợ: thiếu nó thì mọi
      // khoản đều bị coi là "của người khác" và tab hiện rỗng.
      ref.watch(
        groupRosterProvider(groupId).select((s) => s.callerMembershipId),
      );
      final notifier = GroupDebtsNotifier(ref, groupId);
      registerRealtimeInterest(
        ref,
        key: RealtimeInterestKey.groupDebts(groupId),
        refresh: notifier.load,
      );
      return notifier;
    });
