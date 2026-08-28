import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/client_sync_models.dart';

@lazySingleton
class ClientSyncDataSource {
  ClientSyncDataSource(this._dio);

  final Dio _dio;

  /// Lấy cấu hình public của app từ GET /api/v1/app-config
  Future<AppConfigModel> getAppConfig({CancelToken? cancelToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.appConfig,
      cancelToken: cancelToken,
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return AppConfigModel.fromJson(data);
  }

  /// Lấy danh sách version aggregates delta từ GET /api/v1/sync/versions
  Future<SyncVersionsModel> getSyncVersions({
    String? after,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{};
    if (after != null && after.isNotEmpty) {
      queryParams['after'] = after;
    }
    if (limit != null && limit > 0) {
      queryParams['limit'] = limit;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.syncVersions,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SyncVersionsModel.fromJson(data);
  }
}
