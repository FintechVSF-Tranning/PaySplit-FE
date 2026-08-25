import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';
import '../models/bill_model.dart';

abstract class BillRemoteDataSource {
  Future<List<BillModel>> getBills({required String groupId, int limit = 20, String? cursor});

  Future<BillDetailEntity> createBillWithPhotos({
    required String groupId,
    String? merchantName,
    required List<CapturedBillPhoto> photos,
  });

  Future<BillDetailEntity> createManualBill({
    required String groupId,
    required String merchantName,
    required int total,
    required List<BillItemEntity> items,
  });

  Future<BillDetailEntity> getBillDetail({
    required String billId,
    required String groupId,
  });

  Future<BillDetailEntity> updateDraftBill({
    required String billId,
    required String groupId,
    required Map<String, dynamic> payload,
  });

  Future<BillDetailEntity> reviewBill({
    required String billId,
    required String groupId,
    required int version,
  });

  Future<void> finalizeBill({
    required String billId,
    required String groupId,
    required int version,
  });

  Future<List<BillShareBreakdownEntity>> calculateBreakdown({
    String? billId,
    required String groupId,
    required Map<String, dynamic> payload,
  });

  Future<List<BillMemberEntity>> getGroupMembers({
    required String groupId,
  });
}

@LazySingleton(as: BillRemoteDataSource)
class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final Dio _dio;

  BillRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    return const {};
  }

  @override
  Future<List<BillModel>> getBills({
    required String groupId,
    int limit = 20,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{
      'group_id': groupId,
      'limit': limit,
    };
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }

    final response = await _dio.get(
      ApiEndpoints.bills,
      queryParameters: queryParams,
    );
    final rawData = response.data;
    final data = _extractData(rawData);
    final rawBills = data['bills'] ?? (rawData is Map ? rawData['bills'] : null);
    if (rawBills is List) {
      return rawBills
          .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (rawData is Map && rawData['data'] is List) {
      return (rawData['data'] as List)
          .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<BillDetailEntity> createBillWithPhotos({
    required String groupId,
    String? merchantName,
    required List<CapturedBillPhoto> photos,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('group_id', groupId));
    if (merchantName != null && merchantName.isNotEmpty) {
      formData.fields.add(MapEntry('merchant_name', merchantName));
    }

    for (int i = 0; i < photos.length; i++) {
      final p = photos[i];
      formData.files.add(
        MapEntry(
          'images',
          MultipartFile.fromBytes(
            p.bytes,
            filename: 'receipt_$i.jpg',
          ),
        ),
      );
    }

    final response = await _dio.post(
      ApiEndpoints.bills,
      data: formData,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = _extractData(rawData);
      final billJson = data['bill'] as Map<String, dynamic>? ?? data;
      final initialBill = BillDetailEntity.fromJson(billJson).copyWith(photos: photos);
      if (initialBill.items.isNotEmpty) {
        return initialBill;
      }

      // Polling GET /api/v1/bills/{id}?group_id={groupId} for OCR results
      if (initialBill.id.isNotEmpty) {
        const pollInterval = Duration(milliseconds: 1500);
        const maxAttempts = 20; // ~30s
        for (int attempt = 0; attempt < maxAttempts; attempt++) {
          await Future.delayed(pollInterval);
          try {
            final detailResponse = await _dio.get(
              '${ApiEndpoints.bills}/${initialBill.id}',
              queryParameters: {'group_id': groupId},
            );
            final detailRaw = detailResponse.data;
            if (detailRaw is Map<String, dynamic>) {
              final detailData = _extractData(detailRaw);
              final detailBillJson = detailData['bill'] as Map<String, dynamic>? ?? detailData;
              final billWithContext = Map<String, dynamic>.from(detailBillJson);
              if (detailData['ocr_job'] != null) {
                billWithContext['ocr_job'] = detailData['ocr_job'];
              }
              if (detailData['candidate'] != null) {
                billWithContext['candidate'] = detailData['candidate'];
              }
              final updatedBill = BillDetailEntity.fromJson(billWithContext).copyWith(photos: photos);
              if (updatedBill.items.isNotEmpty) {
                return updatedBill;
              }

              final ocrJob = detailData['ocr_job'];
              if (ocrJob is Map && ocrJob['status'] == 'failed') {
                break;
              }

              if (detailBillJson['ocr_jobs'] is List) {
                final jobs = detailBillJson['ocr_jobs'] as List;
                if (jobs.isNotEmpty && jobs.every((j) => j is Map && j['status'] == 'failed')) {
                  break;
                }
              }
            }
          } catch (_) {
            // ignore temporary polling errors
          }
        }
      }

      return initialBill;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Phản hồi tạo hóa đơn không hợp lệ',
    );
  }

  @override
  Future<BillDetailEntity> createManualBill({
    required String groupId,
    required String merchantName,
    required int total,
    required List<BillItemEntity> items,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.bills,
      data: {
        'group_id': groupId,
        'merchant_name': merchantName,
        'total': total,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = _extractData(rawData);
      final billJson = data['bill'] as Map<String, dynamic>? ?? data;
      return BillDetailEntity.fromJson(billJson);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Không thể tạo hoá đơn',
    );
  }

  @override
  Future<BillDetailEntity> getBillDetail({
    required String billId,
    required String groupId,
  }) async {
    final response = await _dio.get(
      '${ApiEndpoints.bills}/$billId',
      queryParameters: {'group_id': groupId},
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = _extractData(rawData);
      final rawBill = data['bill'] as Map<String, dynamic>? ?? data;
      final billJson = Map<String, dynamic>.from(rawBill);
      if (data['breakdown'] != null) {
        billJson['breakdown'] = data['breakdown'];
      }
      if (data['signed_urls'] != null) {
        billJson['signed_urls'] = data['signed_urls'];
      }
      if (data['ocr_job'] != null) {
        billJson['ocr_job'] = data['ocr_job'];
      }
      return BillDetailEntity.fromJson(billJson);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Không thể lấy thông tin hoá đơn',
    );
  }

  @override
  Future<BillDetailEntity> updateDraftBill({
    required String billId,
    required String groupId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.put(
      '${ApiEndpoints.bills}/$billId',
      queryParameters: {'group_id': groupId},
      data: payload,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = _extractData(rawData);
      final rawBill = data['bill'] as Map<String, dynamic>? ?? data;
      final billJson = Map<String, dynamic>.from(rawBill);
      if (data['breakdown'] != null) {
        billJson['breakdown'] = data['breakdown'];
      }
      return BillDetailEntity.fromJson(billJson);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Không thể lưu bản nháp',
    );
  }

  @override
  Future<BillDetailEntity> reviewBill({
    required String billId,
    required String groupId,
    required int version,
  }) async {
    final response = await _dio.post(
      '${ApiEndpoints.bills}/$billId/review',
      queryParameters: {'group_id': groupId},
      data: {'version': version},
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = _extractData(rawData);
      final rawBill = data['bill'] as Map<String, dynamic>? ?? data;
      final billJson = Map<String, dynamic>.from(rawBill);
      if (data['breakdown'] != null) {
        billJson['breakdown'] = data['breakdown'];
      }
      return BillDetailEntity.fromJson(billJson);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Đối soát hoá đơn không thành công',
    );
  }

  @override
  Future<void> finalizeBill({
    required String billId,
    required String groupId,
    required int version,
  }) async {
    await _dio.post(
      '${ApiEndpoints.bills}/$billId/finalize',
      queryParameters: {'group_id': groupId},
      data: {'version': version},
    );
  }

  @override
  Future<List<BillShareBreakdownEntity>> calculateBreakdown({
    String? billId,
    required String groupId,
    required Map<String, dynamic> payload,
  }) async {
    final endpoint = (billId != null && billId.isNotEmpty)
        ? '${ApiEndpoints.bills}/$billId/calculate'
        : '${ApiEndpoints.bills}/calculate';

    final response = await _dio.post(
      endpoint,
      queryParameters: {'group_id': groupId},
      data: payload,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = _extractData(rawData);
      final breakdownList = data['breakdown'] as List? ??
          rawData['breakdown'] as List? ??
          const [];

      return breakdownList
          .map((b) => BillShareBreakdownEntity.fromJson(b as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  @override
  Future<List<BillMemberEntity>> getGroupMembers({
    required String groupId,
  }) async {
    try {
      final response = await _dio.get('${ApiEndpoints.groups}/$groupId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = _extractData(data);
        final dynamic membersList = payload['members'] ?? data['members'];
        if (membersList is List) {
          return membersList
              .map((m) => BillMemberEntity.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      try {
        final response = await _dio.get('${ApiEndpoints.groups}/$groupId/members');
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final payload = _extractData(data);
          final dynamic membersList = payload['members'] ?? data['members'];
          if (membersList is List) {
            return membersList
                .map((m) => BillMemberEntity.fromJson(m as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }
}
