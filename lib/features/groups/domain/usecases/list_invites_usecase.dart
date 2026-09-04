import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

@injectable
class ListInvitesUseCase implements UseCase<List<GroupInvite>, String> {
  ListInvitesUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, List<GroupInvite>>> call(String groupId) =>
      _repository.listInvites(groupId);
}
