import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

@injectable
class DisbandGroupUseCase implements UseCase<Unit, String> {
  DisbandGroupUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String groupId) => _repository.disbandGroup(groupId);
}
