import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/session/session_scope.dart';
import '../../../../core/error/failures.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/group_activity_entity.dart';
import '../../domain/usecases/list_activities_usecase.dart';

class GroupActivitiesState extends Equatable {
  const GroupActivitiesState({
    this.activities = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<GroupActivityEntity> activities;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  @override
  List<Object?> get props => [
    activities,
    nextCursor,
    isLoading,
    isLoadingMore,
    errorMessage,
  ];
}

/// Nhật ký hoạt động thật của nhóm (`GET /api/v1/groups/{id}/activities`).
class GroupActivitiesNotifier extends StateNotifier<GroupActivitiesState> {
  GroupActivitiesNotifier(this._groupId)
    : super(const GroupActivitiesState(isLoading: true)) {
    load();
  }

  final String _groupId;

  static const int _pageSize = 20;

  Future<void> load() async {
    if (_groupId.isEmpty) {
      state = const GroupActivitiesState();
      return;
    }
    state = GroupActivitiesState(activities: state.activities, isLoading: true);
    await _fetch(cursor: null, append: false);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    state = GroupActivitiesState(
      activities: state.activities,
      nextCursor: state.nextCursor,
      isLoadingMore: true,
    );
    await _fetch(cursor: state.nextCursor, append: true);
  }

  Future<void> _fetch({required String? cursor, required bool append}) async {
    final result = await getIt<ListActivitiesUseCase>().call(
      ListActivitiesParams(groupId: _groupId, limit: _pageSize, cursor: cursor),
    );
    if (!mounted) return;

    result.match(
      (Failure failure) {
        state = GroupActivitiesState(
          activities: state.activities,
          nextCursor: state.nextCursor,
          errorMessage: failure.message,
        );
      },
      (page) {
        final seen = append ? {for (final a in state.activities) a.id} : <String>{};
        final merged = append
            ? [...state.activities, ...page.items.where((a) => !seen.contains(a.id))]
            : page.items;
        state = GroupActivitiesState(
          activities: merged,
          nextCursor: page.nextCursor,
        );
      },
    );
  }
}

final groupActivitiesProvider =
    StateNotifierProvider.autoDispose
        .family<GroupActivitiesNotifier, GroupActivitiesState, String>((
          ref,
          groupId,
        ) {
          ref.watch(sessionRevisionProvider);
          return GroupActivitiesNotifier(groupId);
        });
