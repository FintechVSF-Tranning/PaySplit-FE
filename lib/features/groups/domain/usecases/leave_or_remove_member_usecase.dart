import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

/// Một endpoint phục vụ hai hành vi: truyền membership của chính mình là rời
/// nhóm, truyền membership người khác là Captain xóa thành viên.
class MemberParams extends Equatable {
  const MemberParams({required this.groupId, required this.membershipId});

  final String groupId;
  final String membershipId;

  @override
  List<Object?> get props => [groupId, membershipId];
}

@injectable
class LeaveOrRemoveMemberUseCase implements UseCase<Unit, MemberParams> {
  LeaveOrRemoveMemberUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MemberParams params) =>
      _repository.leaveOrRemoveMember(params.groupId, params.membershipId);
}
