import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../app/session/session_scope.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.unreadCount = 0,
    this.error,
  });

  final List<NotificationEntity> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int unreadCount;
  final String? error;

  NotificationsState copyWith({
    List<NotificationEntity>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? unreadCount,
    String? error,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        items,
        isLoading,
        isLoadingMore,
        hasMore,
        currentPage,
        totalPages,
        totalItems,
        unreadCount,
        error,
      ];
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    loadInitial();
  }

  static const int pageSize = 20;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true);

    try {
      final dio = getIt<Dio>();

      // Gọi song song danh sách trang 1 và số lượng chưa đọc
      final responses = await Future.wait([
        dio.get(
          ApiEndpoints.notifications,
          queryParameters: {'page': 1, 'page_size': pageSize},
        ),
        dio.get(ApiEndpoints.notificationsUnreadCount),
      ]);

      final notifResp = responses[0];
      final unreadResp = responses[1];

      List<NotificationEntity> items = [];
      int totalPages = 1;
      int totalItems = 0;

      if (notifResp.data is Map<String, dynamic>) {
        final body = notifResp.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        final rawItems = data['items'] as List? ?? [];
        final meta = data['meta'] as Map<String, dynamic>? ?? {};

        items = rawItems
            .map((item) => NotificationEntity.fromJson(item as Map<String, dynamic>))
            .toList();

        totalPages = meta['total_pages'] as int? ?? 1;
        totalItems = meta['total_items'] as int? ?? items.length;
      }

      int unreadCount = 0;
      if (unreadResp.data is Map<String, dynamic>) {
        final body = unreadResp.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        unreadCount = data['unread_count'] as int? ?? 0;
      }

      state = state.copyWith(
        items: items,
        isLoading: false,
        currentPage: 1,
        totalPages: totalPages,
        totalItems: totalItems,
        hasMore: 1 < totalPages,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final dio = getIt<Dio>();

      final responses = await Future.wait([
        dio.get(
          ApiEndpoints.notifications,
          queryParameters: {'page': 1, 'page_size': pageSize},
        ),
        dio.get(ApiEndpoints.notificationsUnreadCount),
      ]);

      final notifResp = responses[0];
      final unreadResp = responses[1];

      List<NotificationEntity> items = [];
      int totalPages = 1;
      int totalItems = 0;

      if (notifResp.data is Map<String, dynamic>) {
        final body = notifResp.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        final rawItems = data['items'] as List? ?? [];
        final meta = data['meta'] as Map<String, dynamic>? ?? {};

        items = rawItems
            .map((item) => NotificationEntity.fromJson(item as Map<String, dynamic>))
            .toList();

        totalPages = meta['total_pages'] as int? ?? 1;
        totalItems = meta['total_items'] as int? ?? items.length;
      }

      int unreadCount = 0;
      if (unreadResp.data is Map<String, dynamic>) {
        final body = unreadResp.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        unreadCount = data['unread_count'] as int? ?? 0;
      }

      state = state.copyWith(
        items: items,
        currentPage: 1,
        totalPages: totalPages,
        totalItems: totalItems,
        hasMore: 1 < totalPages,
        unreadCount: unreadCount,
      );
    } catch (_) {
      state = state.copyWith(
        error: 'Không thể làm mới thông báo. Vui lòng kiểm tra kết nối mạng.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final dio = getIt<Dio>();
      final response = await dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': nextPage, 'page_size': pageSize},
      );

      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        final rawItems = data['items'] as List? ?? [];
        final meta = data['meta'] as Map<String, dynamic>? ?? {};

        final newItems = rawItems
            .map((item) => NotificationEntity.fromJson(item as Map<String, dynamic>))
            .toList();

        final totalPages = meta['total_pages'] as int? ?? state.totalPages;
        final totalItems = meta['total_items'] as int? ?? state.totalItems;

        state = state.copyWith(
          items: [...state.items, ...newItems],
          isLoadingMore: false,
          currentPage: nextPage,
          totalPages: totalPages,
          totalItems: totalItems,
          hasMore: nextPage < totalPages,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic Update
    final index = state.items.indexWhere((n) => n.id == id);
    if (index != -1 && !state.items[index].isRead) {
      final previousItems = state.items;
      final previousUnread = state.unreadCount;

      final updatedList = List<NotificationEntity>.from(state.items);
      updatedList[index] = updatedList[index].copyWith(readAt: DateTime.now());
      final newUnread = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
      state = state.copyWith(items: updatedList, unreadCount: newUnread);

      try {
        final dio = getIt<Dio>();
        await dio.patch(ApiEndpoints.notificationRead(id));
      } catch (_) {
        // Rollback lại dữ liệu cũ khi API thất bại
        state = state.copyWith(
          items: previousItems,
          unreadCount: previousUnread,
        );
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0 && state.items.every((n) => n.isRead)) {
      return;
    }

    final previousItems = state.items;
    final previousUnread = state.unreadCount;

    final now = DateTime.now();
    final updatedList = state.items.map((n) => n.isRead ? n : n.copyWith(readAt: now)).toList();
    state = state.copyWith(items: updatedList, unreadCount: 0);

    try {
      final dio = getIt<Dio>();
      await dio.post(ApiEndpoints.notificationsReadAll);
    } catch (_) {
      // Rollback lại dữ liệu cũ khi API thất bại
      state = state.copyWith(
        items: previousItems,
        unreadCount: previousUnread,
      );
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  ref.watch(sessionRevisionProvider);
  return NotificationsNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
