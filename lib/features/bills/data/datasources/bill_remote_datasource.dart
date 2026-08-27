import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';
import '../models/bill_list_page_model.dart';

abstract class BillRemoteDataSource {
  Future<BillListPageModel> getBills({
    required String groupId,
    int limit = 20,
    String? cursor,
    List<String> statuses = const [],
  });

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
    int subtotal = 0,
    int serviceCharge = 0,
    int vat = 0,
    int discount = 0,
    String splitMethod = 'item_ratio',
    DateTime? billDate,
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

  Future<BillDetailEntity> voidBill({
    required String billId,
    required String groupId,
    required int version,
    required String reason,
  });

  Future<List<BillShareBreakdownEntity>> calculateBreakdown({
    String? billId,
    required String groupId,
    required Map<String, dynamic> payload,
  });

  Future<List<BillMemberEntity>> getGroupMembers({
    required String groupId,
  });

  Future<void> deleteDraftBill({
    required String billId,
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
  Future<BillListPageModel> getBills({
    required String groupId,
    int limit = 20,
    String? cursor,
    List<String> statuses = const [],
  }) async {
    final queryParams = <String, dynamic>{
      'group_id': groupId,
      'limit': limit,
    };
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }
    // BE nhận `status` lặp lại hoặc CSV; Dio serialize List thành dạng lặp.
    if (statuses.isNotEmpty) {
      queryParams['status'] = statuses;
    }

    final response = await _dio.get(
      ApiEndpoints.bills,
      queryParameters: queryParams,
    );
    final rawData = response.data;
    final data = _extractData(rawData);
    if (data['bills'] != null || data['counts'] != null) {
      return BillListPageModel.fromJson(data);
    }
    // Dạng cũ: `data` là mảng bill trần.
    if (rawData is Map && rawData['data'] is List) {
      return BillListPageModel.fromJson({'bills': rawData['data']});
    }
    return const BillListPageModel(bills: []);
  }

  @override
  Future<BillDetailEntity> createBillWithPhotos({
    required String groupId,
    String? merchantName,
    required List<CapturedBillPhoto> photos,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('group_id', groupId));
    formData.fields.add(const MapEntry('split_method', 'even'));
    if (merchantName != null && merchantName.isNotEmpty) {
      formData.fields.add(MapEntry('merchant_name', merchantName));
    }

    for (int i = 0; i < photos.length; i++) {
      final p = photos[i];
      if (p.hasBytes) {
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              p.bytes!,
              filename: 'receipt_$i.jpg',
            ),
          ),
        );
      }
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
        const maxAttempts = 40; // ~60s
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
                if (detailData['ocr_job'] is Map<String, dynamic>) {
                  final jobMap = detailData['ocr_job'] as Map<String, dynamic>;
                  if (jobMap['candidate'] != null) {
                    billWithContext['candidate'] = jobMap['candidate'];
                  }
                }
              }
              if (detailData['candidate'] != null) {
                billWithContext['candidate'] = detailData['candidate'];
              }
              final updatedBill = BillDetailEntity.fromJson(billWithContext).copyWith(photos: photos);
              if (updatedBill.items.isNotEmpty) {
                return updatedBill;
              }

              final ocrJob = detailData['ocr_job'];
              if (ocrJob is Map) {
                if (ocrJob['status'] == 'failed') {
                  break;
                }
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
    int subtotal = 0,
    int serviceCharge = 0,
    int vat = 0,
    int discount = 0,
    String splitMethod = 'item_ratio',
    DateTime? billDate,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.bills,
      data: {
        'group_id': groupId,
        'merchant_name': merchantName,
        // Thiếu bất kỳ field nào dưới đây là backend ghi 0 / mặc định `even`:
        // lần mở lại hóa đơn sẽ mất thuế phí và bị coi là chia đều, xóa sạch
        // phần gán món người dùng vừa tick.
        'subtotal': subtotal,
        'service_charge': serviceCharge,
        'vat': vat,
        'discount': discount,
        'split_method': splitMethod,
        if (billDate != null) 'bill_date': billDate.toUtc().toIso8601String(),
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
      } else if (rawBill['shares'] is List &&
          (rawBill['shares'] as List).isNotEmpty) {
        // BE chỉ tính `breakdown` tạm thời cho bill draft/reviewed. Với bill đã
        // chốt (finalized) hoặc đã hủy, phần chia đã lưu nằm ở `bill.shares` —
        // dùng nó để màn chi tiết hiển thị lại đúng số tiền từng người.
        billJson['breakdown'] = rawBill['shares'];
      }
      if (data['signed_urls'] != null) {
        billJson['signed_urls'] = data['signed_urls'];
      }
      if (data['ocr_job'] != null) {
        billJson['ocr_job'] = data['ocr_job'];
        if (data['ocr_job'] is Map<String, dynamic>) {
          final jobMap = data['ocr_job'] as Map<String, dynamic>;
          if (jobMap['candidate'] != null) {
            billJson['candidate'] = jobMap['candidate'];
          }
        }
      }
      if (data['candidate'] != null) {
        billJson['candidate'] = data['candidate'];
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
  Future<BillDetailEntity> voidBill({
    required String billId,
    required String groupId,
    required int version,
    required String reason,
  }) async {
    final response = await _dio.post(
      '${ApiEndpoints.bills}/$billId/void',
      queryParameters: {'group_id': groupId},
      data: {
        'version': version,
        'reason': reason,
      },
    );
    final rawData = response.data;
    final data = _extractData(rawData);
    final billMap = data['bill'] ?? rawData['bill'] ?? data;
    if (billMap is Map<String, dynamic>) {
      return BillDetailEntity.fromJson(billMap);
    }
    return getBillDetail(billId: billId, groupId: groupId);
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
  Future<void> deleteDraftBill({
    required String billId,
    required String groupId,
  }) async {
    await _dio.delete<dynamic>(
      '${ApiEndpoints.bills}/$billId',
      queryParameters: {'group_id': groupId},
      // Xóa là thao tác không hoàn tác được: khóa idempotency để một lần bấm bị
      // gửi lại (mạng chập chờn) không biến thành lỗi 404 khó hiểu.
      options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
    );
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
