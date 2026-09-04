import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bulk_finalize_entity.dart';

abstract class GroupBillCloseRepository {
  Future<Either<Failure, BulkFinalizeBatchEntity>> start(
    String groupId, {
    required String idempotencyKey,
  });

  Future<Either<Failure, BulkFinalizeBatchEntity>> getBatch(
    String groupId,
    String batchId, {
    String? cursor,
  });
}
