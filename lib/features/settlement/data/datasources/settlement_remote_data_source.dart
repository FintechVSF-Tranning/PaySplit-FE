import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_endpoints.dart';

abstract class SettlementRemoteDataSource {
  Future<List<Map<String, dynamic>>> listGroups();

  Future<List<Map<String, dynamic>>> listDebts(String groupId);

  Future<List<Map<String, dynamic>>> listBills(String groupId);

  Future<Map<String, dynamic>> getPayment(String groupId, String paymentId);

  Future<Map<String, dynamic>> generatePaymentQr({
    required String groupId,
    required String creditorId,
    required List<String> debtIds,
  });

  Future<void> submitProof({
    required String groupId,
    required String paymentId,
    required String imageName,
    required Uint8List imageBytes,
    String? note,
  });

  Future<void> confirmPayment(String groupId, String paymentId);

  Future<void> rejectPayment(String groupId, String paymentId, String reason);

  Future<void> remindDebt(String groupId, String debtId);
}

class SettlementRemoteDataSourceImpl implements SettlementRemoteDataSource {
  SettlementRemoteDataSourceImpl(this._dio, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final Dio _dio;
  final Uuid _uuid;

  @override
  Future<List<Map<String, dynamic>>> listGroups() async {
    final groups = <Map<String, dynamic>>[];
    String? cursor;

    do {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.groups,
        queryParameters: {'limit': 100, 'cursor': ?cursor},
      );
      final data = _data(response.data);
      groups.addAll(_mapList(data['groups']));
      cursor = data['next_cursor'] as String?;
    } while (cursor != null && cursor.isNotEmpty);

    return groups;
  }

  @override
  Future<List<Map<String, dynamic>>> listDebts(String groupId) async {
    final debts = <Map<String, dynamic>>[];
    String? cursor;

    do {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.groupDebts(groupId),
        queryParameters: {'limit': 100, 'cursor': ?cursor},
      );
      final data = _data(response.data);
      debts.addAll(_mapList(data['debts']));
      cursor = data['next_cursor'] as String?;
    } while (cursor != null && cursor.isNotEmpty);

    return debts;
  }

  @override
  Future<List<Map<String, dynamic>>> listBills(String groupId) async {
    final bills = <Map<String, dynamic>>[];
    String? cursor;

    do {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.bills,
        queryParameters: {'group_id': groupId, 'limit': 100, 'cursor': ?cursor},
      );
      final data = _data(response.data);
      bills.addAll(_mapList(data['bills']));
      cursor = data['next_cursor'] as String?;
    } while (cursor != null && cursor.isNotEmpty);

    return bills;
  }

  @override
  Future<Map<String, dynamic>> getPayment(
    String groupId,
    String paymentId,
  ) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.groupPayment(groupId, paymentId),
    );
    return _payment(response.data);
  }

  @override
  Future<Map<String, dynamic>> generatePaymentQr({
    required String groupId,
    required String creditorId,
    required List<String> debtIds,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.groupPaymentQr(groupId),
      data: {'creditor_member_id': creditorId, 'debt_ids': debtIds},
      options: Options(headers: _idempotencyHeader()),
    );
    return _payment(response.data);
  }

  @override
  Future<void> submitProof({
    required String groupId,
    required String paymentId,
    required String imageName,
    required Uint8List imageBytes,
    String? note,
  }) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: imageName,
        contentType: _imageType(imageName),
      ),
      if (note != null && note.isNotEmpty) 'note': note,
    });

    await _dio.post<dynamic>(
      ApiEndpoints.groupPaymentProof(groupId, paymentId),
      data: formData,
      options: Options(headers: _idempotencyHeader()),
    );
  }

  @override
  Future<void> confirmPayment(String groupId, String paymentId) async {
    await _dio.post<dynamic>(
      ApiEndpoints.confirmGroupPayment(groupId, paymentId),
      options: Options(headers: _idempotencyHeader()),
    );
  }

  @override
  Future<void> rejectPayment(
    String groupId,
    String paymentId,
    String reason,
  ) async {
    await _dio.post<dynamic>(
      ApiEndpoints.rejectGroupPayment(groupId, paymentId),
      data: {'reason': reason},
      options: Options(headers: _idempotencyHeader()),
    );
  }

  @override
  Future<void> remindDebt(String groupId, String debtId) async {
    await _dio.post<dynamic>(
      ApiEndpoints.remindDebt(groupId, debtId),
      options: Options(headers: _idempotencyHeader()),
    );
  }

  Map<String, String> _idempotencyHeader() => {'Idempotency-Key': _uuid.v4()};

  DioMediaType _imageType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return DioMediaType('image', 'heic');
    }
    return DioMediaType('image', 'jpeg');
  }

  Map<String, dynamic> _payment(dynamic body) {
    final data = _data(body);
    return _map(data['payment']);
  }

  Map<String, dynamic> _data(dynamic body) {
    final envelope = _map(body);
    if (envelope['success'] != true) {
      throw const FormatException('API response is not successful');
    }
    return _map(envelope['data']);
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Expected a JSON object');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      throw const FormatException('Expected a JSON array');
    }
    return value.map(_map).toList();
  }
}
