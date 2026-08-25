import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_detail_entity.dart';
import '../entities/bill_entity.dart';
import '../entities/captured_bill_photo.dart';

abstract class BillRepository {
  Future<Either<Failure, List<BillEntity>>> getBills({String groupId = '', int limit = 20, String? cursor});

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
  });

  Future<Either<Failure, List<BillShareBreakdownEntity>>> calculateBreakdown({
    String? billId,
    required String groupId,
    required Map<String, dynamic> payload,
  });

  Future<Either<Failure, List<BillMemberEntity>>> getGroupMembers({
    required String groupId,
  });
}
