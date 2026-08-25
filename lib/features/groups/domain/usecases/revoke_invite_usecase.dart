import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

class RevokeInviteParams extends Equatable {
  const RevokeInviteParams({required this.groupId, required this.inviteId});

  final String groupId;
  final String inviteId;

  @override
  List<Object?> get props => [groupId, inviteId];
}

@injectable
class RevokeInviteUseCase implements UseCase<Unit, RevokeInviteParams> {
  RevokeInviteUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RevokeInviteParams params) =>
      _repository.revokeInvite(params.groupId, params.inviteId);
}
