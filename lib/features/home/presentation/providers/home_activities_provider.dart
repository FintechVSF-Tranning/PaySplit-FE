import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/realtime/realtime_interest.dart';
import '../../../../core/realtime/register_realtime_interest.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/home_activity_entity.dart';
import 'home_groups_provider.dart';

final homeActivitiesProvider =
    FutureProvider.autoDispose<List<HomeActivityEntity>>((ref) async {
      registerRealtimeInterest(
        ref,
        key: RealtimeInterestKey.homeActivities(),
    refresh: () async {
      ref.invalidateSelf();
    },
      );
      final groups = await ref.watch(homeGroupsProvider.future);
      if (groups.isEmpty) {
        return const [];
      }

      try {
        final dio = getIt<Dio>();

        // Lấy hoạt động từ tối đa 3 nhóm song song
        final futures = groups.take(3).map((group) async {
          try {
            final response = await dio.get(
              '${ApiEndpoints.groups}/${group.id}/activities',
              queryParameters: {'limit': 2},
            );

            if (response.data is Map<String, dynamic>) {
              final rawData = response.data as Map<String, dynamic>;
              final data = rawData['data'] as Map<String, dynamic>? ?? rawData;
              final activitiesList = data['activities'] as List? ?? const [];

              return activitiesList
                  .map(
                    (a) => HomeActivityEntity.fromJson(
                      a as Map<String, dynamic>,
                      fallbackGroupId: group.id,
                      groupName: group.name,
                    ),
                  )
                  .toList();
            }
          } catch (_) {
            // Bỏ qua lỗi từng nhóm riêng lẻ
          }
          return <HomeActivityEntity>[];
        });

        final results = await Future.wait(futures);
        final allActivities = results.expand((list) => list).toList();

        // Sắp xếp theo thời gian mới nhất và lấy tối đa 3 hoạt động
        allActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return allActivities.take(3).toList();
      } catch (_) {
        return const [];
      }
    });
