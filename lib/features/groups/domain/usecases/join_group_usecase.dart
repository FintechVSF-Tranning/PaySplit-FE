import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

@injectable
class JoinGroupUseCase implements UseCase<GroupJoinResult, String> {
  JoinGroupUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupJoinResult>> call(String code) => _repository.joinGroup(code);
}
