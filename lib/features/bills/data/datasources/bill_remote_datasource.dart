import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/realtime/realtime_frame_bus.dart';
import '../../../../core/realtime/realtime_transport_mode.dart';
import '../../../../core/realtime/sse_frame.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';
import '../models/bill_list_page_model.dart';
import 'bill_event_stream_datasource.dart';

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

  /// Chạy lại OCR trên một hóa đơn đã tồn tại trên server.
  ///
  /// Khác [createBillWithPhotos] ở chỗ không tạo hóa đơn mới: ảnh đã nằm trên
  /// Cloudinary rồi, và client mở lại một hóa đơn cũ thì cũng không còn bytes
  /// ảnh trong tay để mà upload lần nữa.
  Future<BillDetailEntity> retryOcr({
    required String billId,
    required String groupId,
    List<CapturedBillPhoto> photos = const [],
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
    String? idempotencyKey,
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

  Future<List<BillMemberEntity>> getGroupMembers({required String groupId});

  Future<void> deleteDraftBill({
    required String billId,
    required String groupId,
  });
}

@LazySingleton(as: BillRemoteDataSource)
class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final Dio _dio;

  /// Chỉ dùng ở chế độ legacy. Nullable để test dựng data source mà không phải
  /// kéo theo cả TokenStorage và SessionRefresher.
  final BillEventStreamDataSource? _eventStreamDataSource;

  BillRemoteDataSourceImpl(this._dio, [this._eventStreamDataSource]);

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') &&
          responseData['data'] is Map<String, dynamic>) {
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
    final queryParams = <String, dynamic>{'group_id': groupId, 'limit': limit};
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
        final uploadBytes = await ImageCompressor.compress(p.bytes!);
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(uploadBytes, filename: 'receipt_$i.jpg'),
          ),
        );
      }
    }

    final response = await _dio.post(ApiEndpoints.bills, data: formData);

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = _extractData(rawData);
      final billJson = Map<String, dynamic>.from(
        data['bill'] as Map<String, dynamic>? ?? data,
      );
      // `ocr_job` nằm cạnh `bill` chứ không nằm trong nó. Không kéo sang đây thì
      // hóa đơn trả về từ POST mang `ocrStatus = none`, và một OCR còn đang xếp
      // hàng trông y hệt một OCR đã xong mà không đọc được món nào.
      if (data['ocr_job'] != null) {
        billJson['ocr_job'] = data['ocr_job'];
      }
      final initialBill = BillDetailEntity.fromJson(
        billJson,
      ).copyWith(photos: photos);
      if (initialBill.items.isNotEmpty) {
        return initialBill;
      }

      if (initialBill.id.isNotEmpty) {
        final settled = await _awaitOcrSettled(
          billId: initialBill.id,
          groupId: groupId,
          photos: photos,
        );
        if (settled != null) return settled;
      }

      return initialBill;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Phản hồi tạo hóa đơn không hợp lệ',
    );
  }


  @override
  Future<BillDetailEntity> retryOcr({
    required String billId,
    required String groupId,
    List<CapturedBillPhoto> photos = const [],
  }) async {
    await _dio.post(
      ApiEndpoints.billOcrRetry(billId),
      queryParameters: {'group_id': groupId},
    );

    final settled = await _awaitOcrSettled(
      billId: billId,
      groupId: groupId,
      photos: photos,
    );
    if (settled != null) return settled;

    // Không đọc được kết quả nào: trả về bản đọc cuối để tầng trên còn thấy
    // `ocrStatus` mà báo đúng "vẫn đang chạy" thay vì "xong mà rỗng".
    final last = await _readBillWithOcr(
      billId: billId,
      groupId: groupId,
      photos: photos,
    );
    if (last != null) return last.bill;

    throw DioException(
      requestOptions: RequestOptions(path: ApiEndpoints.billById(billId)),
      message: 'Không đọc được hóa đơn sau khi chạy lại OCR',
    );
  }

  /// Chờ OCR của một hóa đơn vừa tạo xong, rồi trả về chi tiết đã đọc lại.
  ///
  /// Ba đường lấy trạng thái, theo đúng thứ tự quan trọng:
  ///   1. Một GET **trước khi** chờ. OCR có thể xong ngay giữa POST và lúc đăng
  ///      ký, và tại thời điểm này provider chi tiết chưa kịp đăng ký interest
  ///      của mình — không có bước này thì trạng thái đã commit chỉ lộ ra sau
  ///      trọn 60 giây.
  ///   2. Một GET sau **mỗi** `ready`: mỗi lần kết nối lại là một khoảng trống
  ///      sự kiện, và `ready` là lúc rẻ nhất để hàn nó.
  ///   3. Một GET khi hết 60 giây, để không bao giờ kẹt vô hạn.
  ///
  /// Nguồn sự kiện chọn theo chế độ **hiệu lực** chứ không theo biến môi trường:
  /// một owner `auto` đã rơi về legacy thì bus người dùng không còn frame nào.
  Future<BillDetailEntity?> _awaitOcrSettled({
    required String billId,
    required String groupId,
    required List<CapturedBillPhoto> photos,
  }) async {
    final early = await _readBillWithOcr(
      billId: billId,
      groupId: groupId,
      photos: photos,
    );
    if (early != null && early.settled) return early.bill;

    final cancelToken = CancelToken();
    try {
      final legacySource = RealtimeTransportMode.instance.useLegacy
          ? _eventStreamDataSource
          : null;
      final Stream<SseFrame> frames = legacySource != null
          ? legacySource.stream(
              billId,
              groupId: groupId,
              cancelToken: cancelToken,
            )
          : RealtimeFrameBus.instance.frames.where(
              (frame) =>
                  frame.event == 'ready' ||
                  (frame.event == 'ocr.updated' &&
                      frame.data['bill_id'] == billId),
            );

      await for (final frame in frames.timeout(const Duration(seconds: 60))) {
        final shouldRead =
            frame.event == 'ready' ||
            frame.event == 'snapshot' ||
            frame.event == 'ocr.updated';
        if (!shouldRead) continue;

        final read = await _readBillWithOcr(
          billId: billId,
          groupId: groupId,
          photos: photos,
        );
        if (read != null && read.settled) {
          cancelToken.cancel();
          return read.bill;
        }
      }
    } catch (_) {
      // Stream đóng, hết giờ, hoặc mất kết nối: đường GET cuối vẫn còn.
    } finally {
      cancelToken.cancel();
    }

    final last = await _readBillWithOcr(
      billId: billId,
      groupId: groupId,
      photos: photos,
    );
    return last?.bill;
  }

  Future<_BillOcrRead?> _readBillWithOcr({
    required String billId,
    required String groupId,
    required List<CapturedBillPhoto> photos,
  }) async {
    try {
      final detailResponse = await _dio.get(
        '${ApiEndpoints.bills}/$billId',
        queryParameters: {'group_id': groupId},
      );
      final detailRaw = detailResponse.data;
      if (detailRaw is! Map<String, dynamic>) return null;
      final detailData = _extractData(detailRaw);
      final detailBillJson =
          detailData['bill'] as Map<String, dynamic>? ?? detailData;
      final billWithContext = Map<String, dynamic>.from(detailBillJson);
      String? ocrStatus;
      final ocrJob = detailData['ocr_job'];
      if (ocrJob != null) {
        billWithContext['ocr_job'] = ocrJob;
        if (ocrJob is Map<String, dynamic>) {
          ocrStatus = ocrJob['status'] as String?;
          if (ocrJob['candidate'] != null) {
            billWithContext['candidate'] = ocrJob['candidate'];
          }
        }
      }
      if (detailData['candidate'] != null) {
        billWithContext['candidate'] = detailData['candidate'];
      }
      final bill = BillDetailEntity.fromJson(
        billWithContext,
      ).copyWith(photos: photos);
      return _BillOcrRead(bill: bill, status: ocrStatus);
    } catch (_) {
      return null;
    }
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
    String? idempotencyKey,
  }) async {
    final key = (idempotencyKey != null && idempotencyKey.isNotEmpty)
        ? idempotencyKey
        : const Uuid().v4();
    await _dio.post(
      '${ApiEndpoints.bills}/$billId/finalize',
      queryParameters: {'group_id': groupId},
      data: {'version': version},
      options: Options(headers: {'Idempotency-Key': key}),
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
      data: {'version': version, 'reason': reason},
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
      final breakdownList =
          data['breakdown'] as List? ??
          rawData['breakdown'] as List? ??
          const [];

      return breakdownList
          .map(
            (b) => BillShareBreakdownEntity.fromJson(b as Map<String, dynamic>),
          )
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
        final response = await _dio.get(
          '${ApiEndpoints.groups}/$groupId/members',
        );
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final payload = _extractData(data);
          final dynamic membersList = payload['members'] ?? data['members'];
          if (membersList is List) {
            return membersList
                .map(
                  (m) => BillMemberEntity.fromJson(m as Map<String, dynamic>),
                )
                .toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }
}

/// Kết quả một lần đọc `GET /bills/{id}`: hóa đơn cộng trạng thái job OCR.
class _BillOcrRead {
  const _BillOcrRead({required this.bill, required this.status});

  final BillDetailEntity bill;
  final String? status;

  /// OCR đã dừng hẳn — thành công hoặc thất bại. Cả hai đều là lý do hợp lệ để
  /// thôi chờ; chờ tiếp một job đã `failed` chỉ tốn đúng 60 giây của người dùng.
  bool get settled =>
      status == 'succeeded' || status == 'failed' || bill.items.isNotEmpty;
}
