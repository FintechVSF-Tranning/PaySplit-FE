import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bulk_finalize_entity.dart';
import '../repositories/group_bill_close_repository.dart';

class StartBulkFinalizeParams {
  const StartBulkFinalizeParams(this.groupId, {required this.idempotencyKey});
  final String groupId;
  final String idempotencyKey;
}

@injectable
class StartBulkFinalizeUseCase
    implements UseCase<BulkFinalizeBatchEntity, StartBulkFinalizeParams> {
  const StartBulkFinalizeUseCase(this._repository);
  final GroupBillCloseRepository _repository;

  @override
  Future<Either<Failure, BulkFinalizeBatchEntity>> call(
    StartBulkFinalizeParams params,
  ) => _repository.start(params.groupId, idempotencyKey: params.idempotencyKey);
}

class GetBulkFinalizeParams {
  const GetBulkFinalizeParams(this.groupId, this.batchId, {this.cursor});
  final String groupId;
  final String batchId;
  final String? cursor;
}

@injectable
class GetBulkFinalizeUseCase
    implements UseCase<BulkFinalizeBatchEntity, GetBulkFinalizeParams> {
  const GetBulkFinalizeUseCase(this._repository);
  final GroupBillCloseRepository _repository;

  @override
  Future<Either<Failure, BulkFinalizeBatchEntity>> call(
    GetBulkFinalizeParams params,
  ) => _repository.getBatch(
    params.groupId,
    params.batchId,
    cursor: params.cursor,
  );
}
