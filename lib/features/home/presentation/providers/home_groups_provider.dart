import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/home_group_item_entity.dart';

final homeGroupsProvider = FutureProvider.autoDispose<List<HomeGroupItemEntity>>((ref) async {
  try {
    final dio = getIt<Dio>();
    final response = await dio.get(
      ApiEndpoints.groups,
      queryParameters: {'limit': 3},
    );

    if (response.data is Map<String, dynamic>) {
      final rawData = response.data as Map<String, dynamic>;
      final data = rawData['data'] as Map<String, dynamic>? ?? rawData;
      final groupsList = data['groups'] as List? ?? const [];

      if (groupsList.isNotEmpty) {
        return groupsList
            .map((g) => HomeGroupItemEntity.fromJson(g as Map<String, dynamic>))
            .toList();
      }
    }
    return const [];
  } catch (_) {
    // Nếu chưa đăng nhập hoặc có lỗi kết nối, trả về danh sách rỗng để hiển thị fallback thân thiện
    return const [];
  }
});
