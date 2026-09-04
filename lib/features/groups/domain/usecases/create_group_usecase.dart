import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

class CreateGroupParams extends Equatable {
  const CreateGroupParams({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

@injectable
class CreateGroupUseCase implements UseCase<GroupEntity, CreateGroupParams> {
  CreateGroupUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupEntity>> call(CreateGroupParams params) =>
      _repository.createGroup(name: params.name);
}
