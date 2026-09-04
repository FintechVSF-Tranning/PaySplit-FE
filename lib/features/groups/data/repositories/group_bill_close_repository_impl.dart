import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/bulk_finalize_entity.dart';
import '../../domain/repositories/group_bill_close_repository.dart';
import '../datasources/group_bill_close_remote_data_source.dart';

@LazySingleton(as: GroupBillCloseRepository)
class GroupBillCloseRepositoryImpl implements GroupBillCloseRepository {
  GroupBillCloseRepositoryImpl(this._remote);

  final GroupBillCloseRemoteDataSource _remote;

  @override
  Future<Either<Failure, BulkFinalizeBatchEntity>> start(
    String groupId, {
    required String idempotencyKey,
  }) => _guard(() async {
    final data = await _remote.start(groupId, idempotencyKey: idempotencyKey);
    return _batch(data['batch'] as Map<String, dynamic>);
  });

  @override
  Future<Either<Failure, BulkFinalizeBatchEntity>> getBatch(
    String groupId,
    String batchId, {
    String? cursor,
  }) => _guard(() async {
    final data = await _remote.getBatch(groupId, batchId, cursor: cursor);
    final summary = _batch(data['batch'] as Map<String, dynamic>);
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((value) => _item(value as Map<String, dynamic>))
        .toList();
    return summary.copyWith(
      items: items,
      nextCursor: data['next_cursor'] as String?,
    );
  });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on DioException catch (error) {
      return Left(mapDioError(error));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }

  BulkFinalizeBatchEntity _batch(Map<String, dynamic> json) {
    return BulkFinalizeBatchEntity(
      id: json['id'] as String,
      status: switch (json['status']) {
        'completed' => BulkFinalizeStatus.completed,
        'processing' => BulkFinalizeStatus.processing,
        _ => BulkFinalizeStatus.queued,
      },
      targetCount: (json['target_count'] as num).toInt(),
      finalizedCount: (json['finalized_count'] as num).toInt(),
      failedCount: (json['failed_count'] as num).toInt(),
    );
  }

  BulkFinalizeItemEntity _item(Map<String, dynamic> json) {
    return BulkFinalizeItemEntity(
      billId: json['bill_id'] as String,
      billName: json['bill_display_name'] as String? ?? 'Hóa đơn đã xóa',
      status: switch (json['status']) {
        'finalized' => BulkFinalizeItemStatus.finalized,
        'failed' => BulkFinalizeItemStatus.failed,
        _ => BulkFinalizeItemStatus.pending,
      },
      errorCode: json['error_code'] as String?,
      billVersion: (json['bill_version'] as num?)?.toInt(),
      capturedReviewed: json['captured_reviewed'] as bool?,
    );
  }
}
