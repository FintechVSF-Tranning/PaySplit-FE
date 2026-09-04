import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

class RenameGroupParams extends Equatable {
  const RenameGroupParams({required this.groupId, required this.name});

  final String groupId;
  final String name;

  @override
  List<Object?> get props => [groupId, name];
}

@injectable
class RenameGroupUseCase implements UseCase<GroupEntity, RenameGroupParams> {
  RenameGroupUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupEntity>> call(RenameGroupParams params) =>
      _repository.renameGroup(params.groupId, params.name);
}
