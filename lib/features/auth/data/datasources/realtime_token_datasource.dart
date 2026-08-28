import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';

class RealtimeTokenResult {
  const RealtimeTokenResult({
    required this.token,
    required this.expiresAt,
  });

  factory RealtimeTokenResult.fromJson(Map<String, dynamic> json) {
    return RealtimeTokenResult(
      token: json['token'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String token;
  final DateTime expiresAt;
}

@lazySingleton
class RealtimeTokenDataSource {
  RealtimeTokenDataSource(this._dio);

  final Dio _dio;

  /// Lấy short-lived JWT ES256 từ POST /api/v1/auth/realtime-token (Spec 0010 AC-5)
  Future<RealtimeTokenResult> getRealtimeToken({CancelToken? cancelToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.realtimeToken,
      cancelToken: cancelToken,
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return RealtimeTokenResult.fromJson(data);
  }
}
