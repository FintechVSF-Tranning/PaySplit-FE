import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/group_activity_entity.dart';
import '../repositories/group_repository.dart';

class ListActivitiesParams extends Equatable {
  const ListActivitiesParams({required this.groupId, this.limit, this.cursor});

  final String groupId;
  final int? limit;
  final String? cursor;

  @override
  List<Object?> get props => [groupId, limit, cursor];
}

@injectable
class ListActivitiesUseCase
    implements UseCase<GroupPage<GroupActivityEntity>, ListActivitiesParams> {
  ListActivitiesUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupPage<GroupActivityEntity>>> call(ListActivitiesParams params) =>
      _repository.listActivities(params.groupId, limit: params.limit, cursor: params.cursor);
}
