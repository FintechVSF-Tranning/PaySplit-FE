import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GroupBillCloseRemoteDataSource {
  const GroupBillCloseRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> start(
    String groupId, {
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/bills/finalize-all',
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return _requireData(response.data);
  }

  Future<Map<String, dynamic>> getBatch(
    String groupId,
    String batchId, {
    String? cursor,
  }) async {
    final queryParameters = <String, dynamic>{'limit': 20};
    if (cursor != null) queryParameters['cursor'] = cursor;
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/bill-finalize-batches/$batchId',
      queryParameters: queryParameters,
    );
    return _requireData(response.data);
  }

  Map<String, dynamic> _requireData(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid API response');
    }
    return data;
  }
}
