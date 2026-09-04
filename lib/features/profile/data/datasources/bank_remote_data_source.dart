import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../models/bank_model.dart';

@lazySingleton
class BankRemoteDataSource {
  const BankRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<BankModel>> getSupportedBanks() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.banks,
      queryParameters: const {'supported': true},
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Bank response body is empty');
    }

    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
      body,
      (json) => json! as Map<String, dynamic>,
    );
    final rawBanks = envelope.requireData['banks'] as List<dynamic>;
    return rawBanks
        .map((bank) => BankModel.fromJson(bank as Map<String, dynamic>))
        .toList(growable: false);
  }
}
