import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_detail_entity.dart';
import '../entities/bill_list_page.dart';
import '../entities/captured_bill_photo.dart';

abstract class BillRepository {
  Future<Either<Failure, BillListPage>> getBills({
    String groupId = '',
    int limit = 20,
    String? cursor,
    List<String> statuses = const [],
  });

  Future<Either<Failure, BillDetailEntity>> createBillWithPhotos({
    required String groupId,
    String? merchantName,
    required List<CapturedBillPhoto> photos,
  });

  Future<Either<Failure, BillDetailEntity>> createManualBill({
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

  Future<Either<Failure, BillDetailEntity>> getBillDetail({
    required String billId,
    required String groupId,
  });

  Future<Either<Failure, BillDetailEntity>> updateDraftBill({
    required String billId,
    required String groupId,
    required Map<String, dynamic> payload,
  });

  Future<Either<Failure, BillDetailEntity>> reviewBill({
    required String billId,
    required String groupId,
    required int version,
  });

  Future<Either<Failure, void>> finalizeBill({
    required String billId,
    required String groupId,
    required int version,
    String? idempotencyKey,
  });

  Future<Either<Failure, BillDetailEntity>> voidBill({
    required String billId,
    required String groupId,
    required int version,
    required String reason,
  });

  Future<Either<Failure, List<BillShareBreakdownEntity>>> calculateBreakdown({
    String? billId,
    required String groupId,
    required Map<String, dynamic> payload,
  });

  Future<Either<Failure, List<BillMemberEntity>>> getGroupMembers({
    required String groupId,
  });

  /// Xóa hẳn một hóa đơn còn ở trạng thái nháp (kèm ảnh đã tải lên).
  /// Hóa đơn đã chốt phải dùng [voidBill] để giữ lại lịch sử.
  Future<Either<Failure, void>> deleteDraftBill({
    required String billId,
    required String groupId,
  });
}
