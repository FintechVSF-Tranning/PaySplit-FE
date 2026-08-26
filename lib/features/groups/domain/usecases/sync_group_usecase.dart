import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/group_sync_entity.dart';
import '../repositories/group_repository.dart';

class SyncGroupParams extends Equatable {
  const SyncGroupParams({required this.groupId, required this.since});

  final String groupId;

  /// Version client đang giữ. 0 nghĩa là chưa có gì và sẽ nhận snapshot.
  final int since;

  @override
  List<Object?> get props => [groupId, since];
}

/// Hàn gắp lỗ hổng: xin phần còn thiếu kể từ [SyncGroupParams.since], hoặc một
/// snapshot khi client tụt quá xa.
@injectable
class SyncGroupUseCase implements UseCase<GroupSyncResult, SyncGroupParams> {
  SyncGroupUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupSyncResult>> call(SyncGroupParams params) =>
      _repository.syncGroup(params.groupId, since: params.since);
}

/// Kênh nóng. Không dùng [UseCase] vì hợp đồng của nó là `Future<Either<...>>`:
/// một stream sống lâu không phải "một kết quả", và lỗi ở đây là mất kết nối
/// chứ không phải thất bại nghiệp vụ.
@injectable
class StreamGroupEventsUseCase {
  StreamGroupEventsUseCase(this._repository);

  final GroupRepository _repository;

  Stream<GroupSyncEvent> call(String groupId, {required int since}) =>
      _repository.streamGroupEvents(groupId, since: since);
}
