import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

@injectable
class GetGroupDetailUseCase implements UseCase<GroupDetailResult, String> {
  GetGroupDetailUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupDetailResult>> call(String groupId) =>
      _repository.getGroupDetail(groupId);
}
