import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

class ListGroupsParams extends Equatable {
  const ListGroupsParams({this.limit, this.cursor});

  final int? limit;

  /// `null` cho trang đầu; giá trị lấy từ `nextCursor` của trang trước.
  final String? cursor;

  @override
  List<Object?> get props => [limit, cursor];
}

@injectable
class ListGroupsUseCase implements UseCase<GroupPage<GroupEntity>, ListGroupsParams> {
  ListGroupsUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupPage<GroupEntity>>> call(ListGroupsParams params) =>
      _repository.listGroups(limit: params.limit, cursor: params.cursor);
}
